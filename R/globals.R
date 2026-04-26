# globals.R — suppress R CMD check notes for bare column names

utils::globalVariables(c(
  "evidence_code",
  "aspect",
  "evidence_category",
  "taxon_interactor",
  "taxon_subject",
  "n"
))
