# Source
source("src/utils.R")

# Process 0.1
preprocess_data_file('0.1_screen_audibility', c('freq', 'threshold', 'sd', 'n/a'), c('freq'), NaN)

# Process 1.1, 1.2
for (experiment_name in c('1.1c_profile_analysis_control', '1.1_profile_analysis')) {
   preprocess_data_file(experiment_name, c('n_comp', 'freq', 'threshold', 'sd'), c('freq'), 13)
}
for (experiment_name in c('1.2c_ripple_discrimination_control', '1.2_ripple_discrimination')) {
  preprocess_data_file(experiment_name, c('freq', 'threshold', 'sd'), c('freq'), 0)
}

# Process 0.1 (2024)
preprocess_data_file_2024('0.1_screen_audibility_extra_2024', c('ear', 'threshold', 'sd', 'n/a'), NaN)

# Process 0.2 (2024)
preprocess_data_file_2024('0.2_measure_thresholds_extra_2024', c('freq', 'threshold', 'sd'), NaN)

# Process 1.1c (2024)
preprocess_data_file_2024('1.1c_profile_analysis_control_extra_2024', c('n_comp', 'freq', 'threshold', 'sd'), 13)

# Process 1.1 (2024)
preprocess_data_file_2024('1.1_profile_analysis_extra_2024', c('n_comp', 'freq', 'threshold', 'sd'), 13)

# Process 1.2c (2024)
preprocess_data_file_2024('1.2c_ripple_discrimination_control_extra_2024', c('freq', 'threshold', 'sd'), 0)

# Process 1.2 (2024)
preprocess_data_file_2024('1.2_ripple_discrimination_extra_2024', c('freq', 'threshold', 'sd'), 0)