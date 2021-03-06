% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.R
\name{plotMain}
\alias{plotMain}
\title{Plot Estimated Component Smooth Functions for Main Effects}
\usage{
plotMain(object, x, xvar, s, f.truth, col = c("#D55E00", "#009E73"),
  legend.position = "bottomleft", rug = TRUE, ...)
}
\arguments{
\item{object}{a fitted \code{sail} object as produced by \code{sail()} or
\code{cv.sail()$sail.fit}}

\item{x}{original data supplied to the original call to \code{\link{sail}}}

\item{xvar}{a character corresponding to the predictor to be plotted. Only
one variable name should be supplied, if more than one is supplied, only
the first element will be plotted. This variable name must be in
\code{colnames(x)}.}

\item{s}{a single value of the penalty parameter \code{lambda} at which
coefficients will be extracted via the \code{coef} method for objects of
class \code{"sail"}. If more than one is supplied, only the first one will
be used.}

\item{f.truth}{true function. Only used for simulation purposes when the
truth is known. The function takes as a input a numeric vector
corresponding the \code{xvar} column in \code{x} of length \code{nrow(x)}.
A second line will be plotted for the truth and a legend is added to the
plot.}

\item{col}{color of the line. The first element corresponds to the color used
for the estimated function and the second element is for the true function
(if \code{f.truth} is specified). Default: c("#D55E00", "#009E73")}

\item{legend.position}{position of the legend. Only used when \code{f.truth}
is specified. Default: 'bottomleft'. Can be a single keyword from the list
"bottomright", "bottom", "bottomleft", "left", "topleft", "top",
"topright", "right" and "center". This places the legend on the inside of
the plot frame at the given location. Partial argument matching is used.}

\item{rug}{adds a rug representation (1-d plot) of the data to the plot, logical. Default: TRUE.}

\item{...}{other graphical paramters passed to \code{plot}.}
}
\value{
A plot is produced and nothing is returned
}
\description{
Takes a fitted sail object produced by \code{sail()} or
  \code{cv.sail()$sail.fit} and plots the component smooth function for a
  pre-specified variable at a given value of lambda and on the scale of the
  linear predictor. Currently only implemented for \code{type="gaussian"}
}
\details{
The linear predictor \eqn{basis(xvar) * \beta_xvar} is
  plotted against \code{xvar}, where \code{basis} is the expansion provided
  in the original call to \code{sail}.
}
\examples{
\dontrun{
if(interactive()){
# Parallel
library(doMC)
registerDoMC(cores = 4)
data("sailsim")
f.basis <- function(i) splines::bs(i, degree = 5)
cvfit <- cv.sail(x = sailsim$x, y = sailsim$y, e = sailsim$e,
                 basis = f.basis, nfolds = 10, parallel = TRUE)
# plot cv-error curve
plot(cvfit)
# non-zero estimated coefficients at lambda.min
predict(cvfit, type = "nonzero", s="lambda.min")
# plot main effect for X4 with a line for the truth also
plotMain(cvfit$sail.fit, x = sailsim$x, xvar = "X4",
         s = cvfit$lambda.min, f.truth = sailsim$f4)
 }
}
}
\seealso{
\code{\link{coef.sail}} \code{\link{predict.sail}}, \code{\link[graphics]{rug}}
}
