module GuestRajappaOxenham2024

# Standard packages
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

# Custom packages
using AuditoryNerveFiber
using AuditorySignalUtils

# Exports
export subjs_2024

# Set parameters/constants/etc
freq_colors = Dict("low" => "#7fc97f", "high" => "#beaed4")

# Load code
include("theme.jl")
include("stimuli.jl")
include("control_models.jl")  # control observer models 
include("plotting.jl")        # plotting code
include("numbers.jl")

subjs_2024() = ["x01", "x02", "x07", "x09", "x11", "x14", "x15", "x16", "x17", "x25", "x28", "x29", "x32", "x33", "x34", "x35", "x36", "x37", "x38", "x39"]

end # module GuestRajappaOxenham2024
