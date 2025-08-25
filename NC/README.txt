The MIPPIE network construction tool (mippie_nc) takes as an input a flat file 
version of the MIPPIE database (interactions and proteins) and a list of 
proteins or interactions around which a MIPPIE subnetwork is constructed. 
mippie_nc is available at 
http://cbdm-01.zdv.uni-mainz.de/~galanisl/mippie/RS/mippie_nc.R

Requirements and installation
=============================

The script is written in R and requires:
- R >= v3.5.1
- readr >= 1.1.1 
- dplyr >= 0.7.6

No further installation is necessary, the tool can be run right away from the 
R console. It reads the MIPPIE interaction network from a flat file, as well as 
the node meta-data and a list of proteins or interactions around which a MIPPIE 
subnetwork is constructed. 

The up-to-date versions of the PPI and node files can be found at

http://cbdm-01.zdv.uni-mainz.de/~galanisl/mippie/downloads/mippie_ppi_v1_0.tsv
http://cbdm-01.zdv.uni-mainz.de/~galanisl/mippie/downloads/mippie_proteins_v1_0.tsv

By default mippie_nc uses the flat files called mippie_ppi_v1_0.tsv and 
mippie_proteins_v1_0.tsv that are expected to reside in the same directory as 
the script itself.


Quick Start
===========

In the following, the dollar sign ($) corresponds to the terminal's prompt and
the greater than symbol (>) corresponds to R's prompt.

From the terminal, change to the directory containing mippie_nc.R. For 
example, if it is in folder Downloads do:

$ cd /home/user_name/Downloads

Start R:

$ R

Once inside an R session, source mippie_nc.R to make its main function
available:

> source("mippie_nc.R")

When the PPI and protein meta-data files are in the working directory, the tool 
can be run with a single parameter, i.e. the flat file containing the list of 
proteins or protein interactions around which a MIPPIE subnetwork is constructed. 

> mippie_subnet <- mippie_nc(query.file = "query.txt")

The above both generates a file called mippie_subnet.tsv in the 
working directory and returns an igraph object for further post-processing in R. 
The name of the output file can be changed as follows:

> mippie_subnet <- mippie_nc(query.file = "query.txt", output.file = "my_query.tsv")

If PPI or protein meta-data files are in a different directory, their
path must be specified:

> mippie_subnet <- mippie_nc(query.file = "query.txt", 
		path.to.mippie = "/home/user_name/Docs/mippie_ppi_v1_0.tsv", 
      path.to.proteins = "/home/user_name/Docs/mippie_proteins_v1_0.tsv")

By default, mippie_nc finds the level-1 neighbors of the proteins in the query
file. However, it is possible to explore level-2 or more neighbors with parameter
order:

> mippie_subnet <- mippie_nc(query.file = "query.txt", order = 2)

Parameters for the mippie_nc function:
=======
query.file character; The path to the file containing the proteins or PPIs of 
	interest.
path.to.mippie character; The path to the file containing the MIPPIE. 
path.to.proteins character; The path to the file containing protein meta-data.
order integer; The order of the neighborhood, default value is 1.
output.file character; Path and name of the output files, which will
	contain the constructed subnetwork around the input proteins.

For any questions, comments or suggestions, please send an email to 
	galanisl@uni-mainz.de
