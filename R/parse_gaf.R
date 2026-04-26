# parse_gaf.R — core GAF 2.x parsing

#' Parse a GAF 2.x annotation file into a tibble
#'
#' Reads a GAF (Gene Association Format) file — plain or gzip-compressed —
#' and returns a tibble with one row per annotation.  Both GAF 2.1 and 2.2
#' are supported.  The optional columns 16 (\code{annotation_extension})
#' and 17 (\code{gene_product_form_id}) are included when present.
#'
#' @section Column descriptions:
#' \describe{
#'   \item{db}{Source database, e.g. \code{"UniProtKB"}}
#'   \item{db_object_id}{Accession in source db, e.g. \code{"P12345"}}
#'   \item{db_object_symbol}{Gene symbol, e.g. \code{"IL6"}}
#'   \item{qualifier}{Annotation qualifier: \code{NA}, \code{"NOT"},
#'     \code{"contributes_to"}, or \code{"colocalizes_with"}}
#'   \item{go_id}{GO CURIE, e.g. \code{"GO:0006954"}}
#'   \item{db_reference}{Pipe-separated references, e.g.
#'     \code{"PMID:12345678|PMID:23456789"}}
#'   \item{evidence_code}{GAF evidence code, e.g. \code{"IEA"}}
#'   \item{with_or_from}{Pipe-separated supporting identifiers; \code{NA}
#'     if absent}
#'   \item{aspect}{Single character: \code{"P"} (BP), \code{"F"} (MF),
#'     \code{"C"} (CC)}
#'   \item{db_object_name}{Full name of annotated entity}
#'   \item{db_object_synonym}{Pipe-separated synonyms; \code{NA} if absent}
#'   \item{db_object_type}{Entity type, e.g. \code{"protein"}}
#'   \item{taxon}{Raw taxon field, e.g. \code{"taxon:9606"} or
#'     \code{"taxon:9606|taxon:562"} for interacting-taxon annotations}
#'   \item{taxon_subject}{Primary taxon NCBI ID as integer, e.g. \code{9606L}}
#'   \item{taxon_interactor}{Interacting organism NCBI ID, or \code{NA}
#'     for single-taxon annotations}
#'   \item{date}{Annotation date as \code{Date}}
#'   \item{assigned_by}{Database that created the annotation}
#'   \item{annotation_extension}{Optional RO-based annotation extensions;
#'     \code{NA} if absent}
#'   \item{gene_product_form_id}{Optional isoform identifier; \code{NA}
#'     if absent}
#'   \item{ro_predicate}{RO predicate CURIE derived from \code{aspect}:
#'     \code{"RO:0002331"} (BP/involved_in), \code{"RO:0002327"}
#'     (MF/enables), \code{"RO:0001025"} (CC/located_in).
#'     See \code{\link{GAF_ASPECT_TO_RO}} for the full mapping rationale.}
#' }
#'
#' @section Pipe-separated fields:
#' Several columns contain pipe-separated multi-value fields:
#' \code{db_reference}, \code{with_or_from}, \code{db_object_synonym},
#' and \code{annotation_extension}.  These are retained as character
#' strings in the returned tibble.  Use \code{\link{gaf_expand_column}}
#' to unnest a specific column into long format.
#'
#' @param path character scalar.  Path to a GAF file (\code{.gaf},
#'   \code{.gaf.gz}, or any readable connection).
#' @param filter_not logical.  If \code{TRUE} (default), rows where
#'   \code{qualifier} is \code{"NOT"} are excluded.  NOT annotations
#'   assert that a gene product is explicitly \emph{not} involved in
#'   the GO term and should usually be excluded from enrichment analyses.
#' @param filter_taxon integer or \code{NULL}.  If non-\code{NULL}, only
#'   rows whose primary taxon matches this NCBI taxon ID are returned.
#'   Default \code{NULL} retains all taxa.
#' @param evidence_codes character vector or \code{NULL}.  If non-\code{NULL},
#'   only rows whose \code{evidence_code} is in this vector are returned.
#'   See \code{\link{GAF_EVIDENCE_EXPERIMENTAL}} and
#'   \code{\link{GAF_EVIDENCE_COMPUTATIONAL}} for curated sets.
#'   Default \code{NULL} retains all evidence codes.
#'
#' @return a \code{\link[tibble]{tibble}} with 20 columns as described
#'   above.
#'
#' @examples
#' gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
#' gaf <- parse_gaf(gaf_path)
#' gaf
#'
#' # Experimental evidence only
#' parse_gaf(gaf_path, evidence_codes = GAF_EVIDENCE_EXPERIMENTAL)
#'
#' # Human annotations only
#' parse_gaf(gaf_path, filter_taxon = 9606L)
#'
#' @seealso \code{\link{gaf_expand_column}}, \code{\link{gaf_to_term_association}},
#'   \code{\link{GAF_COLUMNS}}, \code{\link{GAF_ASPECT_TO_RO}}
#'
#' @export
parse_gaf <- function(path,
                      filter_not     = TRUE,
                      filter_taxon   = NULL,
                      evidence_codes = NULL) {

  if (!is.character(path) || length(path) != 1L || nchar(path) == 0L)
    stop("`path` must be a single non-empty string.", call. = FALSE)
  if (!file.exists(path))
    stop("File not found: ", path, call. = FALSE)

  # ── Read raw lines, skipping comment/header lines beginning with '!' ────────
  con <- if (grepl("\\.gz$", path, ignore.case = TRUE)) {
    gzcon(file(path, open = "rb"))
  } else {
    file(path, open = "r")
  }
  on.exit(close(con), add = TRUE)

  lines <- readLines(con, warn = FALSE)
  lines <- lines[!startsWith(lines, "!")]
  lines <- lines[nchar(trimws(lines)) > 0L]

  if (length(lines) == 0L)
    stop("No annotation lines found in: ", path, call. = FALSE)

  # ── Parse tab-separated fields ───────────────────────────────────────────────
  fields <- strsplit(lines, "\t", fixed = TRUE)
  n_cols <- lengths(fields)

  bad <- which(n_cols < 15L)
  if (length(bad) > 0L)
    warning(
      length(bad), " line(s) have fewer than 15 columns and will be dropped.",
      call. = FALSE
    )
  fields <- fields[n_cols >= 15L]

  # Pad to 17 columns for GAF 2.1 files lacking optional columns 16-17
  fields <- lapply(fields, function(x) {
    length(x) <- 17L
    x
  })

  # ── Assemble tibble ──────────────────────────────────────────────────────────
  mat <- do.call(rbind, fields)
  colnames(mat) <- GAF_COLUMNS

  raw <- tibble::as_tibble(mat)

  # ── Type coercion ────────────────────────────────────────────────────────────

  # Trim whitespace then convert empty strings → NA for optional fields.
  # trimws() is essential: GAF files use a literal space in empty fields,
  # so na_if("") alone would leave " " values rather than NA.
  optional_cols <- c(
    "qualifier", "with_or_from", "db_object_synonym",
    "annotation_extension", "gene_product_form_id"
  )
  for (col in optional_cols)
    raw[[col]] <- dplyr::na_if(trimws(raw[[col]]), "")

  # Date: YYYYMMDD → Date
  raw$date <- as.Date(raw$date, format = "%Y%m%d")

  # ── Taxon parsing ────────────────────────────────────────────────────────────
  # Column 13 is either "taxon:9606" or "taxon:9606|taxon:562"
  # (the latter for host-pathogen interacting-taxon annotations).
  taxon_split          <- strsplit(raw$taxon, "|", fixed = TRUE)
  raw$taxon_subject    <- .parse_taxon_id(
    vapply(taxon_split, `[`, character(1), 1)
  )
  raw$taxon_interactor <- .parse_taxon_id(
    vapply(taxon_split,
           function(x) if (length(x) >= 2L) x[[2L]] else NA_character_,
           character(1))
  )

  # ── RO predicate from Aspect ─────────────────────────────────────────────────
  raw$ro_predicate <- unname(GAF_ASPECT_TO_RO[raw$aspect])

  bad_aspect <- is.na(raw$ro_predicate) & !is.na(raw$aspect)
  if (any(bad_aspect))
    warning(
      sum(bad_aspect),
      " row(s) have unrecognised Aspect values and will have NA ro_predicate: ",
      paste(unique(raw$aspect[bad_aspect]), collapse = ", "),
      call. = FALSE
    )

  # ── Filtering ────────────────────────────────────────────────────────────────
  if (filter_not)
    raw <- raw[is.na(raw$qualifier) | raw$qualifier != "NOT", ]

  if (!is.null(filter_taxon)) {
    if (!is.numeric(filter_taxon) || length(filter_taxon) != 1L)
      stop("`filter_taxon` must be a single integer NCBI taxon ID.",
           call. = FALSE)
    raw <- raw[!is.na(raw$taxon_subject) &
               raw$taxon_subject == as.integer(filter_taxon), ]
  }

  if (!is.null(evidence_codes)) {
    if (!is.character(evidence_codes) || length(evidence_codes) == 0L)
      stop("`evidence_codes` must be a non-empty character vector.",
           call. = FALSE)
    raw <- raw[raw$evidence_code %in% evidence_codes, ]
  }

  # ── Column ordering ──────────────────────────────────────────────────────────
  raw[, c(
    "db", "db_object_id", "db_object_symbol",
    "qualifier", "go_id",
    "db_reference", "evidence_code", "with_or_from",
    "aspect", "ro_predicate",
    "db_object_name", "db_object_synonym", "db_object_type",
    "taxon", "taxon_subject", "taxon_interactor",
    "date", "assigned_by",
    "annotation_extension", "gene_product_form_id"
  )]
}


# ── Internal helpers ──────────────────────────────────────────────────────────

# Extract integer NCBI taxon ID from "taxon:9606" strings.
# Returns NA_integer_ for missing or malformed entries.
.parse_taxon_id <- function(x) {
  ids <- sub("^taxon:", "", x, ignore.case = TRUE)
  suppressWarnings(as.integer(ids))
}
