
library(dplyr)
library(stringr)
library(readr)

load("results/00_cleandata_ppi_10090.RData")
rm(pin, nodes)
load("results/03_mippie_scores.RData")
load("results/01_ppi2species.RData")

# Form tibbles with unique PPI type, detection method, source and species
type <- unique(
  sapply(
    str_split(
      unlist(
        str_split(edges$type, ",")
        ), "-mi:"
      ), `[`, 2
    )
  )
type <- str_split(type, "\\(")
type_psi <- sapply(type, `[`, 1)
type_name <- str_extract(sapply(type, `[`, 2), "[a-z A-Z]+")
type <- tibble(id = 1:length(type_psi), name = type_name, psi = type_psi)

query <- ""
for(i in 1:nrow(type)){
  query <- paste0(query, 'INSERT INTO interaction_type (id, name, psi) VALUES (', 
                  type$id[i], ', "', type$name[i], '", "', type$psi[i], '");\n')
}
write(query, file = "SQL/interaction_type.sql")

exp_type <- read_tsv("data/experimental_scores.tsv", quote = "") %>% 
  filter(!is.na(PSI) & PSI != "MI:")
exp_type$name <- str_extract(exp_type$technique, "[^\\(]+(?=\\))")
exp_type <- exp_type %>% 
  mutate(id = 1:nrow(exp_type)) %>% 
  select(id, name, PSI, score)

query <- ""
for(i in 1:nrow(exp_type)){
  query <- paste0(query, 'INSERT INTO experiment_type (id, name, psi, score) VALUES (', 
                  exp_type$id[i], ', "', exp_type$name[i], '", "', 
                  exp_type$PSI[i], '", ', exp_type$score[i], ');\n')
}
write(query, file = "SQL/experiment_type.sql")

provider <- unique(unlist(str_split(edges$provider, ",")))
provider <- tibble(id = 1:length(provider), name = provider, link = 
                     c("https://www.ebi.ac.uk/intact",
                       "https://thebiogrid.org",
                       "https://mentha.uniroma2.it",
                       "http://www.ucl.ac.uk/functional-gene-annotation/psicquic/Tabs/bhf-ucl-dataset",
                       "http://irefindex.org", "https://www.imexconsortium.org",
                       "https://mint.bio.uniroma2.it", "http://hpidb.igbb.msstate.edu",
                       "https://www.uniprot.org"))

query <- ""
for(i in 1:nrow(provider)){
  query <- paste0(query, 'INSERT INTO source (id, name, link) VALUES (', 
                  provider$id[i], ', "', provider$name[i], '", "', provider$link[i], '");\n')
}
write(query, file = "SQL/source.sql")

species <- sort(unique(unlist(spc)))
species <- tibble(id = 1:length(species), name = c("Saccharomyces cerevisiae",
                                                   "Caenorhabditis elegans",
                                                   "Drosophila melanogaster",
                                                   "Homo sapiens",
                                                   "Rattus norvegicus"),
                  taxid = species)

query <- ""
for(i in 1:nrow(species)){
  query <- paste0(query, 'INSERT INTO species (id, name) VALUES (', 
                  species$id[i], ', "', species$name[i], '");\n')
}
write(query, file = "SQL/species.sql")

pmid <- str_split(edges$pubID, ",")
pmid <- lapply(pmid, function(x) str_extract(x, "[0-9]+"))

# Prepare SQL file to insert PPI info into MIPPIE
ppi <- ""
i2typ <- ""
i2exp <- ""
i2src <- ""
i2spc <- ""
i2pmi <- ""
for(i in 1:nrow(edges)){
  ppi <- paste0(ppi, 'INSERT INTO interaction (id, protein_id_1, protein_id_2, score) VALUES (', 
                    i, ', ', edges$from[i], ', ', edges$to[i], ', ', mippie_scr[i], ');\n')
  
  for(j in 1:length(pmid[[i]])){
    i2pmi <- paste0(i2pmi, 'INSERT INTO interaction2pubmed (interaction_id, pmid) VALUES (', 
                    i, ', ', pmid[[i]][j], ');\n')
  }
  
  spcID <- species$id[species$taxid %in% spc[[i]]]
  if(length(spcID) > 0){
    for(j in 1:length(spcID)){
      i2spc <- paste0(i2spc, 'INSERT INTO interaction2species (interaction_id, species_id) VALUES (', 
                      i, ', ', spcID[j], ');\n')
    }
  }
  
  typ <- str_split(edges$type[i], ",")[[1]]
  typ <- str_extract(typ, "[^\\(]+(?=\\))")
  typ <- type$id[type$name %in% typ]
  for(j in 1:length(typ)){
    i2typ <- paste0(i2typ, 'INSERT INTO interaction2type (interaction_id, type_id) VALUES (', 
                    i, ', ', typ[j], ');\n')
  }
  
  expe <- str_split(edges$detMethod[i], ",")[[1]]
  expe <- str_extract(expe, "[^\\(]+(?=\\))")
  expe <- exp_type$id[exp_type$name %in% expe]
  for(j in 1:length(expe)){
    i2exp <- paste0(i2exp, 'INSERT INTO interaction2experiment (interaction_id, experiment_id) VALUES (', 
                    i, ', ', expe[j], ');\n')
  }
  
  prov <- str_split(edges$provider[i], ",")[[1]]
  prov <- provider$id[provider$name %in% prov]
  for(j in 1:length(prov)){
    i2src <- paste0(i2src, 'INSERT INTO interaction2source (interaction_id, source_id) VALUES (', 
                    i, ', ', prov[j], ');\n')
  }
}

# Write the generated SQL scripts
write(ppi, file = "SQL/interaction.sql")
write(i2typ, file = "SQL/interaction2type.sql")
write(i2exp, file = "SQL/interaction2experiment.sql")
write(i2src, file = "SQL/interaction2source.sql")
write(i2spc, file = "SQL/interaction2species.sql")
write(i2pmi, file = "SQL/interaction2pubmed.sql")


