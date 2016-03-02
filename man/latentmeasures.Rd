\name{latentmeasures}
\alias{latentmeasures}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Means, Variances, and Correlations of Latent Variables
}
\description{
The means and variances of latent variables and the correlations among the latent variables. In gesca 1.0, the individual scores of latent variables are calculated based on Fornell's (1992) approach.
}
\usage{
latentmeasures(object)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{object}{
An object of class. This can be created via the \code{\link{gesca.run}} function.
}
}
\value{
Numeric vectors of means and variances, and correlation matrices.
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of "comp1"}
%%  \item{comp2 }{Description of "comp2"}
%% ...
}
\references{
Fornell, C. (1992). A national customer satisfaction barometer, the Swedish experience. \emph{Journal of Marketing}, \emph{56}, 6-21.

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
latentmeasures(GSCA.group)

}
