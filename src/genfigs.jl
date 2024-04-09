# This script generates and saves all of the paper figures to disk
# Note that some of these figures are then further pre-processed and arranged in Inkscape
using GuestRajappaOxenham2024
using CairoMakie  # so we can set theme

# Set theme (no upper/right box, outward ticks)
set_theme!(theme_thesis())

# Plot schematic stimulus spectra
for n_comp in [1, 3, 5, 9, 15]
    for freq in ["Low", "High"]
        fig = plot_schematic_stimulus(freq, n_comp)
        save(projectdir("plots", "schematic_stimulus_$(freq)_$(n_comp).png"), fig, px_per_unit=5)
    end
end

# Plot Experiment 1a
fig = plot_fig_pa1()
save(projectdir("plots", "profile_analysis.png"), fig, px_per_unit=5)
fig = plot_fig_pa1_learning_v2()
save(projectdir("plots", "profile_analysis_learning.png"), fig, px_per_unit=5)

# Plot Experiment 1b
fig = plot_fig_pa2()
save(projectdir("plots", "profile_analysis_extra_2024.png"), fig, px_per_unit=5)
fig = plot_fig_pa2_sl()
save(projectdir("plots", "profile_analysis_extra_2024_sl.png"), fig, px_per_unit=5)

# Plot Experiment 2a
fig = plot_fig_r1a()
save(projectdir("plots", "ripples_a.png"), fig, px_per_unit=5)
fig = plot_fig_r1b()
save(projectdir("plots", "ripples_b.png"), fig, px_per_unit=5)

# Plot Experiment 2b
fig = plot_fig_r2a()
save(projectdir("plots", "ripples_a_extra_2024.png"), fig, px_per_unit=5)
fig = plot_fig_r2b()
save(projectdir("plots", "ripples_b_extra_2024.png"), fig, px_per_unit=5)

# Plot Experiment 3
fig = plot_fig_thr()
save(projectdir("plots", "thresholds_in_ten.png"), fig, px_per_unit=5)
