% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calcClusterBase.R
\name{calcClusterBase}
\alias{calcClusterBase}
\title{calcClusterBase}
\usage{
calcClusterBase(years2use = 1995)
}
\arguments{
\item{years2use}{A vector with years with should be taken into account for
the clustering}
}
\value{
A matrix containing the data
}
\description{
Reads a series of MAgPIE files and combines them to a matrix
which is then used for calculating a clustering.
}
\seealso{
\code{\link{calcCluster}}
}
\author{
Jan Philipp Dietrich
}
