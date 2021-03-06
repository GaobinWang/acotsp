#' @title Generates a control object for the \code{\link{runACOTSP}} function.
#'
#' @description
#' This function generates a control object, i.e., internally a simple list, of
#' parameters and does sanity checks.
#'
#' @template arg_nants
#' @template arg_nelite
#' @template arg_useglobalbest
#' @template arg_bestdepositonly
#' @template arg_alpha
#' @template arg_beta
#' @template arg_rho
#' @template arg_attfactor
#' @template arg_initpherconc
#' @template arg_minpherconc
#' @template arg_maxpherconc
#' @template arg_localsearchfun
#' @template arg_localsearchstep
#' @template arg_prpprob
#' @template arg_localpherupdatefun
#' @param max.iter [\code{integer(1)}]\cr
#'   Maximal number of iterations. Default is \code{10}.
#' @param max.time [\code{integer(1)}]\cr
#'   Maximum running time in seconds. The algorithm tries hard to hold this
#'   restriction by logging the times of a number of prior iterations and
#'   determining statistically whether the time limit can be hold when another
#'   iteration is done. Default ist \code{Inf}, which means no time limit at all.
#' @param global.opt.value [\code{numeric(1)}]\cr
#'   Known global best tour length. This can be used as another termination
#'   criterion. Default is \code{NULL}, which means, that the length of the
#'   globally best tour is unknown.
#' @param termination.eps [\code{numeric(1)}]\cr
#'   If \code{global.opt.value} is set, the algorithm stops if the quadratic
#'   distance between the global optimum value and the value of the best tour
#'   found so far is lower than these gap value. Ignored if \code{global.opt.value}
#'   is \code{NULL}.
#' @param trace.all [\code{logical(1)}]\cr
#'   Should we save additional information in each iteration, i. e., pheromone
#'   matrix, all ant trails, best ant trail of the current iteration and so on?
#'   Default is \code{FALSE}. You need to set this to \code{TRUE} if you want
#'   to plot the optimization progress via \code{autoplot.AntsResult}.
#' @return [\code{ACOTSPControl}]
#'   S3 control object containing all the checked parameters and reasonable defaults.
#'
#' @export
makeACOTSPControl = function(
  n.ants = 2L,
  n.elite = n.ants,
  use.global.best = FALSE,
  best.deposit.only = FALSE,
  alpha = 1, beta = 2, rho = 0.1, att.factor = 1,
  init.pher.conc = 0.0001, min.pher.conc = 0, max.pher.conc = 10e5,
  local.search.fun = NULL, local.search.step = integer(),
  prp.prob = 0,
  local.pher.update.fun = NULL,
  max.iter = 10L, max.time = Inf, global.opt.value = NULL, termination.eps = 0.1,
  trace.all = FALSE) {

  # do sanity checks
  assertInteger(n.ants, lower = 1L)
  assertInteger(n.elite, lower = 0L)
  if (n.elite > n.ants) {
    stopf("n.elite must be lower or equal to n.ants, but %i = n.elite > n.ants = %i", n.elite, n.ants)
  }
  assertFlag(use.global.best)
  assertFlag(best.deposit.only)
  if (n.elite == 0 && !use.global.best) {
    stopf("Zero elite ants and no global update not allowed! Somehow the pheromones need
      to be updated.")
  }
  assertNumber(alpha, lower = 0, finite = TRUE, na.ok = FALSE)
  assertNumber(beta, lower = 1, finite = TRUE, na.ok = FALSE)
  assertNumber(rho, lower = 0, upper = 1, na.ok = FALSE)
  assertNumber(att.factor, lower = 1, finite = TRUE, na.ok = FALSE)
  assertNumber(init.pher.conc, lower = 0.0001, finite = TRUE, na.ok = FALSE)
  assertNumber(min.pher.conc, lower = 0, finite = TRUE, na.ok = FALSE)
  assertNumber(max.pher.conc, lower = 1, finite = TRUE, na.ok = FALSE)
  assertNumber(prp.prob, lower = 0, upper = 1, na.ok = FALSE)

  if (!is.null(local.pher.update.fun)) {
    assertFunction(local.pher.update.fun, args = "pher")
  }

  # check local search (LS) parameters
  if (!is.null(local.search.fun)) {
    assertFunction(local.search.fun, args = c("x", "initial.tour"))
  }
  assertInteger(local.search.step, min.len = 0L, any.missing = FALSE,
    all.missing = TRUE, unique = TRUE)

  #FIXME: do we want warnings?
  if (!is.null(local.search.fun) && length(local.search.step) == 0L) {
    warningf("The given local search procedure will not be applied at any iterations.
      Consider to set the local.search.step parameter in an appropriate way.")
  }

  if (is.finite(max.time)) {
    max.time = convertInteger(max.time)
  }
  assertNumber(max.time, lower = 100L, na.ok = FALSE)

  if (is.finite(max.iter)) {
    max.iter = convertInteger(max.iter)
  }
  assertInt(max.iter, lower = 1L, na.ok = FALSE)
  if (!is.null(global.opt.value)) {
    assertNumber(global.opt.value, na.ok = FALSE, finite = TRUE)
  }
  assertNumber(termination.eps, lower = 0.000001, finite = TRUE, na.ok = FALSE)

  makeS3Obj(
    n.ants = n.ants,
    n.elite = n.elite,
    use.global.best = use.global.best,
    best.deposit.only = best.deposit.only,
    alpha = alpha,
    beta = beta,
    rho = rho,
    att.factor = att.factor,
    init.pher.conc = init.pher.conc,
    min.pher.conc = min.pher.conc,
    max.pher.conc = max.pher.conc,
    local.search.fun = local.search.fun,
    local.search.step = local.search.step,
    prp.prob = prp.prob,
    local.pher.update.fun = local.pher.update.fun,
    max.iter = max.iter,
    max.time = max.time,
    global.opt.value = global.opt.value,
    termination.eps = termination.eps,
    trace.all = trace.all,
    classes = "ACOTSPControl"
  )
}

#' @export
print.ACOTSPControl = function(x, ...) {
  catf("Ants Control Object")

  catf("\nBASE PARAMETERS")
  if (x$n.elite > 0) {
    catf("Number of ants: %i with %i elite ants (%.2f%%)",
      x$n.ants, x$n.elite, 100 * as.numeric(x$n.elite) / as.numeric(x$n.ants))
  } else {
    catf("Number of ants:        %i", c$n.ants)
  }
  catf("Alpha:              %.3f", x$alpha)
  catf("Beta:               %.3f", x$beta)
  catf("Rho:                %.3f (evaporation rate)", x$rho)
  catf("Attraction factor:  %.3f", x$att.factor)
  catf("Minimal pheromones: %.3f", x$min.pher.conc)
  catf("Maximal pheromones: %.3f", x$max.pher.conc)
  catf("Initial pheromones: %.3f", x$init.pher.conc)

  catf("\nLOCAL SEARCH")
  if (!is.null(x$local.search.fun)) {
    catf("Local search procedure applied to ant trials %s",
      if (length(x$local.search.step) > 1L) {
        sprintf("in iterations %s.", collapse(x$local.search.step))
      } else {
        sprintf("every %i iterations.", x$local.search.step)
      }
    )
  } else {
    catf("No local search procedure applied.")
  }
}
