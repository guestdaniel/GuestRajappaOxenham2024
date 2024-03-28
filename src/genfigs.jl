# This script generates and saves all of the paper figures to disk
# Note that some of these figures are then further pre-processed and arranged in Inkscape
fig = plot_fig_pa1()
save(projectdir("plots", "profile_analysis.png"), fig, px_per_unit=5)

plot_fig_pa2()
save(projectdir("plots", "profile_analysis_extra_2024.png"), fig, px_per_unit=5)

plot_fig_r1a()
save(projectdir("plots", "ripples_a.png"), fig, px_per_unit=5)
plot_fig_r2a()
save(projectdir("plots", "ripples_b.png"), fig, px_per_unit=5)

plot_fig_r2a()
save(projectdir("plots", "ripples_a_extra_2024.png"), fig, px_per_unit=5)
plot_fig_r2b()
save(projectdir("plots", "ripples_b_extra_2024.png"), fig, px_per_unit=5)
