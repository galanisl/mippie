library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(plyr)

# Load Mippie PPI Data
load("results/00_cleandata_ppi_10090.RData")

# Load SIGNOR tsv file and apply relevant filters and focus on relevant columns 
signor_ppi <- read_tsv("data/SIGNOR_all_data_26_07_18.tsv") %>% 
  filter(TYPEA == "protein", TYPEB == "protein",
         grepl('^up-reg', EFFECT) | grepl('^down-reg', EFFECT)) %>%
  # filter(TYPEA == "protein", TYPEB == "protein", TAX_ID == 10090,
  #        grepl('^up-reg', EFFECT) | grepl('^down-reg', EFFECT)) %>%
  select(ENTITYA, ENTITYB, EFFECT)

# Remove duplicates
signor_ppi <- signor_ppi[!duplicated(signor_ppi), ]

# Focus on relevant columns of nodes
nodes_reduced <- nodes %>% 
  select("name", "symbol") %>% 
  mutate("symbol" = str_to_upper(.$symbol))

rm(nodes, pin)

# Focus on relevant columns of edges and join twice with nodes_reduced
# First to get symbols for column "from", Second to get symbols for column "to"
edges_reduced <- edges %>% 
  select("from", "to") %>% 
  left_join(nodes_reduced, by = c("from" = "name")) %>% 
  left_join(nodes_reduced, by = c("to" = "name"), suffix = c(".from", ".to"))

rm(edges, nodes_reduced)

# Join with signor_ppi to get first direction of interaction (+1) and effects
edges_reduced1 <- edges_reduced %>% 
  left_join(signor_ppi, by = c("symbol.from" = "ENTITYA", 
                               "symbol.to" = "ENTITYB")) %>% 
  mutate(direction = case_when(!is.na(EFFECT) ~ 1)) %>% 
  select("from", "to", "EFFECT", "direction") %>% 
  dplyr::rename(effect = EFFECT)

# Join with signor_ppi to get second direction of interaction (-1) and effects
edges_reduced2 <- edges_reduced %>% 
  left_join(signor_ppi, by = c("symbol.from" = "ENTITYB", 
                               "symbol.to" = "ENTITYA")) %>% 
  mutate(direction = case_when(!is.na(EFFECT) ~ -1)) %>% 
  select("from", "to", "EFFECT", "direction") %>% 
  dplyr::rename(effect = EFFECT)

rm(edges_reduced)

# Final join and conditional mutate to get ouput table
edges_dir <- left_join(edges_reduced1, edges_reduced2, by = c("from", "to")) %>% 
  mutate(direction = case_when(direction.x == 1 & is.na(direction.y) ~ 1, 
                               direction.y == -1 & is.na(direction.x) ~ -1, 
                               direction.x == 1 & direction.y == -1 ~ 0), 
         effect = case_when(!is.na(effect.x) & is.na(effect.y) ~ effect.x, 
                            !is.na(effect.y) & is.na(effect.x) ~ effect.y, 
                            effect.x == effect.y ~ effect.x)) %>% 
  select(-effect.x, -effect.y, -direction.x, -direction.y) %>% 
  distinct(from, to, direction, .keep_all = TRUE) %>% 
  mutate(effect = str_extract(effect, "(up-regulates)|(down-regulates)"))
rm(edges_reduced1, edges_reduced2, signor_ppi)

save(edges_dir, file = "results/01_ppi2SIGNOR.RData")

