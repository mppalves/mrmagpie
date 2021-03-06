#' @title calcAvlWater
#' @description This function calculates water availability for MAgPIE retrieved from LPJmL
#'
#' @param version Switch between LPJmL4 and LPJmL5
#' @param climatetype Switch between different climate scenarios (default: "CRU_4")
#' @param time Time smoothing: average, spline or raw (default)
#' @param averaging_range only specify if time=="average": number of time steps to average
#' @param dof             only specify if time=="spline": degrees of freedom needed for spline
#' @param harmonize_baseline FALSE (default): no harmonization, TRUE: if a baseline is specified here data is harmonized to that baseline (from ref_year on)
#' @param ref_year Reference year for harmonization baseline (just specify when harmonize_baseline=TRUE)
#' @param selectyears Years to be returned
#' @param seasonality grper (default): water available in growing period per year; total: total water available throughout the year; monthly: monthly water availability (for further processing, e.g. in calcEnvmtlFlow)
#'
#' @import magclass
#' @import madrat
#'
#' @return magpie object in cellular resolution
#' @author Felicitas Beier, Kristine Karstens, Abhijeet Mishra
#'
#' @examples
#' \dontrun{ calcOutput("AvlWater", aggregate = FALSE) }
#'

calcAvlWater <- function(selectyears="all",
                         version="LPJmL4", climatetype="CRU_4", time="raw", averaging_range=NULL, dof=NULL,
                         harmonize_baseline=FALSE, ref_year="y2015",
                         seasonality="grper"){

  ######################################################
  ############ Water availability per cell #############
  # Runoff is distributed across the river basin cells #
  # based on discharge-weighted algorithm              #
  ######################################################

  if(harmonize_baseline==FALSE){

    if(time=="raw"){

      ### Monthly Discharge (unit (after calcLPJmL): mio. m^3/month)
      monthly_discharge_magpie <- calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="mdischarge", aggregate=FALSE,
                                             harmonize_baseline=FALSE,
                                             time="raw")
      # Transform to array (faster calculation)
      monthly_discharge_magpie <- as.array(collapseNames(monthly_discharge_magpie))

      ### Monthly Runoff (unit (after calcLPJmL): mio. m^3/month)
      monthly_runoff_magpie    <- calcOutput("LPJmL", version=version, climatetype=climatetype, subtype="mrunoff", aggregate=FALSE,
                                             harmonize_baseline=FALSE,
                                             time="raw")
      # Transform to array (faster calculation)
      monthly_runoff_magpie    <- as.array(collapseNames(monthly_runoff_magpie))

      ### Calculate available water per month (avl_water_month)
      # Empty array
      avl_water_month     <- monthly_runoff_magpie
      avl_water_month[,,] <- NA

      ## River basin water allocation algorithm:
      # River basin information
      basin_code <- toolGetMapping("rivermapping.csv",type="cell")
      basin_code <- basin_code$basincode

      # Sum the runoff in all basins and allocate it to the basin cells with discharge as weight
      for(basin in unique(basin_code)){
        basin_cells     <- which(basin_code==basin)
        basin_runoff    <- colSums(monthly_runoff_magpie[basin_cells,,,drop=FALSE])
        basin_discharge <- colSums(monthly_discharge_magpie[basin_cells,,,drop=FALSE])
        for(month in dimnames(avl_water_month)[[3]]){
          avl_water_month[basin_cells,,month] <- t(basin_runoff[,month]*t(monthly_discharge_magpie[basin_cells,,month])/basin_discharge[,month])
        }
      }
      # Remove no longer needed objects
      rm(basin_discharge,basin_runoff)

      # avl_water_month contain NA's wherever basin_discharge was 0 -> Replace NA's by 0
      avl_water_month[is.nan(avl_water_month)] <- 0
      avl_water_month <- as.magpie(avl_water_month)

    } else {
      # Time smoothing:
      x     <- calcOutput("AvlWater", version=version, climatetype=climatetype, seasonality="monthly", aggregate=FALSE,
                          harmonize_baseline=FALSE, time="raw")

      if(time=="average"){

        # Smoothing data through average:
        avl_water_month <- toolTimeAverage(x, averaging_range=averaging_range)

      } else if(time=="spline"){

        # Smoothing data with spline method:
        avl_water_month <- toolTimeSpline(x, dof=dof)
        # Replace value in 2100 with value from 2099 (LPJmL output ends in 2099)
        if ("y2099" %in% getYears(avl_water_month)) {
          avl_water_month <- toolFillYears(avl_water_month, c(getYears(avl_water_month, as.integer=TRUE)[1]:2100))
        }

      } else if(time!="raw"){
        stop("Time argument not supported!")
      }
    }

  } else {

    if(time=="raw"){
      stop("Harmonization with raw data not possible. Select time='spline' when applying harmonize_baseline=TRUE")
    } else {
      # Load smoothed data
      baseline <- calcOutput("AvlWater", version=version, climatetype=harmonize_baseline, seasonality="monthly", aggregate=FALSE,
                             harmonize_baseline=FALSE, time=time, dof=dof, averaging_range=averaging_range)
      x        <- calcOutput("AvlWater", version=version, climatetype=climatetype, seasonality="monthly", aggregate=FALSE,
                             harmonize_baseline=FALSE, time=time, dof=dof, averaging_range=averaging_range)
      # Harmonize to baseline
      avl_water_month <- toolHarmonize2Baseline(x=x, base=baseline, ref_year=ref_year, limited=TRUE, hard_cut=FALSE)
    }
  }

  if(selectyears!="all"){
    years           <- sort(findset(selectyears,noset = "original"))
    avl_water_month <- avl_water_month[,years,]
  }

  ###########################################
  ######### RETURN FUNCTION OUTPUT ##########
  ###########################################

  ### Available water per cell per month
  if(seasonality=="monthly"){
    # Check for NAs
    if(any(is.na(avl_water_month))){
      stop("produced NA water availability")
    }
    out=avl_water_month
    description="Available water per cell per month (based on runoff and discharge from LPJmL)"
  }

  ### Total water available per cell per year
  if(seasonality=="total"){
    # Sum up over all month:
    avl_water_total <- dimSums(avl_water_month, dim=3)
    # Check for NAs
    if(any(is.na(avl_water_total))){
      stop("produced NA water availability")
    }
    out=avl_water_total
    description="Total available water per year"
  }

  ### Water available in growing period per cell per year
  if(seasonality=="grper"){
    # magpie object with days per month with same dimension as avl_water_month
    tmp <- c(31,28,31,30,31,30,31,31,30,31,30,31)
    month_days     <- new.magpie(names=dimnames(avl_water_month)[[3]])
    month_days[,,] <- tmp
    month_day_magpie     <- as.magpie(avl_water_month)
    month_day_magpie[,,] <- 1
    month_day_magpie     <- month_day_magpie * month_days

    # Daily water availability
    avl_water_day <- avl_water_month/month_day_magpie

    # Growing days per month
    grow_days <- calcOutput("GrowingPeriod", version="LPJmL5", climatetype=climatetype, time=time, dof=dof, averaging_range=averaging_range,
                            harmonize_baseline=harmonize_baseline, ref_year=ref_year, yield_ratio=0.1, aggregate=FALSE)

    # Adjust years
    years_wat <- getYears(avl_water_day)
    years_grper  <- getYears(grow_days)
    if(length(years_wat)>=length(years_grper)){
      years <- years_grper
    } else {
      years <- years_wat
    }
    rm(years_grper, years_wat)

    # Available water in growing period per month
    avl_water_grper <- avl_water_day[,years,]*grow_days[,years,]
    # Available water in growing period per year
    avl_water_grper <- dimSums(avl_water_grper, dim=3)

    # Check for NAs
    if(any(is.na(avl_water_grper))){
      stop("produced NA water availability")
    }
    out=avl_water_grper
    description="Available water in growing period per year"
  }

  return(list(
    x=out,
    weight=NULL,
    unit="mio. m^3",
    description=description,
    isocountries=FALSE))
}
