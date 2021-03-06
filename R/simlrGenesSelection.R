#' @title Genes selection from genesPrioritization output
#' @description This function executes a ubuntu docker that extracts the genes playin major role in clusterin from output of genesPrioritization
#' @param group, a character string. Two options: sudo or docker, depending to which group the user belongs
#' @param scratch.folder, a character string indicating the path of the scratch folder
#' @param file, a character string indicating the path of the file, with file name and extension included
#' @param nCluster, the number of clusters, where to run prioritization
#' @param separator, separator used in count file, e.g. '\\t', ','
#' @param seed, important value to reproduce the same results with same input
#' @param sp, minimun number of percentage of cells that has to be in common in a cluster, between two permutations, default 0.8
#' @param clusterPermErr, probability error in depicting the number of clusters in each permutation, default = 0.05
#' @param maxDeltaConfidence, max value for Delta confidence for gene prioritization p-values.
#' @param minLogMean, min value for Log mean gene prioritization p-value. P-value indicates the importance of a gene in defining clusterization.
#' @author Luca Alessandri, alessandri [dot] luca1991 [at] gmail [dot] com, University of Torino
#' @return ....
#' 
#' @examples
#' \dontrun{
#' system("wget http://130.192.119.59/public/section4.1_examples.zip")
#' unzip("section4.1_examples.zip")
#' setwd("section4.1_examples")
#' genesSelection(group="docker",scratch.folder="/data/scratch/",file=paste(getwd(), "bmsnkn_5x100cells.txt", sep="/"), nCluster=5, separator="\t",  seed=111, sp=0.8, clusterPermErr=0.05, maxDeltaConfidence=0.01, minLogMean=0.05)
#'}
#'
#' @export

genesSelection <- function(group=c("sudo","docker"), scratch.folder, file, nCluster, separator, seed=111, sp=0.8, clusterPermErr=0.05, maxDeltaConfidence=0.01, minLogMean=0.05){
  
  permAnalysis(group=group, scratch.folder=scratch.folder,file=file, range1=nCluster, range2=nCluster, separator=separator, sp=sp, clusterPermErr=clusterPermErr, maxDeltaConfidence=maxDeltaConfidence, minLogMean=minLogMean)
  
  data.folder=dirname(file)
  positions=length(strsplit(basename(file),"\\.")[[1]])
  matrixNameC=strsplit(basename(file),"\\.")[[1]]
  matrixName=paste(matrixNameC[seq(1,positions-1)],collapse="")
  format=strsplit(basename(basename(file)),"\\.")[[1]][positions]
  
  dir <- dir(paste(getwd(), "Results", matrixName, nCluster,sep="/"))
  dir.specific <- dir[grep("_geneRankList.txt", dir)]
  df.specific <- read.table(paste(getwd(), "Results", matrixName, nCluster, dir.specific,sep="/"), sep="\t", header=F)
  df.specific.symbol <- strsplit(as.character(df.specific[,1]), ":")
  df.specific.symbol <- sapply( df.specific.symbol, function(x)x[2])
  zz <- file(paste(getwd(), "Results", matrixName, nCluster, paste(matrixName, "clusters_specific_geneSYMBOLs.txt", sep="_"),sep="/"), "w")
  writeLines(df.specific.symbol, zz)
  close(zz)
  
}
