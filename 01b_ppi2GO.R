
# Given a term of a functional ontology, we associate an interaction with this 
# function when both interactors are annotated with either the given functional 
# term or with children of it in the hierarchy of the ontology.
# We excluded the rather unspecific top-level terms GO:0008150 'biological 
# process', GO:0005575 'cellular component' and GO:0005623 'cell'.

library(dplyr)
library(ontologyIndex)
# library(GO.db)

get_aspect <- function(term, go){
  pars <- get_ancestors(go, term)
  if("GO:0008150" %in% pars){
    return("biological_process")
  }else if("GO:0005575" %in% pars){
    return("cellular_component")
  }else if("GO:0003674" %in% pars){
    return("molecular_function")
  }else{
    return(NA)
  }
}

# Given a gene symbol, gets a tibble with its associated GO terms
get_GO <- function(symbol, go2g, go){
  terms <- go2g$GO_id[grep(symbol, go2g$genes, ignore.case = TRUE)]
  if(length(terms) > 0){
    terms <- terms[!go$obsolete[terms]]
    # aspects <- as.character(Ontology(terms))
    aspects <- sapply(terms, get_aspect, go)
    terms <- terms[!is.na(aspects)]
    aspects <- aspects[!is.na(aspects)]
    go_terms <- tibble(GO = terms, ONTOLOGY = aspects) %>% 
      dplyr::filter(!duplicated(terms))
  }else{
    go_terms <- tibble(GO = terms, ONTOLOGY = character())
  }
  
  return(go_terms)
}

# Given a tibble of GO terms and their Ontology type, it returns a bigger tibble
# that includes the children of each term
get_children <- function(go_terms, go){
  if(nrow(go_terms) > 0){
    ch <- get_descendants(ontology = go, roots = go_terms$GO)
    ch <- ch[!go$obsolete[ch]]
    # aspects <- as.character(Ontology(ch))
    aspects <- sapply(ch, get_aspect, go)
    ch <- ch[!is.na(aspects)]
    aspects <- aspects[!is.na(aspects)]
    go_terms <- rbind(go_terms, tibble(GO = ch, ONTOLOGY = aspects)) %>% 
      dplyr::filter(!duplicated(GO))
    go_terms <- go_terms %>% 
      mutate(name = as.character(sapply(go$name[GO], `[`, 1)),
             parent = as.character(sapply(go$parents[GO], 
                                          function(x) ifelse(is.null(x), NA, x))),
             parent_name = as.character(sapply(go$name[parent], `[`, 1)))
    go_terms <- go_terms %>% 
      filter(GO %in% minimal_set(go, GO))
      # mutate(name = as.character(Term(GO)),
      #        parent = as.character(sapply(go$parents[GO], 
      #                                     function(x) ifelse(is.null(x), NA, x))))
  }else{
    go_terms <- go_terms %>% 
      mutate(name = character(), parent = character(), parent_name = character())
  }
  
  return(go_terms)
}

load("results/00_cleandata_ppi_10090.RData")
rm(pin)

mgi <- get_ontology("data/goslim_generic.obo",
                    propagate_relationships =
                      get_relation_names("data/goslim_generic.obo"),
                    extract_tags = "everything")
# data("go")
# mgi <- go
# rm(go)

go2g <- readr::read_tsv("data/MGIgenes_by_GOid.txt") %>% 
  dplyr::filter(GO_id %in% mgi$id)

goAB <- vector("list", nrow(edges))

for(i in 1:nrow(edges)){
  symbolA <- nodes$symbol[nodes$name == edges$from[i]]
  goA <- get_GO(symbolA, go2g, mgi) %>% 
    get_children(mgi)
  symbolB <- nodes$symbol[nodes$name == edges$to[i]]
  goB <- get_GO(symbolB, go2g, mgi) %>% 
    get_children(mgi)
  goAB[[i]] <- dplyr::intersect(goA, goB)
}

save(goAB, file = "results/01_ppi2go.RData")





