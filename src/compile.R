# This script takes data files generated using process.R and concatenates them into larger, more useful data files
source("src/utils.R")

# Compile profile analysis data (original experiment)
load(file.path("data", "exp_pro", "1.1c_profile_analysis_control_clean_data.RData"))  # load unroved data
data_unroved = dat
data_unroved$task = "Control"
load(file.path("data", "exp_pro", "1.1_profile_analysis_clean_data.RData"))           # load roved data
data_roved = dat
data_roved$task = "Task"
data = rbind(data_unroved, data_roved)                                                # concatenate
data$freq = factor(data$freq, levels=c(300, 6100), labels=c('Low', 'High'))           # factorize frequency
data$task = factor(data$task)                                                         # factorize task
data = data[substr(data$subj, 1, 1) == "x", ]
write.csv(data, file.path("data", "exp_pro", "profile_analysis.csv"))

# Compile profile analysis data (2024 followup experiment)
load(file.path("data", "exp_pro", "1.1c_profile_analysis_control_extra_2024_clean_data.RData"))  # load unroved data
data_unroved = dat
data_unroved$task = "Control"
load(file.path("data", "exp_pro", "1.1_profile_analysis_extra_2024_clean_data.RData"))           # load roved data
data_roved = dat
data_roved$task = "Task"
data = rbind(data_unroved, data_roved)                                                # concatenate
data$freq = factor(data$freq, levels=c(300, 6100), labels=c('Low', 'High'))           # factorize frequency
data$task = factor(data$task)                                                         # factorize task
data = data[substr(data$subj, 1, 1) == "x", ]
write.csv(data, file.path("data", "exp_pro", "profile_analysis_extra_2024.csv"))

# Compile ripple data (original experiment)
load(file.path("data", "exp_pro", "1.2c_ripple_discrimination_control_clean_data.RData"))  # load detection data
data_detection = dat
data_detection$task = "Control"
load(file.path("data", "exp_pro", "1.2_ripple_discrimination_clean_data.RData"))           # load discrimination data
data_discrimination = dat
data_discrimination$task = "Task"
data = rbind(data_detection, data_discrimination)                                                # concatenate
data$freq = factor(data$freq, levels=c(1, 2), labels=c('Low', 'High'))           # factorize frequency
data$task = factor(data$task)                                                         # factorize task
data = data[substr(data$subj, 1, 1) == "x", ]
write.csv(data, file.path("data", "exp_pro", "ripple_discrimination.csv"))

# Compile ripple data (2024 followup experiment)
load(file.path("data", "exp_pro", "1.2c_ripple_discrimination_control_extra_2024_clean_data.RData"))  # load detection data
data_detection = dat
data_detection$task = "Control"
load(file.path("data", "exp_pro", "1.2_ripple_discrimination_extra_2024_clean_data.RData"))           # load discrimination data
data_discrimination = dat
data_discrimination$task = "Task"
data = rbind(data_detection, data_discrimination)                                                # concatenate
data$freq = factor(data$freq, levels=c(1, 2), labels=c('Low', 'High'))           # factorize frequency
data$task = factor(data$task)                                                         # factorize task
data = data[substr(data$subj, 1, 1) == "x", ]
write.csv(data, file.path("data", "exp_pro", "ripple_discrimination_extra_2024.csv"))

# NOTE!!!! DON'T FORGET TO ADD ORDER INFO VIA ADD_ORDER_INFO.JL