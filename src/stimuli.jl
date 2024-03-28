export tone_ensemble, profile_analysis_tone, srs_to_ΔL, ΔL_to_srs

"""
    tone_ensemble(freq, level, phase; kwargs...)

Synthesize a complex tone composed of pure tones with the specified freqs, levels, and phases.

# Arguments
- `freq::Vector{T}`: frequencies of each component in the tone ensemble (Hz)
- `level::Vector{T}`: levels of each component in the tone ensemble (dB SPL)
- `phases::Vector{T}`: staring phases of each component in the tone ensembles (radians), defaults to sine phase
- `dur::T`: duration of components (seconds)
- `dur_ramp::T`: duration of raised cosine ramp applied to each component (seconds)
- `fs::T`: sampling rate (Hz)

# Returns
- `signal::Vector{T}`: tone ensemble
"""
function tone_ensemble(
    freqs::Vector{T}, 
    level::Vector{T}, 
    phase::Vector{T}=repeat([0.0], length(level)); 
    dur::T=1.0, 
    dur_ramp::T=0.1, 
    fs::T=100e3
) where {T<:Real}
    # Create empty output vector
    signal = zeros((Int(floor(dur*fs)), ))
    # Loop through pure tones and synthesize each
    for (_freq, _level, _phase) in zip(freqs, level, phase)
        signal .+= cosine_ramp(scale_dbspl(pure_tone(_freq, _phase, dur, fs), _level), dur_ramp, fs)
    end
    # Return result
    return signal
end

"""
    profile_analysis_tone(freqs::Vector, [target_comp::Int]; kwargs...)

Synthesizes a profile analysis tone composed of a deterministic set of components 

# Arguments
- `freqs::Tuple`: vector of frequenices to include in stimulus
- `target_comp`: which component should contain the increment (index into component_freqs, see code below)

# Returns
- `::Vector`: vector containing profile analysis tone 
"""
function profile_analysis_tone(
    freqs::Vector,
    target_comp::Int=rand(1:length(freqs));
    fs=100e3,
    dur=0.10,
    dur_ramp=0.01,
    pedestal_level=50.0,
    increment=0.0
)
    # Configure component levels
    levels = repeat([pedestal_level], length(freqs))
    levels[target_comp] += increment

    # Synthesize signals 
    stimulus = tone_ensemble(freqs, levels; dur=dur, dur_ramp=dur_ramp, fs=fs)

    # Return
    return stimulus
end

"""
    srs_to_ΔL(srs)

Converts a signal re: standard value in dB to a ΔL in dB.

Here, srs is the signal re: standard, i.e., 20 * log10(ΔA/A), ΔL is the difference between
levels of the standard and the standard + signal in dB.
"""
srs_to_ΔL(srs) = 20 * log10(1 + 10^(srs/20))

"""
    ΔL_to_srs(ΔL)

Converts a ΔL value in dB to a signal re: standard value in dB.

Here, srs is the signal re: standard, i.e., 20 * log10(ΔA/A), ΔL is the difference between
levels of the standard and the standard + signal in dB.
"""
ΔL_to_srs(ΔL) = 20 * log10(10^(ΔL/20) - 1)
