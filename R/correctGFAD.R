#' @title correctGFAD
#' @description Correct Global Forest Age Dataset
#' @return List of magpie objects with results on cellular level, weight, unit and description.
#' @param x magpie object provided by the read function
#' @author Abhijeet Mishra, Felicitas Beier
#' @seealso
#'   \code{\link{readGFAD}}
#' @examples
#'
#' \dontrun{
#'   readSource("GFAD", convert="onlycorrect")
#' }
#'
#' @importFrom madrat toolConditionalReplace
#' @importFrom mstools toolCoord2Isocoord

correctGFAD <- function(x) {

  x <- toolConditionalReplace(x,
                              conditions = c("is.na()", "<0"),
                              replaceby = 0)
  x <- toolCoord2Isocoord(x)

  return(x)
}
