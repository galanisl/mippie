
library(dplyr)
library(readr)

#' Re-computes confidence scores for PPIs in MIPPIE
#' 
#' Given the full MIPPIE data file and a file of experimental scores, it re-
#' scores MIPPIE's PPIs with user-defined parameters.
#' 
#' @param path.to.mippie character; The path to the file containing the MIPPIE 
#' database.
#' @param path.to.exp.scores character; The path to the file reporting the scores
#' assigned to the experimental techniques used to measure MIPPIE's interactions.
#' @param a_s numeric; Controls how fast the study subscore saturates (between 0 
#' and Inf), default value (as used in the paper) is 1.
#' @param a_o numeric; Controls how fast the orthology subscore saturates (between 
#' 0 and Inf), default value (as used in the paper) is 1.5.
#' @param a_t numeric; Controls how fast the technique subscore saturates (between 
#' 0 and Inf), default value (as used in the paper) is 0.5.
#' @param w_s numeric; Contribution of the study subscore to the overall score 
#' (between 0 and 1), default value (as used in the paper) is 0.6.
#' @param w_o numeric; Contribution of the orthology subscore to the overall score 
#' (between 0 and 1), default value (as used in the paper) is 0.1.
#' @param w_t numeric; Contribution of the technique subscore to the overall score 
#' (between 0 and 1), default value (as used in the paper) is 0.3.
#' @param output.file character; Path and name of the output files, which will
#' contain the re-scored version of MIPPIE.
#' 
#' @return A tibble with the same columns as the input file but re-computed
#' confidence scores. In addition, it writes this tibble to the file indicated
#' by parameter output.file.
#' 
#' @author Gregorio Alanis-Lobato \email{galanisl@uni-mainz.de}
#' 
#' @examples
#' 
#' mippie_rs <- rescore_mippie(path.to.mippie = "mippie_ppi_v1_0.tsv", 
#'                             path.to.exp.scores = "experimental_scores.tsv", 
#'                             a_s = 1, a_o = 2, a_t = 0.3,
#'                             w_s = 0.5, w_o = 0.2, w_t = 0.3,
#'                             output.file = "mippie_rescored.tsv")
#' 
rescore_mippie <- function(path.to.mippie = "mippie_ppi_v1_0.tsv",
                           path.to.exp.scores = "experimental_scores.tsv",
                           a_s = 1, a_o = 1.5, a_t = 0.5,
                           w_s = 0.6, w_o = 0.1, w_t = 0.3,
                           output.file = "mippie_ppi_v1_0_rescored.tsv"){
  
  if(w_s + w_o + w_t != 1){
    stop("The sum of the subscore contributions w_s, w_o and w_t must equal 1.")
  }
  
  mippie <- read_tsv(path.to.mippie)
  exp_scr <- read_tsv(path.to.exp.scores)
  
  det_method_scr <- vector("numeric", length = nrow(mippie))
  
  for(i in 1:nrow(exp_scr)){
    idx <- grep(exp_scr$PSI[i], mippie$exp_techniques)
    det_method_scr[idx] <- det_method_scr[idx] + exp_scr$score[i]
  }
  
  mippie <- mippie %>% 
    mutate(exp_scores = det_method_scr)
  
  mippie$MIPPIE_score <- w_s * get_subscore(a_s, mippie$num_studies) +
    w_o * get_subscore(a_o, mippie$num_organisms) +
    w_t * get_subscore(a_t, mippie$exp_scores)
  
  write_tsv(mippie, output.file)
  
  return(mippie)
}

#' Computes the subscores of the overall MIPPIE confidence score
#' 
#' MIPPIE's confidence score is a weighted sum of three saturating functions 
#' that depend on a parameter 'a' that controls its steepness and an 
#' independent variable 'n'.
#' 
#' @param a numeric; Controls how fast the subscore saturates (between 0 and Inf)
#' @param n numeric; Either the number of studies supporting the interactions,
#' the number of other organisms in which they occurs or the sum of reliability
#' scores assigned to the experimental technique used to measure them.
#' 
#' @return A vector, the same size of n, with the subscores for the given 
#' interactions.
#' 
#' @author Gregorio Alanis-Lobato \email{galanisl@uni-mainz.de}
#' 
#' @examples
#' 
#' # Compute the subscores for the number of studies supporting all the 
#' # interactions in MIPPIE
#' mippie <- readr:read_tsv("mippie_v1_0.tsv")
#' Ss <- w_s * get_subscore(a_s, mippie$num_studies)
#' 
get_subscore <- function(a, n){
  return(2/(1 + exp(-a * n)) - 1)
}