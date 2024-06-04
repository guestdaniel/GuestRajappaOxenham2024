export print_subj_counts, print_ceiling_counts

function print_subj_counts()
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis.csv")))
    @chain df begin
        groupby([:subj, :task])
        @combine(:n = length(:threshold))
        @orderby(:task)
    end
end

function print_ceiling_counts()
    # Load data from disk, rename "Control" and "Task" to "Level discrimination" and "Profile analysis"
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis_restricted.csv")))
    df = @orderby(df, :n_comp)
    mapper = Dict("Control" => "Level discrimination", "Task" => "Profile analysis")
    df[!, :task] = [mapper[x] for x in df.task]

    # Calculate and print
    results = @chain df begin 
        @subset(:n_comp .== 1)
        groupby([:task, :freq])
        @combine(
            :n_fail = sum(:sd .== 0.0),
            :n_pass = sum(:sd .!= 0.0),
        )
        @transform(
            :n_total = :n_pass .+ :n_fail,
            :pct = :n_fail ./ (:n_pass .+ :n_fail) .* 100.0,
        )
    end
    print(results)

    results = @chain df begin 
        @subset(:n_comp .> 1)
        groupby([:task, :freq])
        @combine(
            :n_fail = sum(:sd .== 0.0),
            :n_pass = sum(:sd .!= 0.0),
        )
        @transform(
            :n_total = :n_pass .+ :n_fail,
            :pct = :n_fail ./ (:n_pass .+ :n_fail) .* 100.0,
        )
    end
    print(results)


    # Load data from disk, rename "Control" and "Task" to "Level discrimination" and "Profile analysis"
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis_extra_2024_restricted.csv")))
    df = @orderby(df, :n_comp)
    mapper = Dict("Control" => "Level discrimination", "Task" => "Profile analysis")
    df[!, :task] = [mapper[x] for x in df.task]

    # Calculate and print
    results = @chain df begin 
        groupby([:task, :freq])
        @combine(
            :n_fail = sum(:sd .== 0.0),
            :n_pass = sum(:sd .!= 0.0),
        )
        @transform(
            :n_total = :n_pass .+ :n_fail,
            :pct = :n_fail ./ (:n_pass .+ :n_fail) .* 100.0,
        )
    end
    print(results)

    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "ripple_discrimination.csv")));

    # Calculate and print
    results = @chain df begin 
        groupby([:task, :freq])
        @combine(
            :n_fail = sum(:sd .== 0.0),
            :n_pass = sum(:sd .!= 0.0),
        )
        @transform(
            :n_total = :n_pass .+ :n_fail,
            :pct = :n_fail ./ (:n_pass .+ :n_fail) .* 100.0,
        )
    end
    print(results)

    # Load data
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "ripple_discrimination_extra_2024.csv")));
    df = @subset(df, in.(:subj, Ref(subjs_2024())))
    df = @subset(df, :subj .!= "x43")  # exclude x43 (0 dB threshold for both detection)
    df = @subset(df, :subj .!= "x33")  # exclude x33 (0 dB threshold for HF detection)


    # Calculate and print
    results = @chain df begin 
        groupby([:task, :freq])
        @combine(
            :n_fail = sum(:sd .== 0.0),
            :n_pass = sum(:sd .!= 0.0),
        )
        @transform(
            :n_total = :n_pass .+ :n_fail,
            :pct = :n_fail ./ (:n_pass .+ :n_fail) .* 100.0,
        )
    end
    print(results)
end