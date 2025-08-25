
library(dplyr)
library(readr)
library(purrr)
library(MeSH.Mmu.eg.db)
library(MeSH.db)

# Focus on the Disease (Category C) branch of the MeSH
mesh_mm <- select(MeSH.Mmu.eg.db, keys = "C", columns = columns(MeSH.Mmu.eg.db), 
                  keytype = "MESHCATEGORY") %>% 
  dplyr::select(GENEID, MESHID) %>% 
  as_tibble()
mesh_mm <- mesh_mm[!duplicated(mesh_mm), ]

# Do the same for the set of MeSH definitions
mesh_db <- select(MeSH.db, keys = "C", columns = columns(MeSH.db), 
                  keytype = "CATEGORY") %>% 
  dplyr::select(MESHID, MESHTERM) %>% 
  as_tibble()
mesh_db <- mesh_db[!duplicated(mesh_db), ]

# Read in MeSH tree numbers and focus on Disease terms
mesh_tree <- readr::read_delim("data/mtrees2018.bin", delim = ";", quote = "",
                               col_names = c("MESHTERM", "NUMBER"))
mesh_tree <- mesh_tree[grep("C", mesh_tree$NUMBER), ]

# Join with mesh_db to get each term's tree number
mesh_db <- dplyr::left_join(mesh_db, mesh_tree, by = "MESHTERM")
mesh_mm <- mesh_mm[!mesh_mm$MESHID %in% mesh_db$MESHID[is.na(mesh_db$NUMBER)], ]
mesh_db <- mesh_db %>% 
  dplyr::filter(!is.na(NUMBER))
rm(mesh_tree)

#------------------------------------------------------------------------------

load("results/00_cleandata_ppi_10090.RData")
rm(pin, nodes)

# Type convert edges and initialize list
edges_int <- type_convert(edges)
rm(edges)
ppi2mesh <- list()

for(i in 1:nrow(edges_int)) {
    
  # For the i-th edge entry retrieve the MESHID from mesh_mm and the NUMBER and 
  # MESHTERM from mesh_db
  mesh_from <- semi_join(mesh_mm, edges_int[i, "from"], 
                         by = c("GENEID" = "from")) %>% 
    left_join(mesh_db, by = "MESHID") %>% 
    dplyr::select(-GENEID, -MESHID) %>% 
    dplyr::filter(!is.na(MESHTERM))
  
  mesh_to <- semi_join(mesh_mm, edges_int[i, "to"], by = c("GENEID" = "to")) %>% 
    left_join(mesh_db, by = "MESHID") %>% 
    dplyr::select(-GENEID, -MESHID) %>% 
    dplyr::filter(!is.na(MESHTERM))

  # Find the intersecting tibble and store in list
  ppi2mesh[[i]] <- semi_join(mesh_from, mesh_to, by = "NUMBER")

}

save(ppi2mesh, file = "results/01c_ppi2mesh.RData")
