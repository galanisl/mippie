library(dplyr)
library(purrr)

load("results/01_ppi2go.RData")

all_go <- map_df(goAB, rbind)
all_go <- filter(all_go, !duplicated(all_go))

# Add the parents to the tibble
for(i in 1:nrow(all_go)){
  all_go <- rbind(all_go, tibble(GO = all_go$parent[i],
                                 ONTOLOGY = all_go$ONTOLOGY[i],
                                 name = all_go$parent_name[i],
                                 parent = NA,
                                 parent_name = NA))
}
all_go <- filter(all_go, !duplicated(all_go))

# Fix problem with a couple of GO terms and get rid of the GO roots
all_go <- filter(all_go, !(GO == "GO:0003674" & ONTOLOGY == "biological_process"))
all_go <- filter(all_go, !(GO == "GO:0003723" & ONTOLOGY == "biological_process"))

all_go <- filter(all_go, !name %in% c("biological_process", "cellular_component",
                                     "molecular_function"))

# Generate SQL scripts for GO_slim_term and GO_slim_term2term
go <- ""
go2go <- ""
for(i in 1:nrow(all_go)){
  go <- paste0(go, 'INSERT INTO GO_slim_term (id, name, namespace) VALUES ("', 
                all_go$GO[i], '", "', all_go$name[i], '", "', all_go$ONTOLOGY[i], '");\n')
  if(!is.na(all_go$parent[i])){
    go2go <- paste0(go2go, 'INSERT INTO GO_slim_term2term (term_id, parent_term_id) VALUES ("', 
                 all_go$GO[i], '", "', all_go$parent[i], '");\n')
  }else{
    if(all_go$ONTOLOGY[i] == "biological_process"){
      go2go <- paste0(go2go, 'INSERT INTO GO_slim_term2term (term_id, parent_term_id) VALUES ("', 
                      all_go$GO[i], '", "GO:0008150");\n')
    }else if(all_go$ONTOLOGY[i] == "cellular_component"){
      go2go <- paste0(go2go, 'INSERT INTO GO_slim_term2term (term_id, parent_term_id) VALUES ("', 
                      all_go$GO[i], '", "GO:0005575");\n')
    }else{
      go2go <- paste0(go2go, 'INSERT INTO GO_slim_term2term (term_id, parent_term_id) VALUES ("', 
                      all_go$GO[i], '", "GO:0003674");\n')
    }
  }
}

# Generate SQL scripts for interaction2GO
i2go <- ""
for(i in 1:length(goAB)){
  if(nrow(goAB[[i]]) > 0){
    for(j in 1:nrow(goAB[[i]])){
      i2go <- paste0(i2go, 'INSERT INTO interaction2GO (interaction_id,',
                     'term_id) VALUES (', i, ', "', goAB[[i]]$GO[j], '");\n')
    }
  }
}

# Write the generated SQL scripts
write(go, file = "SQL/GO_slim_term.sql")
write(go2go, file = "SQL/GO_slim_term2term.sql")
write(i2go, file = "SQL/interaction2GO.sql")
