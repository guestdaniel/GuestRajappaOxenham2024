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
using GLM

export subjs_2024

# Set parameters/constants/etc
freq_colors = Dict("low" => "#7fc97f", "high" => "#beaed4")
#set_theme!(theme_thesis())

# Load code
include("theme.jl")
include("stimuli.jl")
include("control_models.jl")  # control observer models 
include("plotting.jl")        # plotting code
include("numbers.jl")

subjs_2024() = ["x01", "x02", "x07", "x09", "x14", "x15", "x16", "x17", "x25", "x28", "x29"]

end # module GuestRajappaOxenham2024
