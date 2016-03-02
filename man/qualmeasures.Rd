\name{qualmeasures}
\alias{qualmeasures}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Reliability and Validity Measures
}
\description{
A variety of reliability and validity measures.
}
\usage{
qualmeasures(object)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{object}{
An object of class. This can be created via the \code{\link{gesca.run}} function.
}
}
\details{
Cronbach's alpha and Dillon-Goldstein's rho (or the composite reliability) can be used for checking internal consistency of indicators for each latent variable. The average variance extracted (AVE) can be used to examine the convergent validity of a latent variable. The number of eigenvalues greater than one per block of indicators can be used to check uni-dimensionality of the indicators.
}
\value{
Numeric vectors of the reliability and validity measures.
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
qualmeasures(GSCA.group)

}
