library(dplyr)

load("results/01_ppi2SIGNOR.RData")

i2dir <- ""
i2eff <- ""
k <- 1
for(i in 1:nrow(edges_dir)){
  if(!is.na(edges_dir$direction[i]) & edges_dir$direction[i] != 0){
    print(k)
    i2dir <- paste0(i2dir, 'INSERT INTO interaction2keggDirection (interaction_id, direction) VALUES (', 
                 i, ', ', edges_dir$direction[i], ');\n')
    if(edges_dir$effect[i] == "up-regulates"){
      eff <- 1
    }else{
      eff <- -1
    }
    if(edges_dir$direction[i] == 1){
      direc <- 1
    }else{
      direc <- 25
    }
    i2eff <- paste0(i2eff, 'INSERT INTO interaction2effect (interaction_id, effect_type, source) VALUES (', 
                    i, ', ', eff, ', ', direc, ');\n')
    k <- k + 1
  }
}

write(i2dir, file = "SQL/interaction2keggDirection.sql")
write(i2eff, file = "SQL/interaction2effect.sql")
