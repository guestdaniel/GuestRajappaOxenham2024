# GuestRajappaOxenham2024
This is the code and data repository for Guest, Rajappa, and Oxenham (2024), "Profile analysis at high frequencies."

## Data
Raw data are available in subfolders of `data/exp_raw`, organized in the following way:
- *Experiment 1a*: `0.1_screen_audibility` (screening data), `1.1_profile_analysis` (roved), and `1.1c_profile_analysis_control` (unroved)
- *Experiment 1b*: `0.1_screen_audibility_extra_2024` (screening data), `1.1_profile_analysis_extra_2024` (roved), and `1.1c_profile_analysis_control_extra_2024` (unroved)
- *Experiment 2a*: `1.2c_ripple_discrimination_control` (detection) and `1.2_ripple_discrimination` (discrimination)
- *Experiment 2b*: `1.2c_ripple_discrimination_control_extra_2024` (detection) and `1.2_ripple_discrimination_extra_2024` (discrimination)
- *Experiment 3*: `0.2_measure_thresholds_extra_2024`
Each subfolder contains a `data` folder, containing thresholds measured in each run, and a `control` folder, containing information about the order in which conditions were randomized for each participant.
The files are tagged with participant ids in the form `x00`, where `00` is the participant ID.

For convenience, preprocessed data are available in the following files in the `data/exp_pro` folder:
- `profile_analysis_restricted.csv` All listeners' level-discrimination and profile-analysis data from the final six runs of each condition in Experiment 1a, used to generate Figure 2
- `profile_analysis_extra_2024_restricted.csv` All listeners' level-discrimination and profile-analysis data from the final three runs of each condition in Experiment 1b, used to generate Figure 3
- `ripple_discrimination.csv` All listeners' ripple detection and discrimination data from Experiment 1a, used to generate Figure 4
- `ripple_discrimination_extra_2024.csv` All listeners' ripple detection and discrimination data from Experiment 1b, used to generate Figure 5
- `0.2_measure_thresholds_extra_2024_clean_data.csv` All listeners' tone-in-noise detection data from Experiment 3, used to generate Figure 6

In all data files, each row is data from a single run.
Columns are labeled and indicate the following:
- `n_comp`: Component density (1, 3, 5, 9, or 15)
- `freq`: Frequency condition (Low or High) or tone frequency (in Hz)
- `subj`: Subject ID
- `threshold`: Threshold estimate for run
- `task`: Either "Control" (level discrimination/unroved, for profile analysis, or detection, for ripples) or "Task" (roved, for profile analysis, or discrimination, for ripples)
- `order`: Only for Experiment 1b, a value of `1` indicates that unroved was competed first while a value of `2` indicates that roved was completed first

## Workflow
To reproduce our results: 
1. Download this repository and install recent versions of R and Julia.

2. Set the working directories of your R/Julia interpreters to the folder containing this README file.

3. Install necessary R packages (dplyr, lme4, car, phia, and effects should suffice)

4. Set up your Julia environment using the package included in this repository. Opening your interpreter, pressing `]` to open the package manager, and then typing `activate .` followed by `instantiate`, should do the trick.

The following option steps can be performed if you want to preprocess the raw data, but are unnecessary as the results of this preprocessing step are already included in this repository:

5. Run the contents of `src/process.R` to create aggregate `.csv` files from each individual participant's raw `.dat` files

6. Run the contents of `src/compile.R` to join data from different flavors of the same experiment (e.g., roved and unroved profile analysis)

7. Run the contents of `src/add_order_info.jl` to add run-order information to the compiled `.csv` files

8. Run the contents of `src/subset_data_to_last_six_pa.jl` to subset the profile-analysis data to the last six runs

Next, use these steps to compute our statistics:

9. Run the contents of `src/model_profile_analysis.R` to model data in Experiment 1a, `src/model_profile_analysis_extra_2024.R` for Experiment 1b, `src/model_ripples.R` for Experiment 2a, `src/model_ripples_extra_2024.R` for Experiment 2b, and `src/model_thresholds_ten.R` for Experiment 3

Finally, use these steps to generate figures (or subfigures, as in some cases subfigures are assembled manually in Inkscape):

10. Run the contents of `genfigs.jl` to generate each figure/subfigure. The intro figures and Figure 2 can take a bit to generate, but otherwise they should go quickly after precompilation is done. The contents of `genfigs.jl` are commented to make it clear which functions correspond to which figures.