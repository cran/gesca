\name{fitmeasures}
\alias{fitmeasures}
\title{
Indices for Assessment of Model Fit
}
\description{
This function provides six model fit indices (FIT, Adjusted FIT, GFI, Standardized Root Mean Square, FIT_M, and FIT_S) for the user-specified model.
}
\usage{
fitmeasures(object)
}
\arguments{
  \item{object}{
An object of class. This can be created via the \code{\link{gesca.run}} function.
}
}
\details{
\code{FIT} indicates how much variance of both indicators and latent variables is explained by the user-specified model. \code{AFIT} takes into account the number of parameters when calculating the explained variance. \code{GFI} and \code{SRMR} measure the closeness between the sample covariances and the covariances reproduced by model parameter estimates. In GSCA, separate model fit measures for the measurement and structural models are available: \code{FIT_M} and \code{FIT_S}. \code{FIT_M} assesses how much variance of indicators is explained by a measurement model, whereas \code{FIT_S} calculates how much variance of latent variables is accounted for by a structural model. All six indices are given with their bootstrapped standard errors and confidence intervals. When the number of bootstrap samples is equal to 0, the standard errors will not be reported. The user can specify the number of bootstrap samples via the \code{\link{gesca.run}} function.
}
\value{
Numeric values of six model fit indices: the numbers of parameters and bootstrap samples, and six fit indices with their bootstrapped standard errors and confidence intervals.
}
\references{
Hwang, H., & Takane, Y. (2014). Generalized structured component analysis: A Component-Based Approach to Structural Equation Modeling (pp.26-32). Boca Raton, FL: Chapman & Hall/CRC Press.
}
\seealso{
\code{\link{gesca.run}}
}
\examples{
\donttest{
library(gesca)
data(gesca.rick2) # Organizational identification example of Bagozzi

# Model specification
myModel <- "
		# Measurement model
		OP =~ cei1 + cei2 + cei3
		OI =~ ma1 + ma2 + ma3
		AC_J =~ orgcmt1 + orgcmt2 + orgcmt3
		AC_L =~ orgcmt5 + orgcmt6 + orgcmt8

		# Structural model
		OI ~ OP
		AC_J ~ OI
		AC_L ~ OI
"

# Run a multiple-group GSCA with the grouping variable gender:
GSCA.group <- gesca.run(myModel, gesca.rick2, group.name = "gender", nbt=50)
summary(GSCA.group)	# default output shows model fit indices as well, but
fitmeasures(GSCA.group)	# this gives bootstrapped std errors and CI
}
}
