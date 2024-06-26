# Script to add order info to the profile_analysis_extra_2024 data
df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis_extra_2024.csv")))
df = @subset(df, in.(:subj, Ref(subjs_2024())))
order = Dict(
    "x01" => 2,
    "x02" => 1,
    "x07" => 2,
    "x09" => 2,
    "x11" => 2,
    "x14" => 2,
    "x15" => 1,
    "x16" => 1,
    "x17" => 1,
    "x25" => 2,
    "x28" => 1,
    "x29" => 2,
    "x32" => 2,
    "x33" => 1,
    "x34" => 1,
    "x35" => 1,
    "x36" => 2,
    "x37" => 2,
    "x38" => 1,
    "x39" => 1,
    "x41" => 2,
    "x43" => 2,
)
df[!, :order] .= getindex.(Ref(order), df.subj)
CSV.write(
    projectdir("data", "exp_pro", "profile_analysis_extra_2024_with_order.csv"), 
    df,
)