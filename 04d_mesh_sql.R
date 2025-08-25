library(dplyr)
library(purrr)

load("results/01_ppi2mesh.RData")

all_mesh <- map_df(ppi2mesh, rbind)
all_mesh <- filter(all_mesh, !duplicated(all_mesh))

# Generate SQL script for mesh_term
mesh <- ""
for(i in 1:nrow(all_mesh)){
  mesh <- paste0(mesh, 'INSERT INTO mesh_term (number, name) VALUES ("', 
               all_mesh$NUMBER[i], '", "', all_mesh$MESHTERM[i], '");\n')
}

# Generate SQL script for interaction2mesh
i2mesh <- ""
for(i in 1:length(ppi2mesh)){
  if(nrow(ppi2mesh[[i]]) > 0){
    for(j in 1:nrow(ppi2mesh[[i]])){
      i2mesh <- paste0(i2mesh, 'INSERT INTO interaction2mesh (interaction_id,',
                     'term_number) VALUES (', i, ', "', ppi2mesh[[i]]$NUMBER[j], '");\n')
    }
  }
}

write(mesh, file = "SQL/mesh_term.sql")
write(i2mesh, file = "SQL/interaction2mesh.sql")