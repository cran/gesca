\name{summary.gesca}
\alias{summary.gesca}
\title{
A Summary and Parameter Estimates of a Fitted Model
}
\description{
A summary of a fitted model such as model fit measures and parameter estimates obtained from GSCA.
}
\usage{
\method{summary}{gesca}(object, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{object}{
This function prints out a nice summary of the fitted model by the gesca.run function, including (1) information on convergence of the alternating least-squares (ALS) algorithm, (2) the number of observations (per group), parameters, and bootstrap samples, (3) six model fit measures, (4) GSCA parameter estimates such as weights, loadings, and path coefficients, and (5) R-squared values of each endogenous latent variable.
}
  \item{...}{
Further arguments passed to or from other methods.
}
}
\value{
Object values of general information and parameter estimates of a fitted model via the gesca.run function.
}
\references{
Hwang, H., & Takane, Y. (2014). Generalized structured component analysis: A Component-Based Approach to Structural Equation Modeling (p.26). Boca Raton, FL: Chapman & Hall/CRC Press.
}
\seealso{
\code{\link{gesca.run}}
}
\examples{

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
summary(GSCA.group)

}
