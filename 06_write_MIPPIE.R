
library(dplyr)
library(readr)

load("results/00_cleandata_ppi_10090.RData")
rm(pin)
load("results/01_ppi2species.RData")
load("results/03_mippie_scores.RData")

# PPI data
edges <- edges %>% 
  rename(entrezA = from, entrezB = to, num_studies = w, exp_scores = dm,
         exp_techniques = detMethod, studies = pubID) %>% 
  mutate(other_organisms = sapply(spc, function(x) paste(x, collapse = ",")),
         num_organisms = lengths(spc), MIPPIE_score = mippie_scr) %>% 
  select(entrezA, entrezB, MIPPIE_score, type, provider,
         studies, num_studies, 
         other_organisms, num_organisms, 
         exp_techniques, exp_scores)
write_tsv(x = edges, path = "downloads/mippie_ppi_v1_0.tsv")

# Protein data
nodes <- nodes %>% 
  mutate(uniprot = sapply(uniprot, function(x) paste(x, collapse = ","))) %>% 
  rename(entrez = name, official_symbol = symbol, 
         uniprot_accession = uniprot)
  
write_tsv(x = nodes, path = "downloads/mippie_proteins_v1_0.tsv")