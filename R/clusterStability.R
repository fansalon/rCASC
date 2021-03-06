#' @title Permutations and Clustering
#' @description This function executes a ubuntu docker that produces a specific number of permutation to evaluate clustering.
#' @param group, a character string. Two options: sudo or docker, depending to which group the user belongs
#' @param scratch.folder, a character string indicating the path of the scratch folder
#' @param file, a character string indicating the path of the file, with file name and extension included
#' @param nPerm, number of permutations to perform the pValue to evaluate clustering
#' @param range1, first number of cluster for k means algorithm
#' @param range2, last number of cluster for k means algorithm
#' @param separator, separator used in count file, e.g. '\\t', ','
#' @param logTen, 1 if the count matrix is already in log10, 0 otherwise
#' @param clustering, clustering method to use : "SIMLR" , "tSne", "griph"
#' @param pcaDimensions, dimensions to use for pca reduction for Seurat
#' @param perplexity, Number of close neighbors for each point. This parameter is specific for tSne. Default value is 10.Setting this parameter when use a clustering method different by tSne will be ignored.
#' @param seed, important value to reproduce the same results with same input
#' @author Luca Alessandri, alessandri [dot] luca1991 [at] gmail [dot] com, University of Torino
#'
#' @return plot with cluster stability
#' @examples
#' \dontrun{
#clusterStability("sudo","/media/lucastormreig/8799-82B31/PHD/CASC8.1Stable/CASC8.0STABLE/new/clusterStability/",file="/media/lucastormreig/8799-82B31/PHD/CASC8.1Stable/CASC8.0STABLE/new/clusterStability/annotated_10000_Buettner.csv",nPerm=3,range1=3,range2=3,separator=",",logTen=0,clustering="SIMLR",pcaDimensions=3)

#'}
#' @export
clusterStability <- function(group=c("sudo","docker"), scratch.folder, file, nPerm, range1=3, range2=3, separator, logTen=0, clustering, perplexity=10 ,pcaDimensions, seed=1111){

  data.folder=dirname(file)
positions=length(strsplit(basename(file),"\\.")[[1]])
matrixNameC=strsplit(basename(file),"\\.")[[1]]
matrixName=paste(matrixNameC[seq(1,positions-1)],collapse="")
format=strsplit(basename(basename(file)),"\\.")[[1]][positions]


  #running time 1
  ptm <- proc.time()
  #setting the data.folder as working folder
  if (!file.exists(data.folder)){
    cat(paste("\nIt seems that the ",data.folder, " folder does not exist\n"))
    return(2)
  }

  #storing the position of the home folder
  home <- getwd()
  setwd(data.folder)
  #initialize status
  system("echo 0 > ExitStatusFile 2>&1")

  #testing if docker is running
  test <- dockerTest()
  if(!test){
    cat("\nERROR: Docker seems not to be installed in your system\n")
    system("echo 10 > ExitStatusFile 2>&1")
    setwd(home)
    return(10)
  }



  #check  if scratch folder exist
  if (!file.exists(scratch.folder)){
    cat(paste("\nIt seems that the ",scratch.folder, " folder does not exist\n"))
    system("echo 3 > ExitStatusFile 2>&1")
    setwd(data.folder)
    return(3)
  }
  tmp.folder <- gsub(":","-",gsub(" ","-",date()))
  scrat_tmp.folder=file.path(scratch.folder, tmp.folder)
  writeLines(scrat_tmp.folder,paste(data.folder,"/tempFolderID", sep=""))
  cat("\ncreating a folder in scratch folder\n")
  dir.create(file.path(scrat_tmp.folder))
  #preprocess matrix and copying files

if(separator=="\t"){
separator="tab"
}

system(paste("cp ",data.folder,"/",matrixName,".",format," ",scrat_tmp.folder,"/",sep=""))


  #executing the docker job
    params <- paste("--cidfile ",data.folder,"/dockerID -v ",scrat_tmp.folder,":/scratch -v ", data.folder, ":/data -d docker.io/repbioinfo/clusterstability Rscript /home/main.R ",matrixName," ",nPerm," " ,range1," ",range2," ",format," ",separator," ",logTen," ",clustering," ",perplexity," ",pcaDimensions," ", seed, sep="")

resultRun <- runDocker(group=group, params=params)

  #waiting for the end of the container work
  if(resultRun==0){
    #system(paste("cp ", scrat_tmp.folder, "/* ", data.folder, sep=""))
  }
  #running time 2
  ptm <- proc.time() - ptm
  dir <- dir(data.folder)
  dir <- dir[grep("run.info",dir)]
  if(length(dir)>0){
    con <- file("run.info", "r")
    tmp.run <- readLines(con)
    close(con)
    tmp.run[length(tmp.run)+1] <- paste("user run time mins ",ptm[1]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("system run time mins ",ptm[2]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("elapsed run time mins ",ptm[3]/60, sep="")
    writeLines(tmp.run,"run.info")
  }else{
    tmp.run <- NULL
    tmp.run[1] <- paste("run time mins ",ptm[1]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("system run time mins ",ptm[2]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("elapsed run time mins ",ptm[3]/60, sep="")

    writeLines(tmp.run,"run.info")
  }

  #saving log and removing docker container
  container.id <- readLines(paste(data.folder,"/dockerID", sep=""), warn = FALSE)
  system(paste("docker logs ", substr(container.id,1,12), " &> ",data.folder,"/", substr(container.id,1,12),".log", sep=""))
  system(paste("docker rm ", container.id, sep=""))


  #Copy result folder
  cat("Copying Result Folder")
  system(paste("cp -r ",scrat_tmp.folder,"/* ",data.folder,sep=""))
  #removing temporary folder
  cat("\n\nRemoving the temporary file ....\n")
  system(paste("rm -R ",scrat_tmp.folder))
  system("rm -fR out.info")
  system("rm -fR dockerID")
  system("rm  -fR tempFolderID")
  system(paste("cp ",paste(path.package(package="rCASC"),"containers/containers.txt",sep="/")," ",data.folder, sep=""))
  setwd(home)
} 
