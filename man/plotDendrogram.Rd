% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotDendrogram.R
\docType{methods}
\name{plotDendrogram,ClusterExperiment-method}
\alias{plotDendrogram,ClusterExperiment-method}
\alias{plotDendrogram}
\title{Plot dendrogram of ClusterExperiment object}
\usage{
\S4method{plotDendrogram}{ClusterExperiment}(x, whichClusters = "dendro",
  leafType = c("samples", "clusters"), plotType = c("colorblock", "name",
  "ids"), mergeInfo = "none", main, sub, clusterLabelAngle = 45,
  removeOutbranch = TRUE, legend = c("side", "below", "none"),
  nodeColors = NULL, colData = NULL, clusterLegend = NULL, ...)
}
\arguments{
\item{x}{a \code{\link{ClusterExperiment}} object.}

\item{whichClusters}{only used if \code{leafType="samples"}). If numeric, an 
index for the clusterings to be plotted with dendrogram. Otherwise, 
\code{whichClusters} can be a character value identifying the 
\code{clusterTypes} to be used, or if not matching \code{clusterTypes} then 
\code{clusterLabels}; alternatively \code{whichClusters} can be either 'all'
or 'workflow' or 'primaryCluster' to indicate choosing all clusters or 
choosing all \code{\link{workflowClusters}}. Default 'dendro' indicates 
using the clustering that created the dendrogram.}

\item{leafType}{if "samples" the dendrogram has one leaf per sample, otherwise
it has one per cluster.}

\item{plotType}{one of 'name', 'colorblock' or 'id'. If 'Name' then dendrogram
will be plotted, and name of cluster or sample (depending on type of value 
for \code{leafType}) will be plotted next to the leaf of the dendrogram. If 
'colorblock', rectangular blocks, corresponding to the color of the cluster 
will be plotted, along with cluster name legend. If 'id' the internal 
clusterIds value will be plotted (only appropriate if 
\code{leafType="clusters"}).}

\item{mergeInfo}{What kind of information about merge to plot on dendrogram. 
If not equal to "none", will replicate the kind of plot that 
\code{\link{mergeClusters}} creates, and the input to \code{mergeInfo} 
corresponds to that of \code{plotInfo} in \code{mergeClusters}.}

\item{main}{passed to the \code{plot.phylo} function to set main title.}

\item{sub}{passed to the \code{plot.phylo} function to set subtitle.}

\item{clusterLabelAngle}{angle at which label of cluster will be drawn. Only 
applicable if \code{plotType="colorblock"}.}

\item{removeOutbranch}{logical, only applicable if there are missing samples 
(i.e. equal to -1 or -2), \code{leafType="samples"} and the dendrogram for 
the samples was made by putting missing samples in an outbranch. In which 
case, if this parameter is TRUE, the outbranch will not be plotted, and if 
FALSE it will be plotted.}

\item{legend}{character, only applicable if \code{plotType="colorblock"}. 
Passed to \code{\link{phydataplot}} in \code{\link{ape}} package that is 
used to draw the color values of the clusters/samples next to the 
dendrogram. Options are 'none', 'below', or 'side'. (Note 'none' is only 
available for 'ape' package >= 4.1-0.6).}

\item{nodeColors}{named vector of colors to be plotted on a node in the 
dendrogram. Names should match the name of the node (calls 
\code{\link[ape]{nodelabels}}).}

\item{colData}{index (by integer or name) the sample data stored as a 
\code{DataFrame} in \code{colData} slot of the object. Only discrete valued
("character" or "factor" variables) will be plotted; indexing of continous 
variables will be ignored. Whether that data is continuous or not will be 
determined by the properties of \code{colData} (no user input is needed).
This argument is only relevant if \code{plotType=="colorblock"} and
\code{leafType=="samples"}}

\item{clusterLegend}{Assignment of colors to the clusters or sample data (as
designated by \code{colData} argument) plotted with the dendrogram . If
\code{NULL} or a particular variable/cluster are not assigned a color, 
colors will be assigned internally for sample data and pull from the
\code{clusterLegend} slot of the x for the clusters.}

\item{...}{arguments passed to the \code{\link{plot.phylo}} function of 
\code{ape} that plots the dendrogram.}
}
\value{
A dendrogram is plotted. Returns (invisibly) a list with elements
\itemize{
\item{\code{plottedObject}}{ the \code{phylo} object that is plotted.}
\item{\code{originalObject}}{ the \code{phylo} object before adjusting the
node/tip labels. }
}
}
\description{
Plots the dendrogram saved in a ClusterExperiment object
}
\details{
If \code{leafType="clusters"}, the plotting function will work best
  if the clusters in the dendrogram correspond to the primary cluster. This
  is because the function colors the cluster labels based on the colors of
  the clusterIds of the primaryCluster
}
\examples{
data(simData)

#create a clustering, for 8 clusters (truth was 3) 
cl <-clusterSingle(simData, subsample=FALSE, 
sequential=FALSE, mainClusterArgs=list(clusterFunction="pam", clusterArgs=list(k=8)))

#create dendrogram of clusters and then 
# merge clusters based ondendrogram: 
cl <- makeDendrogram(cl) 
cl <- mergeClusters(cl,mergeMethod="adjP",DEMethod="limma",cutoff=0.1,plot=FALSE) 
plotDendrogram(cl) 
plotDendrogram(cl,leafType="samples",whichClusters="all",plotType="colorblock")

}
\seealso{
\code{\link{mergeClusters}},\code{\link[ape]{plot.phylo}},
  \code{\link[ape]{nodelabels}},\code{\link[ape]{tiplabels}}
}
