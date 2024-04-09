# Libraries
library(ggplot2)
library(dplyr)
library(lme4)
library(car)
library(phia)
library(effects)
library(lmerTest)
library(merTools)
library(customR)
source('scripts/aim3/utils.R')

# Set up directories
dir_out = 'data/stats'

# Import data
data = read.csv(file.path("data", "exp_pro", "ripple_discrimination_extra_2024.csv"))
data = data[!is.nan(data$threshold), ]

# Set up model
model = lmer(threshold ~ freq*task + (freq*task|subj), data=data)

# Report model
name = "ripples_extra_2024_"

# Calculate ANOVA
model_anova = Anova(model, test="F")

# Frequency contrast (overall mean low vs high)
model_contrast_1 = testInteractions(model, pairwise="freq", adjustment="none")
# n_comp contrast (test each adjacent condition)
model_contrast_2 = testInteractions(model, pairwise="task", adjustment="none")
# n_comp * frequency contrast (test 1 vs 15 for low and high)
model_contrast_3 = testInteractions(model, pairwise=c("freq"), fixed="task", adjustment="none")
model_contrast_4 = testInteractions(model, pairwise=c("freq", "task"), adjustment="none")
# Adjust p-values
p_vals = c(model_contrast_1[, "Pr(>Chisq)"], model_contrast_2[, "Pr(>Chisq)"], model_contrast_3[, "Pr(>Chisq)"], model_contrast_4[, "Pr(>Chisq)"])
p_vals = p.adjust(p_vals, method="holm")
model_contrast_1[, "Pr(>Chisq)"] = p_vals[1]
model_contrast_2[, "Pr(>Chisq)"] = p_vals[2]
model_contrast_3[, "Pr(>Chisq)"] = p_vals[3:4]
model_contrast_4[, "Pr(>Chisq)"] = p_vals[5]

# Analyze model
sink(file.path(dir_out, paste0(name, "model.txt")))
summary(model)
model_anova
model_contrast_1
model_contrast_2
model_contrast_3
model_contrast_4
sink()

