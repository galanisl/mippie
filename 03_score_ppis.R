
library(dplyr)

get_subscore <- function(a, w){
  return(2/(1 + exp(-a * w)) - 1)
}

load("results/00_cleandata_ppi_10090.RData")
rm(nodes, pin)
load("results/01_ppi2species.RData")

#a_s, a_o, a_t respectively
a <- c(1, 1.5, 0.5)

#w_s, w_o, w_t respectively
w <- c(0.6, 0.1, 0.3)


mippie_scr <- w[1]*get_subscore(a[1], edges$w) +
  w[2]*get_subscore(a[2], lengths(spc)) +
  w[3]*get_subscore(a[3], edges$dm)

save(mippie_scr, file = "results/03_mippie_scores.RData")
