export plot_fig_thr, plot_schematic_stimulus, plot_fig_pa1_learning, plot_fig_pa1_learning_v2, plot_fig_pa1, plot_fig_pa2, plot_fig_r1a, plot_fig_r1b, plot_fig_r2a, plot_fig_r2b, plot_fig_pa2_sl, plot_schematic_an_response

function plot_schematic_stimulus(freq, n_comp)
    fig = Figure(; size=(350, 350))
    ax = Axis(fig[1, 1]; xscale=log10, xminorticksvisible=false, spinewidth=3.5)
    if n_comp == 1
        if freq == "Low"
            freqs = [487.0]
        else
            freqs = [9909.0]
        end
    else
        if freq == "Low"
            freqs = exp.(LinRange(log(300.0), log(792.0), n_comp))
        else
            freqs = exp.(LinRange(log(6100.0), log(16100.0), n_comp))
        end
    end
    ΔL = srs_to_ΔL(0.0)
    color = freq_colors[lowercase(freq)]
    for (idx, freq) in enumerate(freqs)
        lines!(ax, [freq, freq], [0.0, 60.0 + (idx == ceil(length(freqs)/2) ? ΔL : 0.0)]; color=color, linewidth=4.0)
    end
    xlims!(ax, 300.0 * 2.0^(-0.5), 16100.0*2.0^(0.5))
    ylims!(ax, 30.0, 75.0)
    ax.xticks = ([300.0, 487.0, 798.0, 6100.0, 9909.0, 16100.0], ["300 Hz", "487 Hz", "798 Hz", "6.1 kHz", "9.9 kHz", "16.1 kHz"])
    ax.xticklabelrotation = π/2
    ax.xticklabelsize = 30.0
    hideydecorations!(ax)
    fig
end

function plot_schematic_an_response(freq, n_comp; n_cf=301, fig=Figure(; size=(350, 350)), ax=Axis(fig[1, 1]; xscale=log10, xminorticksvisible=false, spinewidth=3.5))
    # Set up figure
    
    # Select parameters
    if n_comp == 1
        if freq == "Low"
            freqs = [487.0]
        else
            freqs = [9909.0]
        end
    else
        if freq == "Low"
            freqs = exp.(LinRange(log(300.0), log(792.0), n_comp))
        else
            freqs = exp.(LinRange(log(6100.0), log(16100.0), n_comp))
        end
    end

    # Choose CF values 
    cfs = LogRange(487.0 * 2.0^(-1.0), 9909.0 * 2.0 ^ (1.0), n_cf)

    # Synthesize reference stimulus (-Inf dB SRS) and stimulus at 0 dB SRS
    ref, tar = map([srs_to_ΔL(-Inf), srs_to_ΔL(0.0)]) do inc
        stim = profile_analysis_tone(freqs, length(freqs) == 1 ? 1 : Int(round(length(freqs)/2) + 1); dur=0.35, pedestal_level=60.0, increment=inc)
        map(cfs) do cf
            ihc = sim_ihc_zbc2014(stim, cf; species="human")
            an = sim_anrate_zbc2014(ihc, cf; power_law="approximate", fractional=false, fiber_type="low")
            mean(an)
        end
    end

    color = freq_colors[lowercase(freq)]
    lines!(ax, cfs, ref; linestyle=:dash, color=color, linewidth=3.0)
    lines!(ax, cfs, tar; linestyle=:solid, color=color, linewidth=3.0)
    xlims!(ax, 300.0 * 2.0^(-0.5), 16100.0*2.0^(0.5))
    ylims!(ax, 0.0, 125.0)
    ax.xticks = ([300.0, 487.0, 798.0, 6100.0, 9909.0, 16100.0], ["300 Hz", "487 Hz", "798 Hz", "6.1 kHz", "9.9 kHz", "16.1 kHz"])
    ax.xticklabelrotation = π/2
    ax.xticklabelsize = 30.0
    hideydecorations!(ax)
    fig
end

function plot_fig_thr()
    kwargs = [
        :markersize => 18.0,
        :linewidth => 3.0,
        :whiskerwidth => 12.0,
    ]

    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "0.2_measure_thresholds_extra_2024_clean_data.csv")))
    df = @subset(df, in.(:subj, Ref(subjs_2024())))

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
        errorbars!(ax, [offset], ss_avg.threshold_mean, ss_avg.threshold_error; color=color_temp, kwargs...)
        scatter!(ax, [offset], ss_avg.threshold_mean; color=color_temp, kwargs...)
        if freq > 1000
            scatter!(ax, [offset], ss_avg.threshold_mean; color=:white, kwargs..., markersize=10.0)
        end

        # Plot individual data
        n_point = length(ss_ind.threshold)
        x = fill(offset, n_point) .+ 0.35 .+ randn(n_point) .* 0.05
        scatter!(ax, x, ss_ind.threshold; color=color_temp, markersize=10.0)
        if freq > 1000
            scatter!(ax, x, ss_ind.threshold; color=:white, markersize=3.0)
        end
    end
    ax.xticks = ([1, 2, 3, 5, 6, 7], string.(df_avg.freq))
    ylims!(ax, 30.0, 55.0)
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

    # Preproccess to calculate condition-wise means at ind level
    df_ind = @chain df begin
        groupby([:freq, :task, :n_comp, :subj])
        @combine(:threshold = mean(:threshold))
        @orderby(reverse(:freq))
    end

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
        :markersize => 18.0,
        :linewidth => 3.0,
        :whiskerwidth => 12.0,
    ]

    # Assign locations
    x_ld = [1]
    x_unroved = [3, 4, 5, 6]
    x_roved = [8, 9, 10, 11]
    offset = 0.3
    scale = 0.03

    # Plot guidelines
    hlines!(ax, [13.0]; color=:red)  # one gray line at 13 dB SRS to indicate ceiling max

    # Plot unroved control model
    temp = calc_θ_overall_level_unroved(df)
    θ_control_low = [x[1] for x in temp]
    θ_control_high = [x[2] for x in temp]
    lines!(ax, x_unroved, θ_control_low; color=freq_colors["low"], linestyle=:dash, kwargs...)
    lines!(ax, x_unroved, θ_control_high; color=freq_colors["high"], linestyle=:dash, kwargs...)

    # Plot roved control model
    fn_cache = projectdir("cache", "roved__control.jld2")
    if isfile(fn_cache)
        temp = load(fn_cache)["data"]
    else
        temp = calc_θ_overall_level_roved()
        save(fn_cache, Dict("data" => temp))
    end
    lines!(ax, x_roved, temp; color=:lightgray, linestyle=:dash, kwargs...)
    temp = calc_θ_ΔL_roved()
    lines!(ax, [x_roved[1], x_roved[end]], [temp, temp]; color=:lightgray, linestyle=:dot, kwargs...)

    # Plot level discrimination data
    ss = @subset(df_avg, :n_comp .== 1)
    ss_ind = @subset(df_ind, :n_comp .== 1)
    map(zip(["Low", "High"], colors)) do (freq, color)
        group = @subset(ss, :freq .== freq)
        group_ind = @subset(ss_ind, :freq .== freq)
        errorbars!(ax, x_ld, group.threshold_mean, group.threshold_error; color=color, kwargs...)
        scatter!(ax, x_ld, group.threshold_mean; color=color, kwargs...)
        jitter = scale .* randn(nrow(group_ind))
        scatter!(ax, fill(x_ld[1], nrow(group_ind)) .+ offset .+ jitter, group_ind.threshold; color=color, kwargs..., markersize=10.0)
        if freq == "High"
            scatter!(ax, x_ld, group.threshold_mean; color=:white, kwargs..., markersize=6.0)
            scatter!(ax, fill(x_ld[1], nrow(group_ind)) .+ offset .+ jitter, group_ind.threshold; color=:white, kwargs..., markersize=3.0)
        end
    end

    # Plot unroved profile-analysis data
    map(zip(["Level discrimination", "Profile analysis"], [x_unroved, x_roved])) do (task, x)
        ss = @chain df_avg begin
            @subset(:n_comp .> 1)
            @subset(:task .== task)
            @orderby(:n_comp)
        end
        ss_ind = @chain df_ind begin
            @subset(:n_comp .> 1)
            @subset(:task .== task)
            @orderby(:n_comp)
        end
        map(zip(["Low", "High"], colors)) do (freq, color)
            group = @subset(ss, :freq .== freq)
            errorbars!(ax, x, group.threshold_mean, group.threshold_error; color=color, kwargs...)
            scatter!(ax, x, group.threshold_mean; color=color, kwargs...)
            if freq == "High"
                scatter!(ax, x, group.threshold_mean; color=:white, kwargs..., markersize=6.0)
            end

            map(zip([3, 5, 9, 15], x)) do (n_comp, this_x)
                group_ind = @subset(ss_ind, :freq .== freq, :n_comp .== n_comp)
                jitter = scale .* randn(nrow(group_ind))
                scatter!(ax, fill(this_x, nrow(group_ind)) .+ offset .+ jitter, group_ind.threshold; color=color, kwargs..., markersize=10.0)
                if freq == "High"
                    scatter!(ax, fill(this_x, nrow(group_ind)) .+ offset .+ jitter, group_ind.threshold; color=:white, kwargs..., markersize=3.0)
                end
            end
        end
    end

#     # Plot roved profile-analysis data
#     data_subset = @chain df_avg begin
#         @subset(:n_comp .> 1)
#         @subset(:task .!= "Level discrimination")
#         @orderby(:n_comp)
#     end
#     map(zip(["Low", "High"], colors)) do (freq, color)
#         group = @subset(data_subset, :freq .== freq)
# #        lines!(ax, x_roved, group.threshold_mean; color=color, kwargs...)
#         errorbars!(ax, x_roved, group.threshold_mean, group.threshold_error; color=color, kwargs...)
#         scatter!(ax, x_roved, group.threshold_mean; color=color, kwargs...)
#         if freq == "High"
#             scatter!(ax, x_roved, group.threshold_mean; color=:white, kwargs..., markersize=6.0)
#         end
#     end

    # Add manual labels
    scatter!(ax, [1.0], [8.0]; color=freq_colors["low"], kwargs...)
    text!(ax, [1.3], [8.0]; color=freq_colors["low"], text="Low", fontsize=20.0, font="Arial bold", align=(:left, :center))
    scatter!(ax, [1.0], [10.0]; color=freq_colors["high"], kwargs...)
    scatter!(ax, [1.0], [10.0]; color=:white, kwargs..., markersize=6.0)
    text!(ax, [1.3], [10.0]; color=freq_colors["high"], text="High", fontsize=20.0, font="Arial bold", align=(:left, :center))

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

function plot_fig_pa1_learning_v2()
    # Load data from disk, rename "Control" and "Task" to "Level discrimination" and "Profile analysis"
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis.csv")))
    df = @orderby(df, :n_comp)
    mapper = Dict("Control" => "Level discrimination", "Task" => "Profile analysis")
    df[!, :task] = [mapper[x] for x in df.task]

    # Create list of conditions to loop through
    conds = Iterators.product([1, 3, 5, 9, 15], ["Level discrimination", "Profile analysis"])

    # Map over conditions to create new dataframe that contains information about run (assuming that the order of rows inidcates the order of runs, persuant with AFC style)
    temp = map(conds) do (n_comp, task)
        # If we're in the 1-component profile analysis condition, continue
        if (n_comp == 1) & (task == "Profile analysis")
            return DataFrame()
        else
            # Subset data to n_comp and task condition
            ss = @subset(df, :task .== task, :n_comp .== n_comp)

            # Select unique subjects
            subjs = unique(df.subj)

            # Loop through each subject and add run info
            subj_results = map(subjs) do subj
                lo = @subset(ss, :subj .== subj, :freq .== "Low")
                lo[!, :run] .= 1:nrow(lo)
                hi = @subset(ss, :subj .== subj, :freq .== "High")
                hi[!, :run] .= 1:nrow(hi)
                return vcat(lo, hi)
            end
            return subj_results
        end
    end
    df = vcat(vcat(temp...)...)

    # Create plot
    fig = Figure(; size=(850, 1000))
    axs = [(i == 1) & (j == 2) ? nothing : Axis(fig[i, j]; xminorticksvisible=false) for i in 1:5, j in 1:2]

    # Map through conditions and plot
    for ((n_comp, task), ax) in zip(conds, axs)
        # If we're in the 1-component profile analysis condition, continue
        if (n_comp == 1) & (task == "Profile analysis")
            continue 
        end

        # Subset data to n_comp and task condition
        ss = @subset(df, :task .== task, :n_comp .== n_comp)

        # Select unique subjects
        subjs = unique(df.subj)

        # Loop over frequencies
        for freq in ["Low", "High"]
            # Loop over first and last run
            thrs = map(1:12) do run
                # Compute and plot average thresholds across subjs
                temp = @subset(ss, :freq .== freq, :run .== run)
                avg = mean(temp.threshold)
                err = 1.96*std(temp.threshold)/sqrt(length(temp.threshold))
                errorbars!(ax, [run], [avg], [err]; color=freq_colors[lowercase(freq)], whiskerwidth=10.0, linewidth=3.0)
                scatter!(ax, [run], [avg]; color=freq_colors[lowercase(freq)], markersize=15.0)
                if freq == "High"
                    scatter!(ax, [run], [avg]; color=:white, markersize=6.0)
                end
                return temp
            end

            # Loop through subjects available with last run and compute difference scores
            δ = map(thrs[12].subj) do subj
                thr12 = @subset(thrs[12], :subj .== subj).threshold[1]
                thr1 = @subset(thrs[1], :subj .== subj).threshold[1]
                return thr12 - thr1
            end

            # Compute p-value and average learning rate 
            pval = pvalue(OneSampleTTest(δ))
            δ_bar = mean(δ)
            μ12 = mean(thrs[12].threshold)

            # Print
            text!(ax, 12.5, μ12; text="Δ = $(round(δ_bar; digits=2)) dB $(pval < 0.05 ? "✲" : " ")", color=freq_colors[lowercase(freq)], align=(:left, :center))
        end

        # Set limits
        ylims!(ax, (-20.0, 16.0))
        ax.xticks = 1:12
        xlims!(ax, (-1, 18))
        hidexdecorations!(ax; ticklabels=(n_comp==15 ? false : true), ticks=false)
        hideydecorations!(ax; ticklabels=(task == "Level discrimination" ? false : true), ticks=false)

        # Add legend
        if (task == "Level discrimination") & (n_comp == 1)
            scatter!(ax, [1.0], [8.0]; color=freq_colors["low"], markersize=15.0)
            text!(ax, [1.5], [8.0]; color=freq_colors["low"], text="Low", fontsize=20.0, font="Arial bold", align=(:left, :center))
            scatter!(ax, [1.0], [12.0]; color=freq_colors["high"], markersize=15.0)
            scatter!(ax, [1.0], [12.0]; color=:white, markersize=6.0)
            text!(ax, [1.5], [12.0]; color=freq_colors["high"], text="High", fontsize=20.0, font="Arial bold", align=(:left, :center))
        end
    end

    # Add labels
    Label(fig[6, :], "Run"; fontsize=20.0)
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2, fontsize=20.0)
    Label(fig[0, 1], "Unroved"; fontsize=20.0, tellwidth=false)
    Label(fig[0, 2], "Roved"; fontsize=20.0, tellwidth=false)
    for (idx, n_comp) in enumerate(unique(df.n_comp))
        Label(fig[idx, 3], "$n_comp comps"; tellheight=false, fontsize=20.0)
    end
    rowgap!(fig.layout, 6, Relative(0.01))
    colgap!(fig.layout, 1, Relative(0.01))
  
    # Render
    fig
end

function plot_fig_pa2_sl()
    # Load threshold data from disk
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "0.1_screen_audibility_extra_2024_clean_data.csv")))

    # Subset to only passed + complete datasets
    df = @subset(df, in.(:subj, Ref(subjs_2024())))

    # Convert threshold to float
    df.threshold .= parse.(Float64, df.threshold)

    # Rename ear to left and right
    mapper = Dict(1 => "Left", 2 => "Right")
    df.ear .= getindex.(Ref(mapper), df.ear)

    # Map through subjects and take only last two runs
    dfs = map(unique(df.subj)) do subj
        ss = @subset(df, :subj .== subj)
        return ss[(end-3):end, :]
    end
    df = vcat(dfs...)

    # Condense to means and SEs by ear and subj
    df_avg = @chain df begin
        groupby([:ear, :subj])
        @combine(:threshold_mean = mean(:threshold))
    end

    # Unstack by ear
    df_avg = unstack(df_avg, :ear, :threshold_mean) 

    # Add passed and selected ear column
    df_avg[!, :selected_ear] .= "None"
    df_avg[!, :passed] .= false
    df_avg[!, :better_threshold] .= 0.0
    for idx_row in 1:nrow(df_avg)
        df_avg[idx_row, :selected_ear] = df_avg[idx_row, :Left] < df_avg[idx_row, :Right] ? "Left" : "Right"
        df_avg[idx_row, :better_threshold] = df_avg[idx_row, Symbol(df_avg[idx_row, :selected_ear])]
    end
    df_avg.passed .= df_avg.better_threshold .< 40.0

    # Rename df_avg to df_abs_threshold
    df_abs_thr = df_avg

    # Create narrow little plot to go alongside plot_fig_pa2
    # fig = Figure(; size=(150, 400))
    # ax = Axis(fig[1, 1]; bottomspinevisible=false)
    # scatter!(ax, fill(1.0, nrow(df_avg)), df_avg.better_threshold; color=freq_colors["high"])
    # scatter!(ax, [1.25], [mean(df_avg.better_threshold)]; color=freq_colors["high"], markersize=15.0)
    # errorbars!(ax, [1.25], [mean(df_avg.better_threshold)], [1.96*std(df_avg.better_threshold)/sqrt(length(df_avg.better_threshold))]; color=freq_colors["high"], whiskerwidth=15.0, linewidth=3.0)
    # xlims!(ax, (0.5, 1.5))
    # hidexdecorations!(ax)
    # ax.ylabel = "Absolute threshold at 16 kHz (dB SPL)"
    set_theme!(theme_thesis(), fontsize=20.0)

    # Load profile-analysis behavior data 
    # Load data from disk, rename "Control" and "Task" to "Level discrimination" and "Profile analysis"
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis_extra_2024_with_order.csv")))

    # Preproccess to calculate condition-wise means
    df_ind = @chain df begin
        groupby([:freq, :task, :n_comp, :order, :subj])
        @combine(:threshold = mean(:threshold))
    end

    # Rename df_ind to df_pa
    df_pa = df_ind

    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "0.2_measure_thresholds_extra_2024_clean_data.csv")))

    # Analyze into means
    df_ind = @chain df begin
        @orderby(:freq)
        @transform(:freq_group = :freq .< 6100)
        groupby([:freq, :freq_group, :subj])
        @combine(:threshold = mean(:threshold))
    end

    # Rename df_ind to df_msk_thr
    df_msk_thr = df_ind

    # At this point, we have :
    # - df_pa (profile analysis 2024 data)
    # - df_abs_thr (absolute threshold data for 16 kHz)
    # - df_msk_thr (masked threshold data for 16 kHz)
   
    # Now we want to create a master dataframe that contains all the info
    subjs = intersect(unique(df_pa.subj), unique(df_abs_thr.subj), unique(df_msk_thr.subj))

    # Map over subjects and create data DataFrame
    dfs = map(subjs) do subj
        # Calculate relevant PA threshold
        ss = @subset(df_pa, :freq .== "High", :subj .== subj)
        thr_pa = mean(ss.threshold)

        # Extract abs and masked thresholds
        thr_abs = @subset(df_abs_thr, :subj .== subj).better_threshold[1]
        thr_msk = @subset(df_msk_thr, :subj .== subj, :freq .== 16100).threshold[1]

        # Construct dataframe
        DataFrame(
            subj=subj,
            thr_pa=thr_pa,
            thr_abs=thr_abs,
            thr_msk=thr_msk,
        )
    end
    df = vcat(dfs...)

    # Now plot!
    fig = Figure(; size=(340, 550))
    kwargs = [
        :markersize => 18.0,
        :linewidth => 3.0,
        :whiskerwidth => 12.0,
    ]

    # PLOT ABS THR
    ax = Axis(fig[1, 1])
    scatter!(ax, df.thr_abs, df.thr_pa; color=freq_colors["high"], kwargs...)
    ax.xlabel = "Absolute threshold (dB SPL)"
    ax.ylabel = "Profile-analysis\nthreshold (dB SRS)"

    # Add trend lines 
    model = lm(@formula(thr_pa ~ thr_abs), df)
    ablines!(ax, coef(model)[1], coef(model)[2]; color=freq_colors["high"])

    pval = pvalue(CorrelationTest(df.thr_pa, df.thr_abs))

    ylims!(ax, 0.0, 15.0)
    xlims!(ax, 10.0, 60.0)
    text!(ax, [40.0], [4.5]; text="R2 = $(round(r2(model); digits=2))", color=freq_colors["high"], fontsize=20.0, font="Arial bold")
    text!(ax, [40.0], [3.0]; text="p = $(round(pval; digits=2))", color=freq_colors["high"], fontsize=20.0, font="Arial bold")

    # PLOT MSK THR
    ax = Axis(fig[2, 1])
    scatter!(ax, df.thr_msk, df.thr_pa; color=freq_colors["high"], kwargs...)
    ax.xlabel = "Masked threshold (dB SPL)"
    ax.ylabel = "Profile-analysis\nthreshold (dB SRS)"

    # Add trend lines 
    model = lm(@formula(thr_pa ~ thr_msk), df)
    ablines!(ax, coef(model)[1], coef(model)[2]; color=freq_colors["high"])

    pval = pvalue(CorrelationTest(df.thr_pa, df.thr_msk))

    ylims!(ax, 0.0, 15.0)
    xlims!(ax, 10.0, 60.0)
    text!(ax, [40.0], [4.5]; text="R2 = $(round(r2(model); digits=2))", color=freq_colors["high"], fontsize=20.0, font="Arial bold")
    text!(ax, [40.0], [3.0]; text="p = $(round(pval; digits=2))", color=freq_colors["high"], fontsize=20.0, font="Arial bold")
    set_theme!(theme_thesis())

    fig
end

function plot_fig_pa2()
    # Load data from disk, rename "Control" and "Task" to "Level discrimination" and "Profile analysis"
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis_extra_2024_with_order.csv")))

   # Preproccess to calculate condition-wise means
    df_ind = @chain df begin
        groupby([:freq, :task, :n_comp, :order, :subj])
        @combine(:threshold = mean(:threshold))
        @orderby(reverse(:freq))
        @orderby(:order)
    end

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
        :markersize => 18.0,
        :linewidth => 3.0,
        :whiskerwidth => 12.0,
    ]

    # Plot guidelines
    hlines!(ax, [13.0]; color=:red)  # one gray line at 13 dB SRS to indicate ceiling max

    # Pick order to plot points and positions along x axis
    seq = [
        ("Control", 1, 1.0),
        ("Task", 1, 2.0),
        ("Control", 2, 4.0),
        ("Task", 2, 5.0),
    ]

    # Plot unroved profile-analysis data
    map(zip(["Low", "High"], colors)) do (freq, color)
        ss = @subset(df_avg, :freq .== freq)
        ss_ind = @subset(df_ind, :freq .== freq)
        map(seq) do (task, order, offset)
            # Plot avg data
            datum = @subset(ss, :order .== order, :task .== task)
            errorbars!(ax, [offset], datum.threshold_mean, datum.threshold_error; color=color, kwargs...)
            scatter!(ax, [offset], datum.threshold_mean; color=color, kwargs...)
            if freq == "High"
                scatter!(ax, [offset], datum.threshold_mean; color=:white, kwargs..., markersize=6.0)
            end

            # Plot individual data
            datum = @subset(ss_ind, :order .== order, :task .== task)
            x = fill(offset[1], nrow(datum)) .+ 0.3 .+ 0.02*randn(nrow(datum))
            scatter!(ax, x, datum.threshold; color=color, kwargs..., markersize=10.0)
            if freq == "High"
                scatter!(ax, x, datum.threshold; color=:white, kwargs..., markersize=3.0)
            end
        end
    end

    # Add manual labels
    scatter!(ax, [0.5], [-10.0]; color=freq_colors["low"], kwargs...)
    text!(ax, [0.8], [-10.0]; color=freq_colors["low"], text="Low", fontsize=20.0, font="Arial bold", align=(:left, :center))
    scatter!(ax, [0.5], [-8.0]; color=freq_colors["high"], kwargs...)
    scatter!(ax, [0.5], [-8.0]; color=:white, kwargs..., markersize=6.0)
    text!(ax, [0.8], [-8.0]; color=freq_colors["high"], text="High", fontsize=20.0, font="Arial bold", align=(:left, :center))

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
    kwargs = [
        :markersize => 18.0,
        :linewidth => 3.0,
        :whiskerwidth => 12.0,
    ]

    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "ripple_discrimination.csv")));

    # Compute individual and group means
    df_ind = @chain df begin
        groupby([:freq, :task, :subj])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    # Create Makie figures and axes
    fig = Figure(; size=(300, 300))
    ax = Axis(
        fig[1, 1]; 
        xticks=([1.5, 4.5], ["Detection", "Discrimination"]),
        ylabel="Threshold [20 log10 (m)]",
        xlabel="Task",
    )
    ylims!(ax, -25.0, 5.0)
    xlims!(ax, 0.5, 5.5)
    hlines!(ax, [0.0]; color=:red)

    # Plot ripples with boxplot
    seq = [
        (1.0, "Low", "Control"),
        (2.0, "High", "Control"),
        (4.0, "Low", "Task"),
        (5.0, "High", "Task"),
    ]
    map(seq) do (offset, freq, task)
        ss = @subset(df_ind, :freq .== freq, :task .== task)
        μ = mean(ss.threshold_mean)
        err = 1.96 * std(ss.threshold_mean)/sqrt(nrow(ss))
        errorbars!(ax, [offset], [μ], [err]; color=freq_colors[lowercase(freq)], kwargs...)
        scatter!(ax, [offset], [μ]; color=freq_colors[lowercase(freq)], kwargs...)
        if freq == "High"
            scatter!(ax, [offset], [μ]; color=:white, kwargs..., markersize=10.0)
        end
        x = fill(offset, nrow(ss)) .+ 0.3 .+ 0.03*randn(nrow(ss))
        scatter!(ax, x, ss.threshold_mean; color=freq_colors[lowercase(freq)], kwargs..., markersize=10.0)
    end
    fig
    return fig
end

function plot_fig_r1b()
    kwargs = [
        :markersize => 18.0,
        :linewidth => 3.0,
        :whiskerwidth => 12.0,
    ]

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

    # Create figure
    fig = Figure(; size=(200, 300))
    ax = Axis(fig[1, 1]; ylabel="Discrimination - Detection (dB)")
    for (freq, x) in zip(["Low", "High"], [1, 2])
        # Subset
        ss = @subset(df_diff, :freq .== freq)

        # Calculate means
        μ = mean(ss.diff)
        err = 1.96 * std(ss.diff)/sqrt(nrow(ss))

        # Plot means and errorbars
        errorbars!(ax, [x], [μ], [err]; color=freq_colors[lowercase(freq)], kwargs...)
        scatter!(ax, [x], [μ]; color=freq_colors[lowercase(freq)], kwargs...)
        if freq == "High"
            scatter!(ax, [x], [μ]; color=:white, kwargs..., markersize=10.0)
        end
    end


    # Plot ind data
    subjs = unique(df_diff.subj)
    n_subj = length(subjs)
    xlo = fill(1.2, n_subj)# .+ 0.03 .* randn(n_subj)
    xhi = fill(1.8, n_subj)# .+ 0.03 .* randn(n_subj)
    diff_lo = @subset(df_diff, :freq .== "Low")
    diff_hi = @subset(df_diff, :freq .== "High")

    for subj in subjs
        ss = @subset(df_diff, :subj .== subj)
        lo = @subset(ss, :freq .== "Low")
        hi = @subset(ss, :freq .== "High")
        lines!(ax, [1.2, 1.8], [lo.diff[1], hi.diff[1]]; color=:lightgray)
    end
    scatter!(ax, xlo, diff_lo.diff; color=freq_colors["low"], kwargs..., markersize=10.0)
    scatter!(ax, xhi, diff_hi.diff; color=freq_colors["high"], kwargs..., markersize=10.0)
    scatter!(ax, xhi, diff_hi.diff; color=:white, kwargs..., markersize=3.0)

    xlims!(ax, 0.5, 2.5)

    # Add ticks
    ax.xticks = ([1, 2], ["Low", "High"])
    ax.xlabel = "Frequency"
    fig
end

function plot_fig_r2a()
    kwargs = [
        :markersize => 18.0,
        :linewidth => 3.0,
        :whiskerwidth => 12.0,
    ]

    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "ripple_discrimination_extra_2024.csv")));
    df = @subset(df, in.(:subj, Ref(subjs_2024())))

    # Compute individual and group means
    df_ind = @chain df begin
        groupby([:freq, :task, :subj])
        @combine(:threshold_mean = mean(:threshold), :threshold_error = 1.96*std(:threshold)/sqrt(length(:threshold)))
    end

    # Create Makie figures and axes
    fig = Figure(; size=(300, 300))
    ax = Axis(
        fig[1, 1]; 
        xticks=([1.5, 4.5], ["Detection", "Discrimination"]),
        ylabel="Threshold [20 log10 (m)]",
        xlabel="Task",
    )
    ylims!(ax, -20.0, 5.0)
    xlims!(ax, 0.5, 5.5)
    hlines!(ax, [0.0]; color=:red)

    # Plot ripples with boxplot
    seq = [
        (1.0, "Low", "Control"),
        (2.0, "High", "Control"),
        (4.0, "Low", "Task"),
        (5.0, "High", "Task"),
    ]
    map(seq) do (offset, freq, task)
        ss = @subset(df_ind, :freq .== freq, :task .== task)
        μ = mean(ss.threshold_mean)
        err = 1.96 * std(ss.threshold_mean)/sqrt(nrow(ss))
        errorbars!(ax, [offset], [μ], [err]; color=freq_colors[lowercase(freq)], kwargs...)
        scatter!(ax, [offset], [μ]; color=freq_colors[lowercase(freq)], kwargs...)
        if freq == "High"
            scatter!(ax, [offset], [μ]; color=:white, kwargs..., markersize=10.0)
        end
        x = fill(offset, nrow(ss)) .+ 0.3 .+ 0.03*randn(nrow(ss))
        scatter!(ax, x, ss.threshold_mean; color=freq_colors[lowercase(freq)], kwargs..., markersize=10.0)
    end
    fig
end

function plot_fig_r2b()
    kwargs = [
        :markersize => 18.0,
        :linewidth => 3.0,
        :whiskerwidth => 12.0,
    ]

    # Load data
    df = DataFrame(CSV.File("data/exp_pro/ripple_discrimination_extra_2024.csv"));
    df = @subset(df, in.(:subj, Ref(subjs_2024())))

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
    for (freq, x) in zip(["Low", "High"], [1, 2])
        # Subset
        ss = @subset(df_diff, :freq .== freq)

        # Calculate means
        μ = mean(ss.diff)
        err = 1.96 * std(ss.diff)/sqrt(nrow(ss))

        # Plot means and errorbars
        errorbars!(ax, [x], [μ], [err]; color=freq_colors[lowercase(freq)], kwargs...)
        scatter!(ax, [x], [μ]; color=freq_colors[lowercase(freq)], kwargs...)
        if freq == "High"
            scatter!(ax, [x], [μ]; color=:white, kwargs..., markersize=10.0)
        end
    end


    # Plot ind data
    subjs = unique(df_diff.subj)
    n_subj = length(subjs)
    xlo = fill(1.2, n_subj)# .+ 0.03 .* randn(n_subj)
    xhi = fill(1.8, n_subj)# .+ 0.03 .* randn(n_subj)
    diff_lo = @subset(df_diff, :freq .== "Low")
    diff_hi = @subset(df_diff, :freq .== "High")

    for subj in subjs
        ss = @subset(df_diff, :subj .== subj)
        lo = @subset(ss, :freq .== "Low")
        hi = @subset(ss, :freq .== "High")
        lines!(ax, [1.2, 1.8], [lo.diff[1], hi.diff[1]]; color=:lightgray)
    end
    scatter!(ax, xlo, diff_lo.diff; color=freq_colors["low"], kwargs..., markersize=10.0)
    scatter!(ax, xhi, diff_hi.diff; color=freq_colors["high"], kwargs..., markersize=10.0)
    scatter!(ax, xhi, diff_hi.diff; color=:white, kwargs..., markersize=3.0)

    xlims!(ax, 0.5, 2.5)

    # Add ticks
    ax.xticks = ([1, 2], ["Low", "High"])
    ax.xlabel = "Frequency"
    fig
end
