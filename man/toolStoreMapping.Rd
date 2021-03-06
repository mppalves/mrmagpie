% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/toolStoreMapping.R
\name{toolStoreMapping}
\alias{toolStoreMapping}
\title{Tool: StoreMapping}
\usage{
toolStoreMapping(map, name, type = NULL, error.existing = TRUE)
}
\arguments{
\item{map}{mapping data to be stored.}

\item{name}{File name of the mapping file. Supported file types are currently csv (, or ; separated)
and rda (which needs to have the data stored with the object name "data"!). Use code{\link{toolConvertMapping}}
to convert between both formats}

\item{type}{Mapping type (e.g. "regional", "cell", or "sectoral"). Can be set to NULL if file
is not stored in a type specific subfolder}

\item{error.existing}{Boolean which decides whether an error is returned if
the mapping file does not exist or not.}
}
\description{
Function which creates a mapping file
}
\seealso{
\code{\link{calcOutput}}, \code{\link{toolConvertMapping}}
}
\author{
Jan Philipp Dietrich
}
