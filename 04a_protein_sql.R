
library(dplyr)

load("results/00_cleandata_ppi_10090.RData")
rm(pin)
load("results/02_protein2tissue.RData")
rm(rpkm)

# Assign a numeric ID to each unique tissue
tissue <- tibble(tid = 1:length(unique(p2t$tissue)), tissue = unique(p2t$tissue))

# Prepare SQL file to fill the tissue table in MIPPIE
tis <- ""
for(i in 1:nrow(tissue)){
  tis <- paste0(tis, 'INSERT INTO tissue (id, name) VALUES (', 
                    tissue$tid[i], ', "', tissue$tissue[i], '");\n')
}

# Prepare SQL file to insert protein info into MIPPIE
protein <- ""
p2ent <- ""
p2mgi <- ""
p2uni <- ""
p2tis <- ""
for(i in 1:nrow(nodes)){
  protein <- paste0(protein, 'INSERT INTO protein (id, name) VALUES (', 
                    nodes$name[i], ', "', nodes$symbol[i], '");\n')
  
  p2ent <- paste0(p2ent, 'INSERT INTO protein2entrez (protein_id, gene_id, name)', 
                  'VALUES (', nodes$name[i], ', ', nodes$name[i], ', "',
                  nodes$symbol[i], '");\n')
  
  if(!(nodes$mgi[i] == "")){
    p2mgi <- paste0(p2mgi, 'INSERT INTO protein2mgi (protein_id, mgi) VALUES (', 
                    nodes$name[i], ', "', nodes$mgi[i], '");\n')  
  }
  
  for(j in 1:length(nodes$uniprot[[i]])){
    if(!is.na(nodes$uniprot[[i]][j])){
      p2uni <- paste0(p2uni, 'INSERT INTO protein2uniprot (protein_id, uniprot_id, version) VALUES (', 
                      nodes$name[i], ', "', nodes$uniprot[[i]][j], '", ', 1, ');\n')
    }
  }
  
  # Get the tissues in which protein i is expressed
  expr_tissues <- p2t$tissue[p2t$entrez == nodes$name[i]]
  tids <- tissue$tid[tissue$tissue %in% expr_tissues]
  if(length(tids) > 0){
    for(j in 1:length(tids)){
      p2tis <- paste0(p2tis, 'INSERT INTO protein2tissue (protein_id, tissue_id) VALUES (', 
                      nodes$name[i], ', ', tids[j], ');\n')
    }
  }
}

# Write the generated SQL scripts
write(tis, file = "SQL/tissue.sql")
write(protein, file = "SQL/protein.sql")
write(p2ent, file = "SQL/protein2entrez.sql")
write(p2mgi, file = "SQL/protein2mgi.sql")
write(p2uni, file = "SQL/protein2uniprot.sql")
write(p2tis, file = "SQL/protein2tissue.sql")