#' @title Simulation Scenarion from Bhatnagar et al. (2018+) sail paper
#' @description generates the different simulation scenarios. This function is
#'   not intended to be called directly by users. See \code{\link{gendata}}
#' @inheritParams gendata
#' @param hierarchy type of hierarchy. Can be one of \code{c("strong", "weak",
#'   "none")}. Default: "strong"
#' @param nonlinear simulate non-linear terms (logical). Default: TRUE
#' @param interactions simulate interaction (logical). Default: TRUE
#' @param causal character vector of causal variable names
#' @param not_causal character vector of noise variables
#' @return A list with the following elements: \describe{ \item{x}{matrix of
#'   dimension \code{nxp} of simulated main effects} \item{y}{simulated response
#'   vector of length \code{n}} \item{e}{simulated exposure vector of length
#'   \code{n}} \item{Y.star}{linear predictor vector of length \code{n}}
#'   \item{f1}{the function \code{f1} evaluated at \code{x_1} (\code{f1(X1)})}
#'   \item{f2}{the function \code{f1} evaluated at \code{x_1} (\code{f1(X1)})}
#'   \item{f3}{the function \code{f1} evaluated at \code{x_1} (\code{f1(X1)})}
#'   \item{f4}{the function \code{f1} evaluated at \code{x_1} (\code{f1(X1)})}
#'   \item{betaE}{the value for \eqn{\beta_E}} \item{f1.f}{the function
#'   \code{f1}} \item{f2.f}{the function \code{f2}} \item{f3.f}{the function
#'   \code{f3}} \item{f4.f}{the function \code{f4}} \item{X1}{an \code{n} length
#'   vector of the first predictor} \item{X2}{an \code{n} length vector of the
#'   second predictor} \item{X3}{an \code{n} length vector of the third
#'   predictor} \item{X4}{an \code{n} length vector of the fourth predictor}
#'   \item{scenario}{a character representing the simulation scenario identifier
#'   as described in Bhatnagar et al. (2018+)} \item{causal}{character vector of
#'   causal variable names}\item{not_causal}{character vector of noise
#'   variables} }
#' @details Requires installation of \code{truncnorm} package. Not meant to be
#'   called directly by user. Use \code{\link{gendata}}.
#' @seealso \code{\link[stats]{rnorm}},\code{\link[stats]{cor}},
#'   \code{\link{gendata}}
gendataPaper <- function(n, p, corr = 0,
                         E = truncnorm::rtruncnorm(n, a = -1, b = 1),
                         # E = rbinom(n,1,0.5),
                         betaE = 2, SNR = 2, hierarchy = c("strong", "weak", "none"),
                         nonlinear = TRUE, interactions = TRUE, causal, not_causal) {
  # this is modified from "VARIABLE SELECTION IN NONPARAMETRIC ADDITIVE MODEL" huang et al, Ann Stat.
  # n = 200
  # p = 10
  # corr = 1

  if (!requireNamespace("truncnorm", quietly = TRUE)) {
    stop("Package \"truncnorm\" needed for this function to simulate data. Please install it.",
      call. = FALSE
    )
  }

  hierarchy <- match.arg(hierarchy)

  # covariates
  W <- replicate(n = p, truncnorm::rtruncnorm(n, a = 0, b = 1))
  U <- truncnorm::rtruncnorm(n, a = 0, b = 1)
  V <- truncnorm::rtruncnorm(n, a = 0, b = 1)

  # W <- replicate(n = p, rnorm(n))
  # U <- rnorm(n)
  # V <- rnorm(n)

  X1 <- (W[, 1] + corr * U) / (1 + corr)
  X2 <- (W[, 2] + corr * U) / (1 + corr)
  X3 <- (W[, 3] + corr * U) / (1 + corr)
  X4 <- (W[, 4] + corr * U) / (1 + corr)

  X <- (W[, 5:p] + corr * V) / (1 + corr)

  Xall <- cbind(X1, X2, X3, X4, X)

  colnames(Xall) <- paste0("X", seq_len(p))

  # see "Variable Selection in NonParametric Addditive Model" Huang Horowitz and Wei
  if (nonlinear) {

    f1 <- function(x) 5 * x
    f2 <- function(x) 3 * (2 * x - 1)^2
    f3 <- function(x) 4 * sin(2 * pi * x) / (2 - sin(2 * pi * x))
    f4 <- function(x) 6 * (0.1 * sin(2 * pi * x) + 0.2 * cos(2 * pi * x) +
                             0.3 * sin(2 * pi * x)^2 + 0.4 * cos(2 * pi * x)^3 +
                             0.5 * sin(2 * pi * x)^3)
    f3.inter = function(x, e) e * f3(x)
    f4.inter = function(x, e) e * f4(x)

  } else {
    # f1 <- function(x) -1.5 * (x - 2)
    # f2 <- function(x)  1 * (x + 1)
    # f3 <- function(x)  1.5 * x
    # f4 <- function(x)  -2 * x
    # f3.inter <- function(x, e) e * f3(x)
    # f4.inter <- function(x, e) -1.5 * e * f4(x)

    # f1 <- function(x) 2 * x
    # f2 <- function(x)  -2 * (x + 1)
    # f3 <- function(x)  2.5 * x
    # f4 <- function(x)  -2.5 * (x - 2)
    # f3.inter <- function(x, e) e * f3(x)
    # f4.inter <- function(x, e) e * f4(x)

    f1 <- function(x) 5 * x
    f2 <- function(x)  3 * (x + 1)
    f3 <- function(x)  4 * x
    f4 <- function(x)  6 * (x - 2)
    f3.inter <- function(x, e) e * f3(x)
    f4.inter <- function(x, e) e * f4(x)

  }
  # error
  error <- stats::rnorm(n)

  if (!nonlinear) {

    Y.star <- f1(X1) +
      f2(X2) +
      f3(X3) +
      f4(X4) +
      betaE * E +
      f3.inter(X3,E) +
      f4.inter(X4,E)

    scenario <- "2"

  } else {
    if (!interactions) {
      # main effects only; non-linear Scenario 3
      Y.star <- f1(X1) +
        f2(X2) +
        f3(X3) +
        f4(X4) +
        betaE * E
      scenario <- "3"
    } else {
      if (hierarchy == "none" & interactions) {
        # interactions only; non-linear
        Y.star <- E * f3(X3) +
          E * f4(X4)
        scenario <- "1c"
      } else if (hierarchy == "strong" & interactions) {
        # strong hierarchy; non-linear
        Y.star <- f1(X1) +
          f2(X2) +
          f3(X3) +
          f4(X4) +
          betaE * E +
          E * f3(X3) +
          E * f4(X4)
        scenario <- "1a"
      } else if (hierarchy == "weak" & interactions) {
        # weak hierarchy; linear
        Y.star <- f1(X1) +
          f2(X2) +
          # f3(X3) +
          # f4(X4) +
          betaE * E +
          E * f3(X3) +
          E * f4(X4)
        scenario <- "1b"
      }
    }
  }

  k <- sqrt(stats::var(Y.star) / (SNR * stats::var(error)))

  Y <- Y.star + as.vector(k) * error

  return(list(
    x = Xall, y = Y, e = E, Y.star = Y.star, f1 = f1(X1),
    f2 = f2(X2), f3 = f3(X3), f4 = f4(X4), betaE = betaE,
    f1.f = f1, f2.f = f2, f3.f = f3, f4.f = f4,
    X1 = X1, X2 = X2, X3 = X3, X4 = X4, scenario = scenario,
    causal = causal, not_causal = not_causal
  ))
}



#' @title Simulation Scenario from Bhatnagar et al. (2018+) sail paper
#' @description Function that generates data of the different simulation studies
#'   presented in the accompanying paper. This function requires the
#'   \code{truncnorm} package to be installed.
#' @param n number of observations
#' @param p number of main effect variables (X)
#' @param corr correlation between predictors
#' @param E simulated environment vector of length \code{n}. Can be continuous
#'   or integer valued. Factors must be converted to numeric. Default:
#'   \code{truncnorm::rtruncnorm(n, a = -1, b = 1)}
#' @param betaE exposure effect size
#' @param SNR signal to noise ratio
#' @param parameterIndex simulation scenario index. See details for more
#'   information.
#' @return A list with the following elements: \describe{ \item{x}{matrix of
#'   dimension \code{nxp} of simulated main effects} \item{y}{simulated response
#'   vector of length \code{n}} \item{e}{simulated exposure vector of length
#'   \code{n}} \item{Y.star}{linear predictor vector of length \code{n}}
#'   \item{f1}{the function \code{f1} evaluated at \code{x_1} (\code{f1(X1)})}
#'   \item{f2}{the function \code{f1} evaluated at \code{x_1} (\code{f1(X1)})}
#'   \item{f3}{the function \code{f1} evaluated at \code{x_1} (\code{f1(X1)})}
#'   \item{f4}{the function \code{f1} evaluated at \code{x_1} (\code{f1(X1)})}
#'   \item{betaE}{the value for \eqn{\beta_E}} \item{f1.f}{the function
#'   \code{f1}} \item{f2.f}{the function \code{f2}} \item{f3.f}{the function
#'   \code{f3}} \item{f4.f}{the function \code{f4}} \item{X1}{an \code{n} length
#'   vector of the first predictor} \item{X2}{an \code{n} length vector of the
#'   second predictor} \item{X3}{an \code{n} length vector of the third
#'   predictor} \item{X4}{an \code{n} length vector of the fourth predictor}
#'   \item{scenario}{a character representing the simulation scenario identifier
#'   as described in Bhatnagar et al. (2018+)}\item{causal}{character vector of
#'   causal variable names}\item{not_causal}{character vector of noise
#'   variables} }
#'
#'
#' @details We evaluate the performance of our method on three of its defining
#'   characteristics: 1) the strong heredity property, 2) non-linearity of
#'   predictor effects and 3) interactions. \describe{ \item{Heredity
#'   Property}{\describe{\item{}{Truth obeys strong hierarchy
#'   (\code{parameterIndex = 1}) \deqn{Y* = \sum_{j=1}^{4} f_j(X_{j}) + \beta_E
#'   * X_{E} +  X_{E} * f_3(X_{3}) + X_{E} * f_4(X_{4}) }} \item{}{Truth obeys
#'   weak hierarchy (\code{parameterIndex = 2}) \deqn{Y* = f_1(X_{1}) +
#'   f_2(X_{2}) + \beta_E * X_{E} +  X_{E} * f_3(X_{3}) + X_{E} * f_4(X_{4}) }}
#'   \item{}{Truth only has interactions (\code{parameterIndex = 3})\deqn{Y* =
#'   X_{E} * f_3(X_{3}) + X_{E} * f_4(X_{4}) }}}} \item{Non-linearity}{Truth is
#'   linear (\code{parameterIndex = 4}) \deqn{Y* = \sum_{j=1}^{4}\beta_j X_{j} +
#'   \beta_E * X_{E} +  X_{E} * X_{3} + X_{E} * X_{4} }}
#'   \item{Interactions}{Truth only has main effects (\code{parameterIndex = 5})
#'   \deqn{Y* = \sum_{j=1}^{4} f_j(X_{j}) + \beta_E * X_{E} }} }.
#'
#'   The functions are from the paper by Lin and Zhang (2006):
#'   \describe{\item{f1}{f1 <- function(t) 5 * t} \item{f2}{  f2 <- function(t)
#'   3 * (2 * t - 1)^2} \item{f3}{  f3 <- function(t) 4 * sin(2 * pi * t) / (2 -
#'   sin(2 * pi * t))} \item{f4}{  f4 <- function(t) 6 * (0.1 * sin(2 * pi * t)
#'   + 0.2 * cos(2 * pi * t) + 0.3 * sin(2 * pi * t)^2 + 0.4 * cos(2 * pi * t)^3
#'   + 0.5 * sin(2 * pi * t)^3)}}
#'
#'
#'   The response is generated as \deqn{Y = Y* + k*error} where Y* is the linear
#'   predictor, the error term is generated from a standard normal distribution,
#'   and k is chosen such that the signal-to-noise ratio is SNR =
#'   Var(Y*)/Var(error), i.e., the variance of the response variable Y due to
#'   error is 1/SNR of the variance of Y due to Y*
#'
#'   The covariates are simulated as follows as described in Huang et al.
#'   (2010). First, we generate \eqn{w1,\ldots, wp, u,v} independently from
#'   \eqn{Normal(0,1)} truncated to the interval \code{[0,1]} for
#'   \eqn{i=1,\ldots,n}. Then we set \eqn{x_j = (w_j + t*u)/(1 + t)} for \eqn{j
#'   = 1,\ldots, 4} and \eqn{x_j = (w_j + t*v)/(1 + t)} for \eqn{j = 5,\ldots,
#'   p}, where the parameter \eqn{t} controls the amount of correlation among
#'   predictors. This leads to a compound symmetry correlation structure where
#'   \eqn{Corr(x_j,x_k) = t^2/(1+t^2)}, for \eqn{1 \le j \le 4, 1 \le k \le 4},
#'   and \eqn{Corr(x_j,x_k) = t^2/(1+t^2)}, for \eqn{5 \le j \le p, 5 \le k \le
#'   p}, but the covariates of the nonzero and zero components are independent.
#'
#' @examples
#' DT <- gendata(n = 75, p = 100, corr = 0, betaE = 2, SNR = 1, parameterIndex = 1)
#' @rdname gendata
#' @references Lin, Y., & Zhang, H. H. (2006). Component selection and smoothing
#'   in multivariate nonparametric regression. The Annals of Statistics, 34(5),
#'   2272-2297.
#' @references Huang J, Horowitz JL, Wei F. Variable selection in nonparametric
#'   additive models (2010). Annals of statistics. Aug 1;38(4):2282.
#' @references Bhatnagar SR, Yang Y, Greenwood CMT. Sparse additive interaction
#'   models with the strong heredity property (2018+). Preprint.
#' @export
gendata <- function(n, p, corr, E = truncnorm::rtruncnorm(n, a = -1, b = 1),
                    betaE, SNR, parameterIndex) {
  if (!requireNamespace("truncnorm", quietly = TRUE)) {
    stop("Package \"truncnorm\" needed for this function to simulate data. Please install it.",
      call. = FALSE
    )
  }

  main <- paste0("X", seq_len(p))
  vnames <- c(main, "E", paste0(main, ":E"))

  if (parameterIndex == 1) { # 1a
    hierarchy <- "strong"
    nonlinear <- TRUE
    interactions <- TRUE
    causal <- c("X1", "X2", "X3", "X4", "E", "X3:E", "X4:E")
  } else if (parameterIndex == 2) { # 1b
    hierarchy <- "weak"
    nonlinear <- TRUE
    interactions <- TRUE
    causal <- c("X1", "X2", "E", "X3:E", "X4:E")
  } else if (parameterIndex == 3) { # 1c
    hierarchy <- "none"
    nonlinear <- TRUE
    interactions <- TRUE
    causal <- c("X3:E", "X4:E")
  } else if (parameterIndex %in% c(4,6)) { # 2
    hierarchy <- "strong"
    nonlinear <- FALSE
    interactions <- TRUE
    causal <- c("X1", "X2", "X3", "X4", "E", "X3:E", "X4:E")
  } else if (parameterIndex == 5) { # 3
    hierarchy <- "strong"
    nonlinear <- TRUE
    interactions <- FALSE
    causal <- c("X1", "X2", "X3", "X4", "E")
  }

  not_causal <- setdiff(vnames, causal)

  DT <- gendataPaper(
    n = n, p = p, corr = corr,
    E = E,
    betaE = betaE, SNR = SNR,
    hierarchy = hierarchy, nonlinear = nonlinear, interactions = interactions,
    causal = causal, not_causal = not_causal
  )
  return(DT)
}
