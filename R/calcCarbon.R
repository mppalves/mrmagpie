#' @title calcCarbon
#' @description This function extracts carbon densities from LPJ to MAgPIE
#'
#' @param version Switch between LPJmL4 and LPJmL4
#' @param climatetype Switch between different climate scenarios (default: "CRU_4")
#' @param time average, spline or raw (default)
#' @param averaging_range just specify for time=="average": number of time steps to average
#' @param dof             just specify for time=="spline": degrees of freedom
#' @param harmonize_baseline FALSE (default) nothing happens, if a baseline is specified here data is harmonized to that baseline (from ref_year on)
#' @param ref_year just specify for harmonize_baseline != FALSE : Reference year
#'
#' @return magpie object in cellular resolution
#' @author Kristine Karstens
#'
#' @examples
#' \dontrun{ calcOutput("Carbon", aggregate = FALSE) }
#'
#' @importFrom magpiesets findset
#' @importFrom magclass add_dimension

calcCarbon <- function(version="LPJmL4", climatetype="CRU_4", time="raw", averaging_range=NULL, dof=NULL,
                       harmonize_baseline=FALSE, ref_year="y2015"){

  lpjml_years  <- findset("time")[as.numeric(substring(findset("time"),2))<2099]

  soilc_natveg <-  calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="soilc",
                              averaging_range=averaging_range, time=time, dof=dof,
                              harmonize_baseline=harmonize_baseline, ref_year=ref_year,
                              aggregate=FALSE, years=lpjml_years)

  vegc_natveg  <-  calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="vegc",
                              averaging_range=averaging_range, time=time, dof=dof,
                              harmonize_baseline=harmonize_baseline, ref_year=ref_year,
                              aggregate=FALSE, years=lpjml_years)

  litc_natveg  <-  calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="litc",
                              averaging_range=averaging_range, time=time, dof=dof,
                              harmonize_baseline=harmonize_baseline, ref_year=ref_year,
                              aggregate=FALSE, years=lpjml_years)

  natveg       <- mbind(litc_natveg, vegc_natveg, soilc_natveg)

  soilc_grass  <-  calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="soilc_grass",
                              averaging_range=averaging_range, time=time, dof=dof,
                              harmonize_baseline=harmonize_baseline, ref_year=ref_year,
                              aggregate=FALSE, years=lpjml_years)

  vegc_grass   <-  calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="vegc_grass",
                              averaging_range=averaging_range, time=time, dof=dof,
                              harmonize_baseline=harmonize_baseline, ref_year=ref_year,
                              aggregate=FALSE, years=lpjml_years)

  litc_grass   <-  calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="litc_grass",
                              averaging_range=averaging_range, time=time, dof=dof,
                              harmonize_baseline=harmonize_baseline, ref_year=ref_year,
                              aggregate=FALSE, years=lpjml_years)

  grass        <- mbind(litc_grass, vegc_grass, soilc_grass)

  topsoilc     <- calcOutput("TopsoilCarbon", version=version, climatetype=climatetype,
                              averaging_range=averaging_range, time=time, dof=dof,
                              harmonize_baseline=harmonize_baseline, ref_year=ref_year,
                              aggregate=FALSE, years=lpjml_years)
  #find cshare
  cshare_released <- 0.5

  ####################################################
  #Create the output file
  ####################################################


  lpjml_years  <- findset("time")[as.numeric(substring(findset("time"),2))<2099]

  carbon_stocks <- new.magpie(cells_and_regions=getCells(soilc_natveg),
                              years= lpjml_years,
                              names=c("vegc","soilc","litc"))

  carbon_stocks <- add_dimension(carbon_stocks, dim = 3.1, add = "landtype",
                                 nm = c("crop","past","forestry","primforest","secdforest", "urban", "other"))


  ####################################################
  #Calculate the appropriate values for all land types and carbon types.
  ####################################################

  #Factor 0.012 is based on the script subversion/svn/tools/carbon_cropland, executed at 30.07.2013
  carbon_stocks[,,"crop.vegc"]       <- 0.012*natveg[,,"vegc"]
  carbon_stocks[,,"crop.litc"]       <- 0 # does not make sense
  carbon_stocks[,,"crop.soilc"]      <- (1-cshare_released) * topsoilc + (soilc_natveg-topsoilc)

  carbon_stocks[,,"past"]            <- grass
  carbon_stocks[,,"forestry"]        <- natveg
  carbon_stocks[,,"primforest"]      <- natveg
  carbon_stocks[,,"secdforest"]      <- natveg
  carbon_stocks[,,"urban"]           <- 0
  carbon_stocks[,,"other"]           <- natveg #or grass?


  # Check for NAs
  if(any(is.na(carbon_stocks))){
    stop("produced NA Carbon")
  }

  return(list(
    x=carbon_stocks,
    weight=NULL,
    unit="t per ha",
    description="Carbon in tons per hectar for different land use types.",
    isocountries=FALSE))
}
