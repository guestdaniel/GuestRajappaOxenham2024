# Libraries
library(ggplot2)
library(dplyr)
library(lme4)
library(car)
library(phia)
library(effects)
source(file.path("src", "utils.R"))

# Select output directory
dir_out = file.path("data", "stats")

# Import data
data = read.csv(file.path("data", "exp_pro", "profile_analysis_with_run_info.csv"))
data = data[!is.nan(data$threshold), ]
data$n_comp = factor(data$n_comp)

# Set up model
data_ss = data[data$n_comp != 1, ]
data_ss[data_ss$run %in% c(1, 2, 3), "run_group"] = 1
data_ss[data_ss$run %in% c(4, 5, 6), "run_group"] = 2
data_ss[data_ss$run %in% c(7, 8, 9), "run_group"] = 3
data_ss[data_ss$run %in% c(10, 11, 12), "run_group"] = 4
data_ss$run_group = factor(data_ss$run_group)

model = lmer(threshold ~ freq*run_group + (1 + freq|subj) + (1 + run_group|subj), data=data_ss)
name = "profile_analysis_learning"

# Calculate ANOVA
model_anova = Anova(model, test="F")

# Frequency contrast (overall mean low vs high)
model_contrast_1 = testInteractions(model, pairwise="run_group", fixed="freq", adjustment="holm")

# Analyze model
sink(file.path(dir_out, paste0(name, "model.txt")))
summary(model)
model_anova
model_contrast_1
sink()

