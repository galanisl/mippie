The MIPPIE rescoring tool (rescore_mippie) takes as an input a flat file version 
of the MIPPIE database and a list of scores assigned to experimental techniques. 
rescore_mippie is available at 
   http://cbdm-01.zdv.uni-mainz.de/~galanisl/mippie/RS/rescore_mippie.R

Requirements and installation
=============================

The script is written in R and requires:
- R >= v3.5.1
- readr >= 1.1.1 
- dplyr >= 0.7.6

No further installation is necessary, the tool can be run right away from the 
R console. It reads the MIPPIE interaction network from a flat file and the 
scores assigned to the experimental techniques used to measure these 
interactions. The up-to-date versions of these files can be found at

http://cbdm-01.zdv.uni-mainz.de/~galanisl/mippie/downloads/mippie_ppi_v1_0.tsv
http://cbdm-01.zdv.uni-mainz.de/~galanisl/mippie/RS/experimental_scores.tsv

By default rescore_mippie uses a flat file called mippie_ppi_v1_0.tsv that is 
expected to reside in the same directory as the script itself.


Quick Start
===========

In the following, the dollar sign ($) corresponds to the terminal's prompt and
the greater than symbol (>) corresponds to R's prompt.

From the terminal, change to the directory containing rescore_mippie.R. For 
example, if it is in folder Downloads do:

$ cd /home/user_name/Downloads

Start R:

$ R

Once inside an R session, source rescore_mippie.R to make its main function
available:

> source("rescore_mippie.R")

When MIPPIE and the list of experimental scores are in the working directory, 
the tool can be run without passing any further parameters:

> mippie_rs <- rescore_mippie()

The above both generates a file called mippie_ppi_v1_0_rescored.tsv in the 
working directory and returns a data frame for further post-processing in R. The
name of the output file can be changed as follows:

> mippie_rs <- rescore_mippie(output.file = "mippie_rescored.tsv")

If MIPPIE or the list of experimental scores are in a different directory, their
path must be specified:

> mippie_rs <- rescore_mippie(path.to.mippie = "/home/user_name/Docs/mippie_ppi_v1_0.tsv", 
                              path.to.exp.scores = "/home/user_name/Docs/experimental_scores.tsv")

A rescoring run putting a higher emphasis on the orthology subscore but leaving 
the saturation parameters as they are (for details on the scoring formula please 
see the paper describing MIPPIE) looks like: 

> mippie_rs <- rescore_mippie(w_s = 0.5, w_o = 0.3, w_t = 0.2)

Parameters for the rescore_mippie function:
=======
path.to.mippie character; The path to the file containing the MIPPIE 
path.to.exp.scores character; The path to the file reporting the scores
	assigned to the experimental techniques used to measure MIPPIE's interactions.
a_s numeric; Controls how fast the study subscore saturates (between 0 
	and Inf), default value (as used in the paper) is 1.
a_o numeric; Controls how fast the orthology subscore saturates (between 
	0 and Inf), default value (as used in the paper) is 1.5.
a_t numeric; Controls how fast the technique subscore saturates (between 
	0 and Inf), default value (as used in the paper) is 0.5.
w_s numeric; Contribution of the study subscore to the overall score 
	(between 0 and 1), default value (as used in the paper) is 0.6.
w_o numeric; Contribution of the orthology subscore to the overall score 
	(between 0 and 1), default value (as used in the paper) is 0.1.
w_t numeric; Contribution of the technique subscore to the overall score 
	(between 0 and 1), default value (as used in the paper) is 0.3.
output.file character; Path and name of the output files, which will
	contain the re-scored version of MIPPIE.


For any questions, comments or suggestions, please send an email to 
	galanisl@uni-mainz.de
