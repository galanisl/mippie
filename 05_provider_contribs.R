
library(dplyr)

load("results/00_cleandata_ppi_10090.RData")

# Compute the number of PPIs contributed by each provider
providers <- strsplit(edges$provider, ",")

tot_counts <- table(unlist(providers))

unique_counts <- table(unlist(providers[lengths(providers) == 1]))
