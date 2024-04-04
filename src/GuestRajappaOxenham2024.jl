module GuestRajappaOxenham2024

using DataFrames
using DataFramesMeta
using Distributions
using CairoMakie
using CSV
using Chain 
using Statistics
using Colors
using DrWatson
using HypothesisTests

# Set parameters/constants/etc
freq_colors = Dict("low" => "#7fc97f", "high" => "#beaed4")
#set_theme!(theme_thesis())

# Load code
include("theme.jl")
set_theme!(theme_thesis())
include("stimuli.jl")
include("control_models.jl")  # control observer models 
include("plotting.jl")        # plotting code

end # module GuestRajappaOxenham2024
