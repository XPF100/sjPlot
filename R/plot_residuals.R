#' @title Plot predicted values and their residuals
#' @name plot_residuals
#'
#' @description This function plots observed and predicted values of the response
#'              of linear (mixed) models for each coefficient and highlights the
#'              observed values according to their distance (residuals) to the
#'              predicted values. This allows to investigate how well actual and
#'              predicted values of the outcome fit across the predictor variables.
#'
#' @param fit Fitted linear (mixed) regression model (including objects of class
#'        \code{\link[nlme]{gls}} or \code{plm}).
#' @param show.lines Logical, if \code{TRUE}, a line connecting predicted and
#'        residual values is plotted. Set this argument to \code{FALSE}, if
#'        plot-building is too time consuming.
#' @param show.resid Logical, if \code{TRUE}, residual values are plotted.
#' @param show.pred Logical, if \code{TRUE}, predicted values are plotted.
#'
#' @inheritParams plot_model
#' @inheritParams plot_scatter
#' @inheritParams sjp.grpfrq
#' @inheritParams sjt.lm
#'
#' @return A ggplot-object.
#'
#' @note The actual (observed) values have a coloured fill, while the predicted
#'       values have a solid outline without filling.
#'
#' @examples
#' data(efc)
#' # fit model
#' fit <- lm(neg_c_7 ~ c12hour + e17age + e42dep, data = efc)
#'
#' # plot residuals for all independent variables
#' plot_residuals(fit)
#'
#' # remove some independent variables from output
#' plot_residuals(fit, remove.estimates = c("e17age", "e42dep"))
#'
#' @importFrom rlang .data
#' @export
plot_residuals <- function(fit, geom.size = 2, remove.estimates = NULL, show.lines = TRUE,
                      show.resid = TRUE, show.pred = TRUE, show.ci = FALSE) {
  # show lines only when both residual and predicted
  # values are plotted - else, lines make no sense
  if (!show.pred || !show.resid) show.lines <- FALSE

  # Obtain predicted and residual values
  mydat <- sjstats::model_frame(fit)

  # check whether estimates should be removed from plot
  if (!is.null(remove.estimates)) {
    keep <- which(!colnames(mydat) %in% remove.estimates)
  } else {
    keep <- seq_len(ncol(mydat))
  }
  mydat$predicted <- stats::predict(fit)
  mydat$residuals <- stats::residuals(fit)

  # get name of response, used in ggplot-aes
  rv <- sjstats::resp_var(fit)

  # remove estimates, if required
  dummy <- mydat %>% dplyr::select(keep, .data$predicted, .data$residuals)

  # set default variable labels, used as column names, so labelled
  # data variable labels appear in facet grid header.
  sel <- 2:length(keep)
  var.labels <- sjlabelled::get_label(dummy, def.value = colnames(dummy)[sel])[sel]
  if (is.null(var.labels) || all(var.labels == "")) var.labels <- colnames(dummy)[sel]
  colnames(dummy)[sel] <- var.labels

  # melt data
  mydat <- suppressWarnings(dummy %>%
    tidyr::gather(key = "grp", value = "x", -1, -.data$predicted, -.data$residuals))

  colnames(mydat)[1] <- ".response"

  # melt data, build basic plot
  res.plot <- ggplot(mydat, aes(x = .data$x, y = .data$.response)) +
    stat_smooth(method = "lm", se = show.ci, colour = "grey70")

  if (show.lines) res.plot <- res.plot +
    geom_segment(aes(xend = .data$x, yend = .data$predicted), alpha = .3)

  if (show.resid) res.plot <- res.plot +
    geom_point(aes(fill = .data$residuals), size = geom.size, shape = 21, colour = "grey50")

  if (show.pred) res.plot <- res.plot +
    geom_point(aes(y = .data$predicted), shape = 1, size = geom.size)

  # residual plot
  res.plot <- res.plot +
    facet_grid(~grp, scales = "free") +
    scale_fill_gradient2(low = "#003399", mid = "white", high = "#993300") +
    guides(color = FALSE, fill = FALSE) +
    labs(x = NULL, y = sjlabelled::get_label(mydat[[1]], def.value = rv))

  res.plot
}
