
library(dplyr)
library(readr)

load("results/00_cleandata_ppi_10090.RData")
rm(pin)

i2d <- read_tsv("data/i2d.2_9.Public.MOUSE.tab")
i2d_src <- read_tsv("data/i2d_sources.tsv")
i2d <- left_join(i2d, i2d_src, by = c("Dataset" = "db"))
rm(i2d_src)

spc <- vector("list", nrow(edges))

for(i in 1:nrow(edges)){
  uA <- nodes$uniprot[nodes$name == edges$from[i]][[1]]
  uB <- nodes$uniprot[nodes$name == edges$to[i]][[1]]
  spcAB <- i2d$taxid[(i2d$SwissProt1 %in% uA) & (i2d$SwissProt2 %in% uB)]
  spcBA <- i2d$taxid[(i2d$SwissProt1 %in% uB) & (i2d$SwissProt2 %in% uA)]
  spc[[i]] <- setdiff(union(spcAB, spcBA), "10090")
}

save(spc, file = "results/01_ppi2species.RData")
