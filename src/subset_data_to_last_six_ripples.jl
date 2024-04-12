# Script to take profile-analysis preprocessed data and subset data to only include results
# from final six runs
# NOTE TO SELF: run after add_order_info.jl for convenience

# Handle old profile analysis first
df = DataFrame(CSV.File(projectdir("data", "exp_pro", "ripple_discrimination.csv")))

# Create list of conditions to loop through
conds = ["Control", "Task"]

# Map over conditions to create new dataframe that contains information about run (assuming that the order of rows inidcates the order of runs, persuant with AFC style)
temp = map(conds) do task
    # Subset data to n_comp and task condition
    ss = @subset(df, :task .== task)

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
df = vcat(vcat(temp...)...)

CSV.write(
    projectdir("data", "exp_pro", "ripple_discrimination_with_run_info.csv"), 
    df,
)