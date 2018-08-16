# Commonly used models ----------------------------------------------------

# Interaction model with all covariates.
lmm_ia_chbdibai <- function()
{
  list(dependent = "value",
      fixed = c("mbigroup", "project", "mbigroup:project"),
      random = "(1 | sbjnr)",
      covariate = c("channel", "BDI2", "BAI"),
      description = "lmm_ia_chbdibai")
}

# Interaction model without covariates.
lmm_ia_ch <- function()
{
  list(dependent = "value",
        fixed = c("mbigroup", "project", "mbigroup:project"),
        random = "(1 | sbjnr)",
        covariate = c("channel"),
        description = "lmm_ia_ch")
}


# Main effects-model with all covariates.
lmm_me_chbdibai <- function()
{
  list(dependent = "value",
      fixed = c("MBIScore", "project"),
      random = "(1 | sbjnr)",
      covariate = c("channel", "BDI2", "BAI"),
      description = "lmm_me_chbdibai")
}

# Main effects model without covariates.
lmm_me_ch <- function()
{
  list(dependent = "value",
        fixed = c("MBIScore", "project"),
        random = "(1 | sbjnr)",
        covariate = c("channel"),
        description = "lmm_me_ch")
}

# # Model for vascular. ses = measurement session, or effect of operation/time.
# fit_lmm_ses_ch <- function()
# {
# list(dependent = "value",
#      fixed = c("session"),
#      random = "(1 | sbjnr)",
#      covariate = c("channel"),
#      description = "lmm_ses_ch")
# }
