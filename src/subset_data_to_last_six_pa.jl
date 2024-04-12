# Script to take profile-analysis preprocessed data and subset data to only include results
# from final six runs
# NOTE TO SELF: run after add_order_info.jl for convenience

# Handle old profile analysis first
df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis.csv")))

# Create list of conditions to loop through
conds = Iterators.product([1, 3, 5, 9, 15], ["Control", "Task"])

# Map over conditions to create new dataframe that contains information about run (assuming that the order of rows inidcates the order of runs, persuant with AFC style)
temp = map(conds) do (n_comp, task)
    # If we're in the 1-component profile analysis condition, continue
    if (n_comp == 1) & (task == "Task")
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

CSV.write(
    projectdir("data", "exp_pro", "profile_analysis_with_run_info.csv"), 
    df,
)
CSV.write(
    projectdir("data", "exp_pro", "profile_analysis_restricted.csv"), 
    @subset(df, :run .> 6),
)

# Handle new profile analysis first
df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis_extra_2024_with_order.csv")))

# Create list of conditions to loop through
conds = Iterators.product([9], ["Control", "Task"])

# Map over conditions to create new dataframe that contains information about run (assuming that the order of rows inidcates the order of runs, persuant with AFC style)
temp = map(conds) do (n_comp, task)
    # If we're in the 1-component profile analysis condition, continue
    if (n_comp == 1) & (task == "Task")
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
df = @subset(df, :run .> 3)

CSV.write(
    projectdir("data", "exp_pro", "profile_analysis_extra_2024_restricted.csv"), 
    df,
)