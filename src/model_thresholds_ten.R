# Libraries
library(ggplot2)
library(dplyr)
library(lme4)
library(car)
library(phia)
library(effects)
source('src/utils.R')

# Set up directories
dir_out = 'data/stats'

# Import data
data = read.csv(file.path("data", "exp_pro", "0.2_measure_thresholds_extra_2024_clean_data.csv"))
data = data[(data$subj != "x18") & (data$subj != "x20"), ]  # get rid of x18/x20
data = data[!is.nan(data$threshold), ]
data$freq = factor(data$freq)

# Set up model
model = lmer(threshold ~ freq + (freq|subj), data=data)

# Report model
name = "thresholds_extra_2024_"

# Calculate ANOVA
model_anova = Anova(model, test="F")
model_means = interactionMeans(model, fixed="freq")

# Refit model with average low-frequency threshold subtracted, then test significance of 
# high frequency conditions
data = read.csv(file.path("data", "exp_pro", "0.2_measure_thresholds_extra_2024_clean_data.csv"))
data = data[(data$subj != "x18") & (data$subj != "x20"), ]  # get rid of x18/x20
data = data[!is.nan(data$threshold), ]
data_adj = data
data_adj$threshold = data_adj$threshold - mean(data_adj[data_adj$freq < 6000, "threshold"])
data_adj$freq = factor(data_adj$freq)
model = lmer(threshold ~ freq + (freq|subj), data=data_adj)

# Frequency contrast (overall mean low vs high)
model_contrast_1 = testInteractions(model, fixed="freq", adjustment="none")
model_contrast_1 = model_contrast_1[c(4, 5, 6), ]
p_vals = p.adjust(p_vals, method="holm")
model_contrast_1[, "Pr(>Chisq)"] = p.adjust(model_contrast_1[, "Pr(>Chisq)"], method="holm")

# Analyze model
sink(file.path(dir_out, paste0(name, "model.txt")))
summary(model)
model_anova
model_means
model_contrast_1
sink()


