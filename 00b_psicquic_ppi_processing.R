
library(dplyr)
library(readr)
library(mygene)
library(igraph)
library(stringr)

species = "10090"

# Load data
load(paste0("data/ids_", species, ".RData"))
load(paste0("data/psicquic_", species, ".RData"))

# Create tibble for the ID mappings
ids <- tibble(id = ids, 
              entrez = character(length(ids)), 
              symbol = character(length(ids)),
              mgi = character(length(ids)),
              uniprot = vector("list", length(ids)))

# Get symbols and entrez for each ID
# Though, MyGene.info offers the queryMany function, we do a for loop because we
# don't really know the scope of each PSICQUIC ID
for(i in 1:nrow(ids)){
  tmp <- tryCatch({query(ids$id[i], species = species)}, 
                  error = function(e){return(list(total = 0))})
  if(tmp$total > 0){
    if("entrezgene" %in% colnames(tmp$hits)){
      tmp$hits <- filter(tmp$hits, !is.na(entrezgene))
      ids$entrez[i] <- tmp$hits$entrezgene[1]
      tmp <- getGene(ids$entrez[i], fields = c("symbol", "uniprot", "MGI"))
      ids$symbol[i] <- tmp[[1]]$symbol[1]
      if(!is.null(tmp[[1]]$MGI[1])){
        ids$mgi[i] <- tmp[[1]]$MGI[1]  
      }
      if(!is.null(tmp[[1]]$uniprot)){
        if(!is.null(tmp[[1]]$uniprot$`Swiss-Prot`)){
          ids$uniprot[[i]] <- tmp[[1]]$uniprot$`Swiss-Prot`
        }else if(!is.null(tmp[[1]]$uniprot$TrEMBL)){
          ids$uniprot[[i]] <- tmp[[1]]$uniprot$TrEMBL
        }
      }
    }else{
      ids$entrez[i] <- "-"
      ids$symbol[i] <- "-"
    }
  }else{
    ids$entrez[i] <- "-"
    ids$symbol[i] <- "-"
  }
}
ids <- ids %>% 
  filter(!is.na(entrez))
ids$uniprot[sapply(ids$uniprot, is.null)] <- NA

save(ids, file = paste0("results/id_map_", species, ".RData"))

# Now join the ID mapping with the PPI data
ppi <- left_join(ppi, ids, by = c("A_id" = "id")) %>% 
  dplyr::rename(entrezA = entrez, symbolA = symbol, mgiA = mgi, uniprotA = uniprot)
ppi <- left_join(ppi, ids, by = c("B_id" = "id")) %>% 
  dplyr::rename(entrezB = entrez, symbolB = symbol, mgiB = mgi, uniprotB = uniprot)

# Get rid of original ID columns, remove duplicates, unmapped cases and consider
# only valida PUBMED IDs
ppi <- ppi %>% 
  dplyr::select(-A_id, -B_id) %>% 
  filter(!duplicated(dplyr::select(ppi, -provider))) %>% 
  filter(!(entrezA == "-" | entrezB == "-"))

pubs <- str_extract_all(ppi$publicationID, "pubmed:([0-9]+)")

ppi <- ppi %>% 
  filter(lengths(pubs) > 0) %>% 
  mutate(publicationID = sapply(pubs[lengths(pubs) > 0], `[`, 1))

# Sort entrez gene IDs per row to detect parallel edges
for(i in 1:nrow(ppi)){
  tmp <- sort(as.character(ppi[i, c("entrezA" ,"entrezB")]))
  if(ppi$entrezA[i] != tmp[1]){
    ppi$entrezA[i] <- tmp[1]
    ppi$entrezB[i] <- tmp[2]  
    sA <- ppi$symbolA[i]
    ppi$symbolA[i] <- ppi$symbolB[i]
    ppi$symbolB[i] <- sA
    uA <- ppi$uniprotA[[i]]
    ppi$uniprotA[[i]] <- ppi$uniprotB[[i]]
    ppi$uniprotB[[i]] <- uA
    mA <- ppi$mgiA[i]
    ppi$mgiA[i] <- ppi$mgiB[i]
    ppi$mgiB[i] <- mA
  }
}

ppi <- ppi %>% 
  filter(!duplicated(dplyr::select(ppi, -provider)))

# Assign detection method reliability based on HIPPIE data
exp_scores <- read_tsv("data/experimental_scores.tsv", quote = "") %>% 
  filter(!is.na(PSI))

ppi <- mutate(ppi, detMethodScr = 0)

for(i in 1:nrow(exp_scores)){
  ppi$detMethodScr[grep(exp_scores$PSI[i], 
                        ppi$detectionMethod)] <- exp_scores$score[i]
}

# Save meta-data
save(ids, ppi, file = paste0("results/00_metadata_ppi_", species, ".RData"))

# Prepare final node data
nodes <- ids %>% 
  dplyr::select(entrez, symbol, uniprot, mgi) %>% 
  filter(entrez != "-") %>%
  filter(!duplicated(entrez))

# Group by PPI, count evidence sources and sum detection method scores
edges <- ppi %>% 
  group_by(entrezA, entrezB) %>% 
  summarise(w = n(), dm = sum(detMethodScr), 
            type = paste(type, collapse = ","),
            detMethod = paste(detectionMethod, collapse = ","),
            pubID = paste(publicationID, collapse = ","),
            provider = paste(provider, collapse = ","))

# Create graph
pin <- igraph::graph_from_data_frame(edges, directed = FALSE, vertices = nodes)
pin <- igraph::simplify(pin, remove.multiple = TRUE, remove.loops = FALSE, 
                        edge.attr.comb = list(w = "sum", dm = "sum",
                                              type = toString, 
                                              detMethod = toString,
                                              pubID = toString,
                                              provider = toString))

# Get rid of isolated nodes
pin <- igraph::delete_vertices(pin, v = which(degree(pin) == 0))

# Get the clean data
nodes <- as_tibble(igraph::as_data_frame(pin, what = "vertices"))
edges <- as_tibble(igraph::as_data_frame(pin, what = "edges"))

# Save clean data
save(nodes, edges, pin, 
     file = paste0("results/00_cleandata_ppi_", species, ".RData"))

