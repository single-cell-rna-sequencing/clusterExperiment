#'Find sets of samples that stay together across clusterings
#'
#'Find sets of samples that stay together across clusterings in order to define 
#'a new clustering vector.
#'
#'@aliases makeConsensus
#'  
#'@param x a matrix or \code{\link{ClusterExperiment}} object.
#' @inheritParams ClusterExperiment-methods
#'@param clusterFunction the clustering to use (passed to 
#'  \code{\link{mainClustering}}); currently must be of type '01'.
#'@param minSize minimum size required for a set of samples to be considered in 
#'  a cluster because of shared clustering, passed to
#'  \code{\link{mainClustering}}
#'@param proportion The proportion of times that two sets of samples should be 
#'  together in order to be grouped into a cluster (if <1, passed to
#'  mainClustering via alpha = 1 - proportion)
#'@param propUnassigned samples with greater than this proportion of assignments
#'  equal to '-1' are assigned a '-1' cluster value as a last step (only if
#'  proportion < 1)
#'@param ... arguments to be passed on to the method for signature 
#'  \code{matrix,missing}.
#'@inheritParams clusterMany
#'@details This function was previously called \code{combineMany} (versions <= 2.0.0).
#' \code{combineMany} is still available, but is considered defunct and users should 
#' update their code accordingly. 
#'@details The function tries to find a consensus cluster across many different 
#'  clusterings of the same samples. It does so by creating a \code{nSamples} x 
#'  \code{nSamples} matrix of the percentage of co-occurance of each sample and 
#'  then calling mainClustering to cluster the co-occurance matrix. The function
#'  assumes that '-1' labels indicate clusters that are not assigned to a 
#'  cluster. Co-occurance with the unassigned cluster is treated differently 
#'  than other clusters. The percent co-occurance is taken only with respect to 
#'  those clusterings where both samples were assigned. Then samples with more 
#'  than \code{propUnassigned} values that are '-1' across all of the 
#'  clusterings are assigned a '-1' regardless of their cluster assignment.
#'@details The method calls \code{\link{mainClustering}} on the proportion
#'  matrix with \code{clusterFunction} as the 01 clustering algorithm,
#'  \code{alpha=1-proportion}, \code{minSize=minSize}, and
#'  \code{evalClusterMethod=c("average")}. See help of 
#'  \code{\link{mainClustering}} for more details.
#'@return If x is a matrix, a list with values \itemize{ 
#'  \item{\code{clustering}}{ vector of cluster assignments, with "-1" implying 
#'  unassigned}
#'  
#'  \item{\code{percentageShared}}{ a nSample x nSample matrix of the percent 
#'  co-occurance across clusters used to find the final clusters. Percentage is 
#'  out of those not '-1'} \item{\code{noUnassignedCorrection}{ a vector of 
#'  cluster assignments before samples were converted to '-1' because had 
#'  >\code{propUnassigned} '-1' values (i.e. the direct output of the 
#'  \code{mainClustering} output.)}} }
#'  
#' @return If x is a \code{\link{ClusterExperiment}}, a
#'  \code{\link{ClusterExperiment}} object, with an added clustering of
#'  clusterTypes equal to \code{makeConsensus} and the \code{percentageShared}
#'  matrix stored in the \code{coClustering} slot.
#'
#' @examples
#' data(simData)
#'
#' cl <- clusterMany(simData,nReducedDims=c(5,10,50),  reduceMethod="PCA",
#' clusterFunction="pam", ks=2:4, findBestK=c(FALSE), removeSil=TRUE,
#' subsample=FALSE)
#'
#' #make names shorter for plotting
#' clMat <- clusterMatrix(cl)
#' colnames(clMat) <- gsub("TRUE", "T", colnames(clMat))
#' colnames(clMat) <- gsub("FALSE", "F", colnames(clMat))
#' colnames(clMat) <- gsub("k=NA,", "", colnames(clMat))
#'
#' #require 100% agreement -- very strict
#' clCommon100 <- makeConsensus(clMat, proportion=1, minSize=10)
#'
#' #require 70% agreement based on clustering of overlap
#' clCommon70 <- makeConsensus(clMat, proportion=0.7, minSize=10)
#'
#' oldpar <- par()
#' par(mar=c(1.1, 12.1, 1.1, 1.1))
#' plotClusters(cbind("70%Similarity"=clCommon70$clustering, clMat,
#' "100%Similarity"=clCommon100$clustering), axisLine=-2)
#'
#' #method for ClusterExperiment object
#' clCommon <- makeConsensus(cl, whichClusters="workflow", proportion=0.7,
#' minSize=10)
#' plotClusters(clCommon)
#' par(oldpar)
#'
#' @rdname makeConsensus
#' @export
setMethod(
  f = "makeConsensus",
  signature = signature(x = "matrix", whichClusters = "missing"),
  definition = function(x, whichClusters, proportion,
                        clusterFunction="hierarchical01",
                        propUnassigned=.5, minSize=5,...) {
    
    if(proportion >1 || proportion <0) stop("Invalid value for the 'proportion' parameter")
    if(propUnassigned >1 || propUnassigned <0) stop("Invalid value for the 'propUnassigned' parameter")
    clusterMat <- x
    if(proportion == 1) {
      #have to repeat from mainClustering because didn't
      if(!is.numeric(minSize) || minSize<0) 
        stop("Invalid value for the 'minSize' parameter in determining the minimum number of samples required in a cluster.")
      else minSize<-round(minSize) #incase not integer.
      singleValueClusters <- apply(clusterMat, 1, paste, collapse=";")
      allUnass <- paste(rep("-1", length=ncol(clusterMat)), collapse=";")
      uniqueSingleValueClusters <- unique(singleValueClusters)
      tab <-	table(singleValueClusters)
      tab <- tab[tab >= minSize]
      tab <- tab[names(tab) != allUnass]
      cl <- match(singleValueClusters, names(tab))
      cl[is.na(cl)] <- -1
      sharedPerct<-NULL
    } else{
      
      if(is.character(clusterFunction)) typeAlg <- algorithmType(clusterFunction)
      else if(class(clusterFunction)=="ClusterFunction") typeAlg<-algorithmType(clusterFunction) else stop("clusterFunction must be either built in clusterFunction name or a ClusterFunction object")
      if(typeAlg!="01") {
        stop("makeConsensus is only implemented for '01' type clustering functions (see ?ClusterFunction)")
      }
      
      ##Make clusterMat integer, just in case
      clusterMat <- apply(clusterMat, 2, as.integer)
      clusterMat[clusterMat %in%  c(-1,-2)] <- NA
      sharedPerct <- search_pairs(t(clusterMat)) #works on columns. gives a nsample x nsample matrix back. only lower tri populated
      
      #fix those pairs that have no clusterings for which they are both not '-1'
      sharedPerct <- sharedPerct + t(sharedPerct)
      sharedPerct[is.na(sharedPerct)] <- 0
      sharedPerct[is.nan(sharedPerct)] <- 0
      diag(sharedPerct) <- 1
      
      clustArgs<-list(alpha=1-proportion)
      clustArgs<-c(clustArgs,list(...))
      if(!"evalClusterMethod" %in% names(clustArgs) && clusterFunction=="hierarchical01"){
        clustArgs<-c(clustArgs,list(evalClusterMethod=c("average")))
      }
      cl <- mainClustering(diss=1-sharedPerct, clusterFunction=clusterFunction,
                           minSize=minSize, format="vector",
                           clusterArgs=clustArgs)
      
      if(is.character(cl)) {
        stop("coding error -- mainClustering should return numeric vector")
      }
    }
    ##Now define as unassigned any samples with >= propUnassigned '-1' values in clusterMat
    whUnassigned <- which(apply(clusterMat, 2, function(x){
      sum(x== -1)/length(x)>propUnassigned}))
    clUnassigned <- cl
    clUnassigned[whUnassigned] <- -1
    
    return(list(clustering=clUnassigned, percentageShared=sharedPerct,
                noUnassignedCorrection=cl))
  }
)

#' @rdname makeConsensus
#' @export
#' @param clusterLabel a string used to describe the type of clustering. By
#'   default it is equal to "makeConsensus", to indicate that this clustering is
#'   the result of a call to makeConsensus. However, a more informative label can
#'   be set (see vignette).
setMethod(
  f = "makeConsensus",
  signature = signature(x = "ClusterExperiment", whichClusters = "numeric"),
  definition = function(x, whichClusters, eraseOld=FALSE,clusterLabel="makeConsensus",...){
    
    if(!all(whichClusters %in% seq_len(NCOL(clusterMatrix(x))))) {
      stop("Invalid indices for clusterLabels")
    }
    if(length(whichClusters)==0) stop("No clusters chosen (whichClusters has length 0)")
    clusterMat <- clusterMatrix(x)[, whichClusters, drop=FALSE]
    
    outlist <- makeConsensus(clusterMat, ...)
    newObj <- ClusterExperiment(x, outlist$clustering,
                                transformation=transformation(x),
                                clusterTypes="makeConsensus",checkTransformAndAssay=FALSE)
    #add "c" to name of cluster
    newObj<-.addPrefixToClusterNames(newObj,prefix="c",whCluster=1)
    clusterLabels(newObj) <- clusterLabel
    
    if(!is.null(outlist$percentageShared)) {
      coClustering(newObj) <- outlist$percentageShared
    }
    ##Check if pipeline already ran previously and if so increase
		x<-.updateCurrentWorkflow(x,eraseOld,newTypeToAdd="makeConsensus",newLabelToAdd=clusterLabel)
		
    if(!is.null(x)) retval<-.addNewResult(newObj=newObj,oldObj=x) #make decisions about what to keep.
    else retval<-.addBackSEInfo(newObj=newObj,oldObj=x)
    return(retval)
  }
)

#' @rdname makeConsensus
#' @export
setMethod(
  f = "makeConsensus",
  signature = signature(x = "ClusterExperiment", whichClusters = "character"),
  definition = function(x, whichClusters, ...){
    
    wh <- .TypeIntoIndices(x, whClusters=whichClusters)
    makeConsensus(x, wh, ...)
  }
)
#' @rdname makeConsensus
#' @export
setMethod(
  f = "makeConsensus",
  signature = signature(x = "ClusterExperiment", whichClusters = "missing"),
  definition = function(x, whichClusters, ...){
    wh<-.TypeIntoIndices(x,"clusterMany")
    if(length(wh)>0){
      .mynote("no clusters specified to combine, using results from clusterMany")
      makeConsensus(x, whichClusters = "clusterMany",...)
    }
    else{
      stop("no clusters specified to combine, please specify.")
    }
  }
)


