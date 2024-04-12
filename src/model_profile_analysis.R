# Libraries
library(dplyr)
library(lme4)
library(car)
library(phia)
library(effects)
source(file.path("src", "utils.R"))

# Select output directory
dir_out = file.path("data", "stats")

# Import data
data = read.csv(file.path("data", "exp_pro", "profile_analysis_restricted.csv"))
data = data[!is.nan(data$threshold), ]
data$n_comp = factor(data$n_comp)

# Set up model
model_control = lmer(threshold ~ freq*n_comp + (freq*n_comp|subj), data=data[data$task == "Control", ])
model_task = lmer(threshold ~ freq*n_comp + (freq*n_comp|subj), data=data[data$task == "Task", ])
model_joint = lmer(threshold ~ freq*n_comp*task + (freq*n_comp*task|subj), data=data[data$n_comp != 1, ])

## Control part
model = model_control
name = "profile_analysis_control_"

# Calculate ANOVA
model_anova = Anova(model, test="F")

# Frequency contrast (overall mean low vs high)
model_contrast_1 = testInteractions(model, pairwise="freq", adjustment="none")
model_contrast_1pt5 = testInteractions(model, pairwise="freq", adjustment="none", fixed="n_comp")
model_contrast_1pt5 = model_contrast_1pt5[1, ]
# n_comp contrast (test each adjacent condition)
model_contrast_2 = testInteractions(model, pairwise="n_comp", adjustment="none")
model_contrast_2 = model_contrast_2[c(1, 5, 8, 10), ]
# n_comp * frequency contrast (test 1 vs 15 for low and high)
model_contrast_3 = testInteractions(model, pairwise=c("n_comp", "freq"), adjustment="none")
model_contrast_3 = model_contrast_3[c(1, 2, 3, 4), ]
# Adjust p-values
p_vals = c(model_contrast_1[, "Pr(>Chisq)"], model_contrast_1pt5[, "Pr(>Chisq)"], model_contrast_2[, "Pr(>Chisq)"], model_contrast_3[, "Pr(>Chisq)"])
p_vals = p.adjust(p_vals, method="holm")
model_contrast_1[, "Pr(>Chisq)"] = p_vals[1]
model_contrast_1pt5[, "Pr(>Chisq)"] = p_vals[2]
model_contrast_2[, "Pr(>Chisq)"] = p_vals[3:6]
model_contrast_3[, "Pr(>Chisq)"] = p_vals[7:10]

# Analyze model
sink(file.path(dir_out, paste0(name, "model.txt")))
summary(model)
model_anova
model_contrast_1
model_contrast_1pt5
model_contrast_2
model_contrast_3
sink()

## Task part
model = model_task
name = "profile_analysis_task_"

# Calculate ANOVA
model_anova = Anova(model, test="F")

# Frequency contrast (overall mean low vs high)
model_contrast_1 = testInteractions(model, pairwise="freq", adjustment="none")
# n_comp contrast (test each adjacent condition)
#model_contrast_2 = testInteractions(model, pairwise="n_comp", adjustment="none")
#model_contrast_2 = model_contrast_2[c(1, 4, 6), ]
# n_comp * frequency contrast (test bowl)
model_contrast_3 = testInteractions(model, pairwise="n_comp", fixed="freq", adjustment="none")
model_contrast_3 = model_contrast_3[c(1, 4, 6, 7, 10, 12), ]
#model_contrast_3 = model_contrast_3[4, ]
# Adjust p-values
p_vals = c(model_contrast_1[, "Pr(>Chisq)"], model_contrast_3[, "Pr(>Chisq)"])
p_vals = p.adjust(p_vals, method="holm")
model_contrast_1[, "Pr(>Chisq)"] = p_vals[1]
#model_contrast_2[, "Pr(>Chisq)"] = p_vals[2:4]
model_contrast_3[, "Pr(>Chisq)"] = p_vals[2:length(p_vals)]

# Analyze model
sink(file.path(dir_out, paste0(name, "model.txt")))
summary(model)
model_anova
model_contrast_1
model_contrast_3
sink()

## Joint part
model = model_joint
name = "profile_analysis_joint_"

# Calculate ANOVA
model_anova = Anova(model, test="F")

# Task contrast in each condition 
model_contrast_1 = testInteractions(model, pairwise="task", fixed=c("freq", "n_comp"), adjustment="none")
# Overall level vs profile high vs low
model_contrast_2 = testInteractions(model, pairwise="task", fixed="freq", adjustment="none")
model_contrast_3 = testInteractions(model, pairwise=c("task", "freq"), adjustment="none")
# Adjust p-values
p_vals = c(model_contrast_1[, "Pr(>Chisq)"], model_contrast_2[, "Pr(>Chisq)"], model_contrast_3[, "Pr(>Chisq)"])
p_vals = p.adjust(p_vals, method="holm")
model_contrast_1[, "Pr(>Chisq)"] = p_vals[1:8]
model_contrast_2[, "Pr(>Chisq)"] = p_vals[9:10]
model_contrast_3[, "Pr(>Chisq)"] = p_vals[11]

# Analyze model
sink(file.path(dir_out, paste0(name, "model.txt")))
summary(model)
model_anova
model_contrast_1
model_contrast_2
model_contrast_3
sink()
