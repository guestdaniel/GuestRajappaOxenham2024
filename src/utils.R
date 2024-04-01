# Title     : TODO
# Objective : TODO
# Created by: daniel
# Created on: 5/28/21

preprocess_data_file <- function(experiment_name, column_names, vars_to_factor, ceiling_val){
  #' Preprocesses a data file for the F31 experiment
  #'
  #' @param experiment_name string String indcating which experiment to preprocess
  #' @param column_names vector Vector of strings indicating what to call the colnames. Must match the number of columns
  #'    in the loaded datafile or things will blow up.
  #' @param vars_to_factor vector Vector of strings indcating which columns to turn into factors
  #' @param ceiling_val float Value to set failed runs to

  # Define data directories data and create as necessary
  raw_data_dir = file.path("data", "exp_raw", experiment_name, "data")
  clean_data_dir = file.path("data", "exp_pro")

  # Collect data into data frame
  data_files = list.files(raw_data_dir)
  data_files = data_files[grepl(".dat", data_files)]
  subj_ids = regmatches(data_files, regexpr("[A-z]{1}\\d{2,3}", data_files))
  dat = data.frame()
  for (ii in seq_along(data_files)) {
    # Read data from disk
	temp = read.table(paste0(raw_data_dir, "/", data_files[ii]), sep="", header=T, row.names=NULL, fill=TRUE)
    # Set column names
    colnames(temp) = column_names
	temp$subj = subj_ids[ii]
    for (var_to_factor in vars_to_factor) {
	  temp[, var_to_factor] = factor(as.numeric(temp[, var_to_factor]))
    }
	dat = rbind(dat, temp)
  }
  # Filter out any data that don't have "x" as the alpha code at the start of the subject ID
  #dat = dat[substr(dat$subj, 1, 1) == 'x', ]
  # Set any threshold where sd == 0 (run failed) to max
  dat[dat$sd == 0, "threshold"] = ceiling_val
  # Factorize subject
  dat$subj = factor(dat$subj)
  # Save clean version to disk
  save(dat, file=file.path(clean_data_dir, paste0(experiment_name, "_clean_data.RData")))
  write.csv(dat, file=file.path(clean_data_dir, paste0(experiment_name, "_clean_data.csv")))
}

preprocess_data_file_2024 <- function(experiment_name, column_names, ceiling_val){
  #' Preprocesses a data file for the F31 experiment (2024)
  #'
  #' @param experiment_name string String indcating which experiment to preprocess
  #' @param column_names vector Vector of strings indicating what to call the colnames. Must match the number of columns
  #'    in the loaded datafile or things will blow up.
  #' @param ceiling_val float Value to set failed runs to

  # Define data directories data and create as necessary
  raw_data_dir = file.path("data", "exp_raw", experiment_name, "data") 
  clean_data_dir = file.path("data", "exp_pro")

  # Collect data into data frame
  data_files = list.files(raw_data_dir)
  data_files = data_files[grepl(".dat", data_files)]
  subj_ids = regmatches(data_files, regexpr("[A-z]{1}\\d{2,3}", data_files))
  dat = data.frame()
  for (ii in seq_along(data_files)) {
    # Read data from disk
	temp = read.table(paste0(raw_data_dir, "/", data_files[ii]), sep="", header=T, row.names=NULL, fill=TRUE)
    # Set column names
    colnames(temp) = column_names
	temp$subj = subj_ids[ii]
	dat = rbind(dat, temp)
  }
  # Filter out any data that don't have "x" as the alpha code at the start of the subject ID
  #dat = dat[substr(dat$subj, 1, 1) == 'x', ]

  # Set any threshold where sd == 0 (run failed) to max
  dat[dat$sd == 0, "threshold"] = ceiling_val

  # Factorize subject
  dat$subj = factor(dat$subj)

  # Save clean version to disk
  save(dat, file=file.path(clean_data_dir, paste0(experiment_name, "_clean_data.RData")))
  write.csv(dat, file=file.path(clean_data_dir, paste0(experiment_name, "_clean_data.csv")))
}

load_data <- function(experiment_code, experiment_name, filter_xids=TRUE) {
  # List all directories matching experiment_code
  data_files = list.files('data/exp_pro')[grepl(experiment_name, list.files('data/exp_pro'))]
  data_files = data_files[grepl("RData", data_files)]
  # Create storage for data
  data = data.frame()
  # Loop through these directories
  for (file in data_files) {
    # Extract file name parts
    subexperiment_name = strsplit(file, '_')[[1]]
    subexperiment_name = paste(subexperiment_name[3:(length(subexperiment_name)-2)], collapse='_')
    # Load in data for this subexperiment and add name
    data_name = file.path('data', 'exp_pro', file)
    load(data_name)
    dat$task = subexperiment_name
    data = rbind(data, dat)
  }
  # Handle experiment-specific stuff
  if (experiment_code == '1.1') {
    data$freq = factor(data$freq, levels=c(300, 6100), labels=c('Low', 'High'))
    data$task = factor(data$task, levels=c('profile_analysis_control', 'profile_analysis'), labels=c('Control', 'Task'))
  } else if (experiment_code == '1.2') {
    data$freq = factor(data$freq, levels=c(1, 2), labels=c('Low', 'High'))
    data$task = factor(data$task, levels=c('ripple_discrimination_control', 'ripple_discrimination'), labels=c('Control', 'Task'))
  } else if (experiment_code == '2.1') {
    data$F0 = factor(data$F0, levels=c(280, 1400))
    data$task = factor(data$task, levels=c('component_segregation_control', 'component_segregation_am', 'component_segregation_oa'), labels=c('Control', 'AM', 'OA'))
    # Loop through and indicate for each subject what git commit they ran on
    for (subj in levels(data$subj)) {
      if (subj %in% c('x08', 'x29')) {
        data[data$subj == subj, "commit"] = "25f668b (10 Hz)"
      } else if (subj %in% c('x23', 'x00', 'x02', 'x27')) {
        data[data$subj == subj, "commit"] = "b27b870 (4 Hz)"
      } else {
        data[data$subj == subj, "commit"] = "2fdf0a4 (current)"
      }
    }
  } else if (experiment_code == '2.2') {
    data$real_F0 = factor(data$F0, levels=c(280, 1400, 140, 700))
    data$F0 = 'none'
    data[data$real_F0 == 280 | data$real_F0 == 140, "F0"] = "Low"
    data[data$real_F0 == 1400 | data$real_F0 == 700, "F0"] = "High"
    data$F0 = factor(data$F0, levels=c('Low', 'High'))
    data$task = factor(data$task, levels=c('hct_segregation_control', 'hct_segregation_nocue_all', 'hct_segregation_nocue_even',
                                           'hct_segregation_nocue_oddeven', 'hct_segregation_am_all', 'hct_segregation_am_even',
                                           'hct_segregation_oa_all', 'hct_segregation_oa_even'),
                       labels=c('Control', 'No Cue All', 'No Cue Even', 'No Cue Odd-Even', 'AM All', 'AM Even', 'OA All', 'OA Even'))
  }
  # Filter out non x-ids (optionally)
  if (filter_xids) {
    data = data[substr(data$subj, 1, 1) == 'x', ]
  }
  return(data)
}