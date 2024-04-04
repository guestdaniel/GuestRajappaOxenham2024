export print_subj_counts

function print_subj_counts()
    df = DataFrame(CSV.File(projectdir("data", "exp_pro", "profile_analysis.csv")))
    @chain df begin
        groupby([:subj, :task])
        @combine(:n = length(:threshold))
        @orderby(:task)
    end
end