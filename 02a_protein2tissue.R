
library(dplyr)
library(tidyr)
library(readr)
library(mygene)

# Read in expression data
rpkm <- read_tsv("data/mouse_rpkm.txt")

# Get rid of genes with no signal
rpkm <- rpkm %>% 
  filter(rowSums(rpkm[, 2:ncol(rpkm)]) > 0)

# Map ENSEMBL gene IDs to Entrez
id_map <- tibble(ensembl = rpkm$gene, entrez = character(nrow(rpkm)))

for(i in 1:nrow(id_map)){
  tmp <- tryCatch({query(id_map$ensembl[i], species = "10090")}, 
                  error = function(e){return(list(total = 0))})
  if(tmp$total > 0){
    if("entrezgene" %in% colnames(tmp$hits)){
      tmp$hits <- filter(tmp$hits, !is.na(entrezgene))
      id_map$entrez[i] <- tmp$hits$entrezgene[1]
    }else{
      id_map$entrez[i] <- "-"
    }
  }else{
    id_map$entrez[i] <- "-"
  }
}

save(id_map, file = "results/id_map_ensembl_10090.RData")

rpkm$entrez <- id_map$entrez

# Get rid of unmapped genes
rpkm <- rpkm %>% 
  dplyr::filter(entrez != "-") %>% 
  dplyr::select(-gene) %>% 
  dplyr::select(entrez, `199_1_Pancreas`:`199_39_Brain`)

# Tidy up data
rpkm <- rpkm %>% 
  gather(`199_1_Pancreas`:`199_39_Brain`, key = "sample", value = "expr") %>% 
  separate(sample, into = c("num1", "num2", "tissue"), sep = "_") %>% 
  dplyr::select(-num1, -num2)

# Compute average expression per gene and tissue
rpkm <- rpkm %>% 
  group_by(entrez, tissue) %>% 
  summarise(expr = mean(expr))

# Only keep genes with at least 1 RPKM of expression
p2t <- rpkm %>% 
  filter(expr >= 1)

save(rpkm, p2t, file = "results/02_protein2tissue.RData")




