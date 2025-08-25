
library(PSICQUIC)
library(readr)
library(dplyr)
library(purrr)
library(tidyr)

species <- "10090"

# List of protein coding genes
proteins <- read_tsv(paste0("data/protein-coding_", species, ".txt"), 
                     quote = "")

# Initialise connection to PSICQUIC
psicquic <- PSICQUIC()

# Retrieve experimentally-detected interactions for each protein
ppi <- vector("list", nrow(proteins))

for(i in 1:nrow(proteins)){
  ppi[[i]] <- interactions(psicquic, proteins$symbol[i], species = species, 
                           type = c("association", 
                                    "physical association", 
                                    "direct interaction",
                                    "colocalization"))
  ppi[[i]] <- ppi[[i]] %>% 
      select(A, B, type, detectionMethod, publicationID, provider)

}

# Put the interactions together in a tibble and remove duplicate rows (column 
# 'provider' is not considered because diff. providers can report the same PPI)
ppi <- as_tibble(map_df(ppi, rbind))
ppi <- ppi[!duplicated(ppi[, 1:5]), ]

# Extract the protein ID from the corresponding columns
ppi <- ppi %>% 
  separate(A, into = c("A_src", "A_id"), sep = ":") %>% 
  separate(B, into = c("B_src", "B_id"), sep = ":") %>% 
  select(-A_src, -B_src)

# Identify unique IDs for mapping with MyGene
ids <- union(ppi$A_id, ppi$B_id)

save(ppi, file = paste0("data/psicquic_", species, ".RData"))
save(ids, file = paste0("data/ids_", species, ".RData"))

