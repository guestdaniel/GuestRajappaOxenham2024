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
data = read.csv(file.path("data", "exp_pro", "profile_analysis_extra_2024_with_order.csv"))
data = data[!is.nan(data$threshold), ]
data$n_comp = factor(data$n_comp)
data$order = factor(data$order)

# Set up model
model = lmer(threshold ~ freq*order*task + (1 + task*freq|subj), data=data)

## Control part
name = "profile_analysis_extra_2024_"

# Calculate ANOVA
model_anova = Anova(model, test="F")

# Calculate contrasts
model_contrast_1 = testInteractions(model, pairwise=c("order", "task"), adjustment="none")
model_contrast_2 = testInteractions(model, pairwise=c("task"), fixed="order", adjustment="none")
p_vals = c(model_contrast_1[, "Pr(>Chisq)"], model_contrast_2[, "Pr(>Chisq)"])
p_vals = p.adjust(p_vals, method="holm")
model_contrast_1[, "Pr(>Chisq)"] = p_vals[1]
model_contrast_2[, "Pr(>Chisq)"] = p_vals[2:length(p_vals)]

# Analyze model
sink(file.path(dir_out, paste0(name, "model.txt")))
summary(model)
model_anova
model_contrast_1
model_contrast_2
sink()