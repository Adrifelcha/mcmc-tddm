###############################################################################
#####      A script containing auxiliary functions that are used repeatedly
#####               across different sampling algorithms
###############################################################################
# +
# +
# +
# +
# +

###############################################################################
# Transformation functions: ###################################################
###############################################################################
# Switch between Cardinal and Rectangular Coordinates 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
rectToPolar <- function(x,y){
  n <- length(x)
  driftAngle <- atan2(y,x)
  driftLength <- sqrt((x^2)+(y^2))
  output <- as.data.frame(cbind(driftAngle,driftLength))
  colnames(output) <- c("dAngle","dLength")
  return(output)
}

polarToRect <- function(vectorAngle,vectorLength){
  x <- vectorLength*cos(vectorAngle)
  y <- vectorLength*sin(vectorAngle)
  X <-  as.data.frame(cbind(x,y))
  colnames(X) <-  c("x","y")
  return(X)
}


# Switch between degrees and radians
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
degToRad <- function(theta.deg){  
  theta <-  theta.deg * pi /180  #Transform to radians
  return(theta)
}

radToDeg <- function(theta.rad){
  theta <- theta.rad * (180/pi)
  return(theta)
}


###############################################################################
# Sampling space functions: ###################################################
###############################################################################

### Use CDDM density function to find key values for setting up the sampling space
keyDensityPoints <- function(par, cutoff = 0.00009){
  # Extract model parameters from input list
  drift <- par$drift;   theta <- par$theta      # Drift magnitude and direction
  tzero <- par$tzero;   boundary <- par$boundary # Non-decision time and boundary
  
  ### Find minimum response time (RT) where density exceeds cutoff
  # Start from non-decision time plus small increment
  density <- 0
  min.RT <- tzero+0.1
  while(density < cutoff){
    # Test density at drift direction (theta) until exceeding cutoff
    density <- dCDDM(c(theta,min.RT),drift,theta,tzero,boundary)
    min.RT <- min.RT+0.01
  }

  ### Find maximum density and most likely RT
  # Search for peak density by incrementing RT until density starts decreasing
  density_increase <- TRUE; d <- 0
  pred.RT <- min.RT
  while(density_increase){
    pred.RT <- pred.RT+0.01
    density <- dCDDM(c(theta,pred.RT),drift,theta,tzero,boundary)
    density_increase <- density > d
    d <- density
  }
  max.Density <- density

  ### Find maximum RT where density falls below cutoff
  # Start from predicted RT and increment until density drops below cutoff
  max.RT <- pred.RT
  while(density > cutoff){
    density <- dCDDM(c(theta,max.RT),drift,theta,tzero,boundary)
    max.RT <- max.RT+0.01
  }

  # Return key points needed for setting up rejection sampling
  return(list("min.RT" = min.RT,          # Minimum response time
              "pred.RT" = pred.RT,         # Most likely response time
              "max.Density" = max.Density, # Maximum density value
              "max.RT" = max.RT))         # Maximum response time
}

###############################################################################
# Ex-Gaussian functions: ######################################################
###############################################################################

rexGAUS <- function(n, mu, sigma, tau) {
  return(rnorm(n, mu, sigma) + rexp(n, 1/tau))
}

dexGAUS <- function(x, mu, sigma, tau) {
  if(tau <= 0) return(dnorm(x, mu, sigma))
  
  arg1 <- sigma^2/(2*tau^2) + (mu-x)/tau
  arg2 <- (x-mu)/sigma - sigma/tau
  
  return(exp(arg1) * pnorm(arg2) / tau)
}

###############################################################################
# Log-RT functions:   #########################################################
###############################################################################

# Function to compute variance and mean of log-transformed RTs
logRT_stats <- function(mean_RT, var_RT) {
  # Compute log-RT variance
  sigma_logRT <- log(var_RT / mean_RT^2 + 1)
  
  # Compute log-RT mean
  mu_Y <- log(mean_X) - (sigma_Y2 / 2)
  
  # Return both values as a list
  return(list(mu_logRT = mu_logRT, sigma_logRT = sigma_logRT))
}

