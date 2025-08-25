library(dplyr)
library(readr)
library(readxl)

load("results/00_cleandata_ppi_10090.RData")
rm(edges, pin)

tf <- read_tsv("data/Mus_musculus_TF_AnimalTFDB_v3.txt")
re <- read_excel("data/Cell_Surface_Protein_Atlas.xlsx", sheet = "Table B") %>% 
  filter(!is.na(ENTREZ_gene_ID)) %>% 
  filter(`CSPA category` == "1 - high confidence")

pclass <- tibble(entrez = nodes$name, 
                 tfa = entrez %in% tf$`Entrez ID`,
                 rec = entrez %in% re$ENTREZ_gene_ID,
                 class = case_when(
                   tfa & !rec ~ "tf",
                   !tfa & rec ~ "rec",
                   tfa & rec ~ "b",
                   TRUE ~ "other"
                 ))

p2class <- ""
for(i in 1:nrow(pclass)){
  if(pclass$class[i] != "other"){
    for(j in 1:length(nodes$uniprot[[i]])){
      p2class <- paste0(p2class, 'INSERT INTO sp_analysis_end_nodes (uniprot_id, type) VALUES ("', 
                      nodes$uniprot[[i]][j], '", "', pclass$class[i], '");\n')
    }
  }
}

write(p2class, file = "SQL/protein2class.sql")
