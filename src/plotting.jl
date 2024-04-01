export plot_fig_thr, plot_fig_pa1, plot_fig_pa2, plot_fig_r1a, plot_fig_r1b, plot_fig_r2a, plot_fig_r2b

function plot_fig_thr()
    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "0.2_measure_thresholds_extra_2024_clean_data.csv")))

    # Analyze into means
    df_ind = @chain df begin
        @orderby(:freq)
        @transform(:freq_group = :freq .< 6100)
        groupby([:freq, :freq_group, :subj])
        @combine(:threshold = mean(:threshold))
    end
    df_avg = @chain df_ind begin
        groupby([:freq, :freq_group])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    # Plot
    fig = Figure(; size=(500, 400))
    ax = Axis(fig[1, 1]; xminorticksvisible=false)

    # Loop over frequencies
    for (freq, offset) in zip([300, 487, 798, 6100, 9909, 16100], [1, 2, 3, 5, 6, 7])
        # Subset data
        ss_ind = @subset(df_ind, :freq .== freq)
        ss_avg = @subset(df_avg, :freq .== freq)

        # Plot means
        color_temp = freq < 6100 ? freq_colors["low"] : freq_colors["high"]
        scatter!(ax, [offset], ss_avg.threshold_mean; color=color_temp, markersize=15.0)
        errorbars!(ax, [offset], ss_avg.threshold_mean, ss_avg.threshold_error; color=color_temp, whiskerwidth=20.0)

        # Plot individual data
        n_point = length(ss_ind.threshold)
        scatter!(ax, fill(offset, n_point) .+ 0.35 .+ randn(n_point) .* 0.05, ss_ind.threshold; color=color_temp)
    end
    ax.xticks = ([1, 2, 3, 5, 6, 7], string.(df_avg.freq))
    ylims!(ax, 20.0, 60.0)
    ax.xlabel = "Frequency (Hz)"
    ax.ylabel = "Threshold (dB SPL)"
    fig
end

function plot_fig_pa1()
    # Load data from disk, rename "Control" and "Task" to "Level discrimination" and "Profile analysis"
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis.csv")))
    df = @orderby(df, :n_comp)
    mapper = Dict("Control" => "Level discrimination", "Task" => "Profile analysis")
    df[!, :task] = [mapper[x] for x in df.task]

    # Preproccess to calculate condition-wise means
    df_avg = @chain df begin
        groupby([:freq, :task, :n_comp, :subj])
        @combine(:threshold = mean(:threshold))
        groupby([:freq, :task, :n_comp])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
        @orderby(reverse(:freq))
    end

    # Create plot
    fig = Figure(; size=(600, 400))
    ax = Axis(fig[1, 1])
    colors = [freq_colors["low"], freq_colors["high"]]
    kwargs = [
        :markersize => 14.0,
        :linewidth => 2.0,
        :whiskerwidth => 12.0,
    ]

    # Assign locations
    x_ld = [1.0]
    x_unroved = [3, 4, 5, 6]
    x_roved = [8, 9, 10, 11]

    # Plot guidelines
    hlines!(ax, [13.0]; color=:red)  # one gray line at 13 dB SRS to indicate ceiling max

    # Plot unroved control model
    temp = calc_θ_overall_level_unroved(df)
    θ_control_low = [x[1] for x in temp]
    θ_control_high = [x[2] for x in temp]
    lines!(ax, x_unroved, θ_control_low; color=freq_colors["low"], linestyle=:dash)
    lines!(ax, x_unroved, θ_control_high; color=freq_colors["high"], linestyle=:dash)

    # Plot roved control model
    fn_cache = projectdir("cache", "roved_control.jld2")
    if isfile(fn_cache)
        temp = load(fn_cache)["data"]
    else
        temp = calc_θ_overall_level_roved()
        save(fn_cache, Dict("data" => temp))
    end
    lines!(ax, x_roved, temp; color=:lightgray, linestyle=:dash)
    temp = calc_θ_ΔL_roved()
    lines!(ax, [x_roved[1], x_roved[end]], [temp, temp]; color=:lightgray, linestyle=:dot)

    # Plot level discrimination data
    data_subset = @subset(df_avg, :n_comp .== 1)
    map(zip(["Low", "High"], colors)) do (freq, color)
        group = @subset(data_subset, :freq .== freq)
        scatter!(ax, x_ld, group.threshold_mean; color=color, kwargs...)
        errorbars!(ax, x_ld, group.threshold_mean, group.threshold_error; color=color, kwargs...)
    end

    # Plot unroved profile-analysis data
    data_subset = @chain df_avg begin
        @subset(:n_comp .> 1)
        @subset(:task .== "Level discrimination")
        @orderby(:n_comp)
    end
    map(zip(["Low", "High"], colors)) do (freq, color)
        group = @subset(data_subset, :freq .== freq)
        lines!(ax, x_unroved, group.threshold_mean; color=color, kwargs...)
        scatter!(ax, x_unroved, group.threshold_mean; color=color, kwargs...)
        errorbars!(ax, x_unroved, group.threshold_mean, group.threshold_error; color=color, kwargs...)
    end

    # Plot roved profile-analysis data
    data_subset = @chain df_avg begin
        @subset(:n_comp .> 1)
        @subset(:task .!= "Level discrimination")
        @orderby(:n_comp)
    end
    map(zip(["Low", "High"], colors)) do (freq, color)
        group = @subset(data_subset, :freq .== freq)
        lines!(ax, x_roved, group.threshold_mean; color=color, kwargs...)
        scatter!(ax, x_roved, group.threshold_mean; color=color, kwargs...)
        errorbars!(ax, x_roved, group.threshold_mean, group.threshold_error; color=color, kwargs...)
    end

    # Handle x-axis
    ax.xticks = (
        vcat(x_ld, x_unroved, x_roved),
        [
            "Level\nDiscrimination",
            "3",
            "5",
            "9",
            "15",
            "3",
            "5",
            "9",
            "15",
        ]
    )
    ax.xminorticksvisible = false
    ax.xlabel = "Condition / Number of components"

    # Handle y-axis
    ax.ylabel = "Threshold (dB SRS)"
    ax.yticks = -15:5:15

    # Add labels
    text!(ax, "Unroved"; position=(4.5, 15.0), align=(:center, :baseline))
    text!(ax, "Roved"; position=(9.5, 15.0), align=(:center, :baseline))

    # Set limits
    ylims!(ax, (-15, 17.5))

    # Render
    fig
end

function plot_fig_pa2()
    # Load data from disk, rename "Control" and "Task" to "Level discrimination" and "Profile analysis"
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis_extra_2024.csv")))
    df = @orderby(df, :n_comp)
    mapper = Dict("Control" => "Level discrimination", "Task" => "Profile analysis")
    df[!, :task] = [mapper[x] for x in df.task]

    # Filter to only be complete datasets
    df = @subset(df, in.(:subj, Ref(["x01", "x02", "x07", "x09", "x14", "x15", "x16", "x17", "x18", "x20", "x25", "x28", "x29"])))

    # Add information about which was completed first for each person
    # Here, a 1 indicates control was completed first, a 2 indicates PA was completed first
    order = Dict(
        "x01" => 2,
        "x02" => 1,
        "x07" => 2,
        "x09" => 2,
        "x14" => 2,
        "x15" => 1,
        "x16" => 1,
        "x17" => 1,
        "x18" => 1,
        "x20" => 1,
        "x25" => 2,
        "x28" => 1,
        "x29" => 2,
    )
    df[!, :order] .= getindex.(Ref(order), df.subj)

    # Preproccess to calculate condition-wise means
    df_avg = @chain df begin
        groupby([:freq, :task, :n_comp, :order, :subj])
        @combine(:threshold = mean(:threshold))
        groupby([:freq, :task, :order, :n_comp])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
        @orderby(reverse(:freq))
        @orderby(:order)
    end

    # Create plot
    fig = Figure(; size=(450, 400))
    ax = Axis(fig[1, 1])
    colors = [freq_colors["low"], freq_colors["high"]]
    kwargs = [
        :markersize => 14.0,
        :linewidth => 2.0,
        :whiskerwidth => 12.0,
    ]

    # Plot guidelines
    hlines!(ax, [13.0]; color=:red)  # one gray line at 13 dB SRS to indicate ceiling max

    # Pick order to plot points and positions along x axis
    seq = [
        ("Level discrimination", 1, 1.0),
        ("Profile analysis", 1, 2.0),
        ("Level discrimination", 2, 4.0),
        ("Profile analysis", 2, 5.0),
    ]

    # Plot unroved profile-analysis data
    map(zip(["Low", "High"], colors)) do (freq, color)
        df_subset = @subset(df_avg, :freq .== freq)
        map(seq) do (task, order, offset)
            datum = @subset(df_subset, :order .== order, :task .== task)
            scatter!(ax, [offset], datum.threshold_mean; color=color, kwargs...)
            errorbars!(ax, [offset], datum.threshold_mean, datum.threshold_error; color=color, kwargs...)
        end
    end

    # Handle x-axis
    ax.xticks = (
        [1, 2, 4, 5],
        ["Unroved", "Roved", "Unroved", "Roved"],
    )
    ax.xticklabelrotation = π/4
    ax.xminorticksvisible = false
    ax.xlabel = "Condition"

    # Handle y-axis
    ax.ylabel = "Threshold (dB SRS)"
    ax.yticks = -15:5:15

    # Add labels
    text!(ax, "Unroved first"; position=(1.5, 15.0), align=(:center, :baseline))
    text!(ax, "Roved first"; position=(4.5, 15.0), align=(:center, :baseline))

    # Set limits
    ylims!(ax, (-15, 17.5))
    xlims!(ax, [0.0, 6.0])

    # Render
    fig
end

function plot_fig_r1a()
    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "ripple_discrimination.csv")));

    # Compute individual and group means
    df_ind = @chain df begin
        groupby([:freq, :task, :subj])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    df_avg = @chain df begin
        groupby([:freq, :task, :subj])
        @combine(:threshold = mean(:threshold))
        groupby([:freq, :task])
        @combine(:threshold_mean = median(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    # Create Makie figures and axes
    fig = Figure(; size=(300, 300))
    ax = Axis(
        fig[1, 1]; 
        xticks=([1, 2], ["Detection", "Discrimination"]),
        ylabel="Threshold [20 log10 (m)]",
        xlabel="Task",
    )
    ylims!(ax, -25.0, 0.0)
    xlims!(ax, 0.5, 2.5)

    # Plot ripples with boxplot
    boxplot!(
        ax, 
        repeat([0.85], 12), 
        @subset(df_ind, :freq .== "Low", :task .== "Control").threshold_mean; 
        width=0.25, 
        color=freq_colors["low"]
    )
    boxplot!(
        ax, 
        repeat([1.15], 12), 
        @subset(df_ind, :freq .== "High", :task .== "Control").threshold_mean; 
        width=0.25, 
        color=freq_colors["high"]
    )
    boxplot!(
        ax, 
        repeat([1.85], 12), 
        @subset(df_ind, :freq .== "Low", :task .== "Task").threshold_mean; 
        width=0.25, 
        color=freq_colors["low"]
    )
    boxplot!(
        ax, 
        repeat([2.15], 12), 
        @subset(df_ind, :freq .== "High", :task .== "Task").threshold_mean; 
        width=0.25, 
        color=freq_colors["high"]
    )
    fig
    return fig
end

function plot_fig_r1b()
    # Load data
    df = DataFrame(CSV.File("data/exp_pro/ripple_discrimination.csv"));

    # Compute individual and group means
    df_ind = @chain df begin
        groupby([:freq, :task, :subj])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    # Calculate difference scores
    df_diff = unstack(df_ind, [:subj, :freq], :task, :threshold_mean)
    df_diff[!, :diff] .= df_diff.Task .- df_diff.Control
    df_diff_avg = @chain df_diff begin
        groupby(:freq)
        @combine(:diff_mean = median(:diff), :diff_error = 1.96*std(:diff)/sqrt(length(:diff)))
    end

    # Create figure
    fig = Figure(; size=(200, 300))
    ax = Axis(fig[1, 1]; ylabel="Discrimination - Detection (dB)")
    xlims!(ax, 0.5, 1.5)
    for freq in ["Low", "High"]
        # Handle major points
        temp = @subset(df_diff, :freq .== freq)
        offset = freq == "Low" ? -0.2 : 0.2
        boxplot!(ax, (1.0 + offset) .* ones(length(temp.diff)), temp.diff; color=freq_colors[lowercase(freq)], markersize=13.0, width=0.15)
    end

    # Handle minor points
    for subj in unique(df_diff.subj)
        temp = @subset(df_diff, :subj .== subj)
        temp = @orderby(temp, reverse(:freq))
        scatter!(ax, [0.9, 1.1], temp.diff; color=[freq_colors["low"], freq_colors["high"]], markersize=5.0)
        lines!(ax, [0.9, 1.1], temp.diff; color=:gray, linewidth=1.0)
    end

    # Add ticks
    ax.xticks = ([0.8, 1.2], ["Low", "High"])
    ax.xlabel = "Frequency"
    fig
end

function plot_fig_r2a()
    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "ripple_discrimination_extra_2024.csv")));

    # Compute individual and group means
    df_ind = @chain df begin
        groupby([:freq, :task, :subj])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    df_avg = @chain df begin
        groupby([:freq, :task, :subj])
        @combine(:threshold = mean(:threshold))
        groupby([:freq, :task])
        @combine(:threshold_mean = median(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    # Create Makie figures and axes
    fig = Figure(; size=(300, 300))
    ax = Axis(
        fig[1, 1]; 
        xticks=([1, 2], ["Detection", "Discrimination"]),
        ylabel="Threshold [20 log10 (m)]",
        xlabel="Task",
    )
    ylims!(ax, -25.0, 0.0)
    xlims!(ax, 0.5, 2.5)

    # Plot ripples with boxplot
    ss = @subset(df_ind, :freq .== "Low", :task .== "Control")
    boxplot!(
        ax, 
        repeat([0.85], length(unique(ss.subj))), 
        ss.threshold_mean; 
        width=0.25, 
        color=freq_colors["low"]
    )
    ss = @subset(df_ind, :freq .== "High", :task .== "Control")
    boxplot!(
        ax, 
        repeat([1.15], length(unique(ss.subj))), 
        ss.threshold_mean; 
        width=0.25, 
        color=freq_colors["high"]
    )
    ss = @subset(df_ind, :freq .== "Low", :task .== "Task")
    boxplot!(
        ax, 
        repeat([1.85], length(unique(ss.subj))), 
        ss.threshold_mean; 
        width=0.25, 
        color=freq_colors["low"]
    )
    ss = @subset(df_ind, :freq .== "High", :task .== "Task")
    boxplot!(
        ax, 
        repeat([2.15], length(unique(ss.subj))), 
        ss.threshold_mean; 
        width=0.25, 
        color=freq_colors["high"]
    )
    fig
    return fig
end

function plot_fig_r2b()
    # Load data
    df = DataFrame(CSV.File("data/exp_pro/ripple_discrimination_extra_2024.csv"));

    # Compute individual and group means
    df_ind = @chain df begin
        groupby([:freq, :task, :subj])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    # Calculate difference scores
    df_diff = unstack(df_ind, [:subj, :freq], :task, :threshold_mean)
    df_diff[!, :diff] .= df_diff.Task .- df_diff.Control
    df_diff = dropmissing(df_diff)

    # Create figure
    fig = Figure(; size=(200, 300))
    ax = Axis(fig[1, 1]; ylabel="Discrimination - Detection (dB)")
    xlims!(ax, 0.5, 1.5)
    for freq in ["Low", "High"]
        # Handle major points
        temp = @subset(df_diff, :freq .== freq)
        offset = freq == "Low" ? -0.2 : 0.2
        boxplot!(ax, (1.0 + offset) .* ones(length(temp.diff)), temp.diff; color=freq_colors[lowercase(freq)], markersize=13.0, width=0.15)
    end

    # Handle minor points
    for subj in unique(df_diff.subj)
        temp = @subset(df_diff, :subj .== subj)
        temp = @orderby(temp, reverse(:freq))
        scatter!(ax, [0.9, 1.1], temp.diff; color=[freq_colors["low"], freq_colors["high"]], markersize=5.0)
        lines!(ax, [0.9, 1.1], temp.diff; color=:gray, linewidth=1.0)
    end

    # Add ticks
    ax.xticks = ([0.8, 1.2], ["Low", "High"])
    ax.xlabel = "Frequency"
    fig
end
