# gaf_utils.R — utility functions for working with parsed GAF tibbles

#' Expand a pipe-separated GAF column into long format
#'
#' Several GAF columns contain pipe-separated multi-value fields:
#' \code{db_reference}, \code{with_or_from}, \code{db_object_synonym},
#' and \code{annotation_extension}.  This function unnests one such column
#' into long format, with one value per row and all other columns repeated.
#'
#' @param gaf a tibble as returned by \code{\link{parse_gaf}}.
#' @param column character scalar naming the column to expand.  Must be
#'   one of \code{"db_reference"}, \code{"with_or_from"},
#'   \code{"db_object_synonym"}, or \code{"annotation_extension"}.
#'
#' @return a tibble with \eqn{\geq}{>=} as many rows as \code{gaf} — one
#'   per pipe-separated value in \code{column}.  Rows where \code{column}
#'   is \code{NA} are retained with \code{NA} in the expanded column.
#'
#' @examples
#' gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
#' gaf <- parse_gaf(gaf_path)
#'
#' # db_reference has pipe-separated PMIDs in some rows
#' gaf_expand_column(gaf, "db_reference")
#'
#' # with_or_from has pipe-separated IDs in some rows
#' gaf_expand_column(gaf, "with_or_from")
#'
#' @export
gaf_expand_column <- function(gaf, column) {
  valid <- c("db_reference", "with_or_from",
             "db_object_synonym", "annotation_extension")

  if (!column %in% valid)
    stop(
      "`column` must be one of: ", paste(valid, collapse = ", "),
      call. = FALSE
    )

  tidyr::separate_longer_delim(gaf, cols = dplyr::all_of(column), delim = "|")
}


#' Extract the primary database accession as a CURIE
#'
#' Combines \code{db} and \code{db_object_id} into a CURIE-style identifier
#' such as \code{"UniProtKB:P12345"}.  This is the format used in the semsql
#' \code{gene_go_edge} schema for the \code{subject} column.
#'
#' @param gaf a tibble as returned by \code{\link{parse_gaf}}.
#'
#' @return \code{gaf} with an additional \code{subject_curie} column prepended.
#'
#' @examples
#' gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
#' gaf <- parse_gaf(gaf_path)
#' gaf_add_subject_curie(gaf)
#'
#' @export
gaf_add_subject_curie <- function(gaf) {
  gaf$subject_curie <- paste0(gaf$db, ":", gaf$db_object_id)
  gaf[, c("subject_curie", setdiff(colnames(gaf), "subject_curie"))]
}


#' Summarise annotation counts by evidence code
#'
#' Returns a summary tibble showing how many annotations exist per
#' evidence code, sorted by descending count.  Useful for a quick
#' quality check after parsing.
#'
#' @param gaf a tibble as returned by \code{\link{parse_gaf}}.
#'
#' @return a tibble with columns \code{evidence_code}, \code{n},
#'   \code{experimental} (logical).
#'
#' @examples
#' gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
#' gaf <- parse_gaf(gaf_path)
#' gaf_evidence_summary(gaf)
#'
#' @export
gaf_evidence_summary <- function(gaf) {
  gaf |>
    dplyr::count(evidence_code, sort = TRUE) |>
    dplyr::mutate(
      experimental = evidence_code %in% GAF_EVIDENCE_EXPERIMENTAL
    )
}


#' Summarise annotation counts by aspect and evidence type
#'
#' Convenience cross-tabulation of ontology aspect (BP/MF/CC) against
#' broad evidence category (experimental vs computational vs other).
#'
#' @param gaf a tibble as returned by \code{\link{parse_gaf}}.
#'
#' @return a tibble with columns \code{aspect}, \code{evidence_category},
#'   \code{n}.
#'
#' @examples
#' gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
#' gaf <- parse_gaf(gaf_path)
#' gaf_aspect_summary(gaf)
#'
#' @export
gaf_aspect_summary <- function(gaf) {
  gaf |>
    dplyr::mutate(
      evidence_category = dplyr::case_when(
        evidence_code %in% GAF_EVIDENCE_EXPERIMENTAL   ~ "experimental",
        evidence_code %in% GAF_EVIDENCE_COMPUTATIONAL  ~ "computational",
        TRUE                                           ~ "other"
      )
    ) |>
    dplyr::count(aspect, evidence_category, sort = FALSE) |>
    dplyr::arrange(aspect, evidence_category)
}


#' Filter to interacting-taxon annotations
#'
#' Returns only rows where a second (interacting) taxon is present in
#' column 13 — i.e., host-pathogen annotations such as human gene products
#' annotated in the context of SARS-CoV-2, HIV-1, or bacterial infection.
#' These are excluded from most standard enrichment workflows but may be
#' of specific interest for immunology or infectious disease research.
#'
#' @param gaf a tibble as returned by \code{\link{parse_gaf}}.
#'
#' @return a tibble, subset of \code{gaf}.
#'
#' @examples
#' gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
#' gaf <- parse_gaf(gaf_path)
#' gaf_interspecies(gaf)
#'
#' @export
gaf_interspecies <- function(gaf) {
  gaf[!is.na(gaf$taxon_interactor), ]
}


#' Convert a parsed GAF tibble to semsql term_association format
#'
#' Transforms the output of \code{\link{parse_gaf}} into the column
#' structure of the semsql \code{term_association} table, suitable for
#' writing to parquet and loading into a GO.ddb-compatible DuckDB
#' connection.
#'
#' The mapping is:
#' \tabular{ll}{
#'   \code{subject}       \tab \code{db:db_object_id} CURIE \cr
#'   \code{predicate}     \tab \code{ro_predicate} derived from Aspect \cr
#'   \code{object}        \tab \code{go_id} \cr
#'   \code{evidence_type} \tab \code{evidence_code} \cr
#'   \code{publication}   \tab first pipe-separated \code{db_reference} \cr
#'   \code{source}        \tab \code{assigned_by} \cr
#' }
#'
#' Additionally retains \code{taxon_subject}, \code{taxon_interactor},
#' \code{db_object_symbol}, and \code{db_object_type} as extended columns
#' not in the minimal semsql schema but useful for downstream analysis.
#'
#' @param gaf a tibble as returned by \code{\link{parse_gaf}}.
#'
#' @return a tibble in semsql term_association column order, ready for
#'   \code{arrow::write_parquet()} or DuckDB ingestion.
#'
#' @examples
#' gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
#' gaf <- parse_gaf(gaf_path)
#' gaf_to_term_association(gaf)
#'
#' @seealso \code{\link{parse_gaf}}, \code{\link[arrow]{write_parquet}}
#'
#' @export
gaf_to_term_association <- function(gaf) {
  tibble::tibble(
    # Core semsql term_association columns
    subject        = paste0(gaf$db, ":", gaf$db_object_id),
    predicate      = gaf$ro_predicate,
    object         = gaf$go_id,
    evidence_type  = gaf$evidence_code,
    publication    = sub("\\|.*$", "", gaf$db_reference),  # first ref only
    source         = gaf$assigned_by,
    # Extended columns retained for downstream use
    symbol              = gaf$db_object_symbol,
    db_object_type      = gaf$db_object_type,
    taxon_subject       = gaf$taxon_subject,
    taxon_interactor    = gaf$taxon_interactor,
    qualifier           = gaf$qualifier,
    date                = gaf$date,
    annotation_extension     = gaf$annotation_extension,
    gene_product_form_id     = gaf$gene_product_form_id
  )
}
