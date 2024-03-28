export calc_overall_level, calc_θ_overall_level_unroved, calc_θ_overall_level_roved,
       calc_θ_ΔL_roved

"""
    calc_overall_level(comp_levels)

Calculate overall level from summating pure tones presented at `comp_levels`

Calculate overall level of complex tone synthesized by summating various pure tone
components of different frequencies with the sound levels specified in the vector
`comp_levels`. The equation used is:
    L = 10 * log10(∑ᵢ 10 ^ (lᵢ / 10))
where L is the overall sound level and lᵢ is the i-th sound level in dB SPL.
"""
function calc_overall_level(comp_levels)
    10.0 * log10(sum(10.0 .^ (comp_levels ./ 10.0)))
end

"""
    calc_θ_overall_level_unroved(df)

Calculate performance of observer attending to overall level changes in unroved PA task

Calculate the theoretical performance of an observer that selects the interval with the 
highest overall level as the target interval, assuming that the observe achieves its
threshold at the same ΔL as required for threshold performance in the pure-tone level 
discrimination task. This is applied for interpretation of the unroved data, where we assume
that performance is dominated by "internal" noise.
"""
function calc_θ_overall_level_unroved(df)
    # Given input dataframe with level-discrimination and profile-analysis data, calculate
    # average pure-tone LDLs in units of dB SRS for both low and high frequencies
    df_θ = @chain df begin
        @subset(:task .== "Level discrimination")
        groupby([:freq, :task, :n_comp, :subj])
        @combine(:threshold = mean(:threshold))
        groupby([:freq, :task, :n_comp])
        @combine(:threshold = mean(:threshold))
        @subset(:n_comp .== 1)
    end
    θ_low = df_θ[df_θ.freq .== "Low", :threshold][1]    # pure-tone LDL for low frequencies, dB SRS
    θ_high = df_θ[df_θ.freq .== "High", :threshold][1]  # pure-tone LDL for high frequencies, dB SRS

    # Map over each tested numbers of components and estimate observer performance
    map([3, 5, 9, 15]) do n_comp
        # For increment values ranging from -30 to 20 dB SRS, calculate overall sound level
        # for profile-analysis reference and target stimuli without level roving
        incs = LinRange(-30.0, 20.0, 2000)  # increments ranging from -30 to 20 dB SRS
        lpc_ref = fill(60.0, size(incs))    # level per component of background (dB SPL)
        lpc_tar = 60.0 .+ srs_to_ΔL.(incs)  # level per component of target (dB SPL)
        # Overall level in reference intervals (dB SPL)
        ol_ref = map(x -> calc_overall_level(fill(x, n_comp)), lpc_ref)
        # Overall level in target intervals (dB SPL)
        ol_tar = map(x -> calc_overall_level(vcat(fill(x[1], n_comp-1), x[2])), zip(lpc_ref, lpc_tar))
        ΔL = ol_tar .- ol_ref

        # Estimate thresholds as dB SRS value where ΔL exceeds pure-tone LDL 
        θ_control_low = incs[findfirst(ΔL .> srs_to_ΔL(θ_low))]
        θ_control_high = incs[findfirst(ΔL .> srs_to_ΔL(θ_high))]

        # Return
        return θ_control_low, θ_control_high
    end
end

"""
    calc_θ_overall_level_roved()

Calculate performance of observer attending to overall level changes in roved PA task

Calculate the theoretical performance of an observer that selects the interval with the
highest overall level as the target interval, assuming that the observer makes perfect
estimates of overall level (i.e., performance is limited only by "external" or
rove-associated noise). The returned threshold is the threshold at the 79.4% correct point 
on the psychometric function. 
"""
function calc_θ_overall_level_roved()
    # Map over each tested numbers of components and estimate observer performance
    map([3, 5, 9, 15]) do n_comp
        # For increment values ranging from -30 to 20 dB SRS, do...
        N = 5000
        incs = LinRange(-30.0, 20.0, 2000)
        ΔL = map(incs) do inc
            # For N simualed trials at this increment, draw from the rove distribution
            # (uniform from 50 to 70 dB SPL) and determine the per-component level of:
            # background in reference trials (lpc_ref), background in target trials
            # (lpc_tar_back), and target in target trials (lpc_tar_tar)
            lpc_ref = rand(Uniform(50.0, 70.0), N)       # background level per comp in reference interval (dB SPL)
            lpc_tar_back = rand(Uniform(50.0, 70.0), N)  # background level per comp in target interval (dB SPL)
            lpc_tar_tar =  lpc_tar_back .+ srs_to_ΔL.(inc)   # target level per comp in target interval (dB SPL)

            # Overall level in N reference intervals (dB SPL)
            ol_ref = map(x -> calc_overall_level(fill(x, n_comp)), lpc_ref)

            # Overall level in N target intervals (dB SPL)
            ol_tar = map(x -> calc_overall_level(vcat(fill(x[1], n_comp-1), x[2])), zip(lpc_tar_back, lpc_tar_tar))

            # Return ΔL
            ol_tar .- ol_ref  # vector length N
        end

        # Calculate control threshold as dB SRS value where target interval has higher
        # overall level in at least 79.4% of trials
        θ_control = incs[findfirst(mean.(map(x -> x .> 0.0, ΔL)) .> 0.794)]

        # Return
        return θ_control
    end
end

"""
    calc_θ_ΔL_roved()

Calculate performance of observer attending to target level changes (i.e., ΔL) in roved PA task

Calculate the theoretical performance of an observer that selects the interval with the
highest target level as the target interval, assuming that the observer makes perfect
estimates of target level (i.e., performance is limited only by "external" or
rove-associated noise). The returned threshold is the threshold at the 79.4% correct point 
on the psychometric function. 
"""

function calc_θ_ΔL_roved()
    # For increment values ranging from -30 to 20 dB SRS, do...
    N = 5000
    incs = LinRange(-30.0, 20.0, 2000)
    ΔL = map(incs) do inc
        # For N simualed trials at this increment, draw from the rove distribution
        # (uniform from 50 to 70 dB SPL) and determine the level of:
        # target component in reference trials (l_ref), target component in target trials (l_tar)
        l_ref = rand(Uniform(50.0, 70.0), N)                       # target level in reference interval (dB SPL)
        l_tar =  rand(Uniform(50.0, 70.0), N) .+ srs_to_ΔL.(inc)   # target level in target interval (dB SPL)

        # Return ΔL
        l_tar .- l_ref  # vector length N
    end

    # Calculate control threshold as dB SRS value where target interval has higher
    # overall level in at least 79.4% of trials
    θ_control = incs[findfirst(mean.(map(x -> x .> 0.0, ΔL)) .> 0.794)]

    # Return
    return θ_control
end