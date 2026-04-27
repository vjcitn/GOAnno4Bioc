# gaf_parquet.R — parquet cache management and lazy tbl access for GAF data
#
# Workflow:
#   1. gaf_cache("human")          — download/cache the .gaf.gz via BiocFileCache
#   2. build_gaf_parquet("human")  — convert to parquet (one-time, ~seconds)
#   3. gaf_tbl("human")            — lazy tbl_duckdb for dplyr composition
#   4. get_gaf("human", ...)       — eager tibble (auto-selects parquet if present)
#
# The parquet file is stored alongside the gaf.gz in a subdirectory of the
# BiocFileCache root, one file per species.

#' Directory for parquet-converted GAF files
#'
#' @keywords internal
.gaf_parquet_dir <- function() {
  bfc  <- BiocFileCache::BiocFileCache(ask = FALSE)
  root <- BiocFileCache::bfccache(bfc)
  d    <- file.path(root, "gaf_parquet")
  if (!dir.exists(d))
    dir.create(d, recursive = TRUE)
  d
}

#' Path to the parquet file for a given species
#'
#' @keywords internal
.gaf_parquet_path <- function(species) {
  file.path(.gaf_parquet_dir(), paste0(tolower(species), ".parquet"))
}

# SQL column name list for DuckDB read_csv column_names parameter.
# GAF has 17 columns; DuckDB needs them quoted as SQL strings.
.gaf_column_names_sql <- function() {
  paste(
    sprintf("'%s'", GAF_COLUMNS),
    collapse = ", "
  )
}

# DuckDB column type overrides — all character to preserve raw GAF values.
# Derived columns (date parsing, taxon splitting, ro_predicate) are added
# by .enrich_gaf_tbl() after reading.
.gaf_column_types_sql <- function() {
  paste(
    sprintf("'%s': 'VARCHAR'", GAF_COLUMNS),
    collapse = ", "
  )
}


#' Test whether a parquet cache exists for a species
#'
#' @param species character scalar, e.g. \code{"human"}.
#' @return logical scalar.
#'
#' @examples
#' has_gaf_parquet("human")
#'
#' @export
has_gaf_parquet <- function(species = "human") {
  file.exists(.gaf_parquet_path(species))
}


#' Convert a species GAF file to parquet
#'
#' Reads the cached \code{.gaf.gz} file via DuckDB (which handles gzip
#' decompression and TSV parsing natively) and writes a ZSTD-compressed
#' parquet file.  This is a one-time operation per species per release —
#' subsequent calls to \code{\link{gaf_tbl}} and \code{\link{get_gaf}}
#' use the parquet file directly without touching the \code{.gaf.gz}.
#'
#' Comment lines beginning with \code{!} are filtered out during
#' conversion.  All 17 GAF columns are stored as VARCHAR in the parquet
#' file; derived columns (\code{taxon_subject}, \code{taxon_interactor},
#' \code{ro_predicate}, \code{date}) are computed at query time by
#' \code{\link{gaf_tbl}}.
#'
#' @param species character scalar matching a \code{species} value from
#'   \code{\link{gaf_known_species}}, e.g. \code{"human"}, \code{"mouse"}.
#' @param force logical.  Rebuild even if a parquet file already exists.
#'   Default \code{FALSE}.
#'
#' @return the path to the parquet file, invisibly.
#'
#' @examples
#' if (!has_gaf_parquet("human")) {
#'   build_gaf_parquet("human")
#' }
#' has_gaf_parquet("human")
#'
#' @seealso \code{\link{gaf_tbl}}, \code{\link{get_gaf}},
#'   \code{\link{has_gaf_parquet}}
#'
#' @export
build_gaf_parquet <- function(species = "human", force = FALSE) {
  out_path <- .gaf_parquet_path(species)

  if (file.exists(out_path) && !force) {
    message("Parquet cache already exists: ", out_path,
            "\nUse force = TRUE to rebuild.")
    return(invisible(out_path))
  }

  # Ensure the .gaf.gz is available
  gaf_path <- gaf_cache(species = species)

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  message("Converting ", species, " GAF to parquet ...")
  t0 <- proc.time()[["elapsed"]]

  # DuckDB reads the gzipped TSV in one pass.
  # - column_names assigns the 17 GAF column names
  # - all columns typed VARCHAR to preserve raw values unchanged
  # - comment lines (starting with !) are filtered via WHERE
  # - ignore_errors skips any malformed lines rather than aborting
  sql <- sprintf(
    "COPY (
       SELECT * FROM read_csv(
         '%s',
         delim         = '\t',
         header        = false,
         compression   = 'gzip',
         column_names  = [%s],
         dtypes        = {%s},
         ignore_errors = true
       )
       WHERE db NOT LIKE '!%%'
     ) TO '%s'
     (FORMAT PARQUET, COMPRESSION ZSTD)",
    gaf_path,
    .gaf_column_names_sql(),
    .gaf_column_types_sql(),
    out_path
  )

  tryCatch(
    DBI::dbExecute(con, sql),
    error = function(e)
      stop("GAF parquet conversion failed: ", conditionMessage(e),
           call. = FALSE)
  )

  elapsed <- round(proc.time()[["elapsed"]] - t0, 1L)
  sz      <- file.size(out_path) / 1024^2
  n       <- DBI::dbGetQuery(
    con, sprintf("SELECT COUNT(*) AS n FROM '%s'", out_path)
  )$n

  message(sprintf(
    "  -> %s rows | %.1f MB | %.1fs",
    format(n, big.mark = ","), sz, elapsed
  ))
  invisible(out_path)
}


#' Lazy DuckDB tbl for a species GAF parquet file
#'
#' Returns a lazy \code{tbl_duckdb} backed by the parquet file for the
#' requested species.  dplyr verbs (\code{filter}, \code{select},
#' \code{count}, etc.) are translated to SQL and executed by DuckDB with
#' full predicate pushdown — only matching rows and columns are read from
#' disk.
#'
#' The returned tbl has all 17 raw GAF columns plus three derived columns
#' computed at query time:
#' \describe{
#'   \item{taxon_subject}{integer primary taxon NCBI ID}
#'   \item{taxon_interactor}{integer interacting taxon NCBI ID, or \code{NULL}}
#'   \item{ro_predicate}{RO CURIE derived from \code{aspect}}
#' }
#' Note that \code{date} remains VARCHAR in the parquet file and is not
#' coerced to \code{Date} until \code{collect()} is called and
#' post-processing is applied via \code{\link{gaf_collect}}.
#'
#' @param species character scalar, e.g. \code{"human"}, \code{"mouse"}.
#' @param con optional \code{DBIConnection} to an existing DuckDB instance.
#'   If \code{NULL} (default), a new in-memory DuckDB connection is opened.
#'   The caller is responsible for disconnecting if \code{con} is supplied.
#'
#' @return a lazy \code{tbl_duckdb}.
#'
#' @examples
#' if (has_gaf_parquet("human")) {
#'   gaf_tbl("human") |>
#'     dplyr::filter(db_object_symbol == "ORMDL3") |>
#'     dplyr::collect()
#' }
#'
#' @seealso \code{\link{build_gaf_parquet}}, \code{\link{gaf_collect}},
#'   \code{\link{get_gaf}}
#'
#' @export
gaf_tbl <- function(species = "human", con = NULL) {
  path <- .gaf_parquet_path(species)
  if (!file.exists(path))
    stop(
      "No parquet cache for species '", species, "'.\n",
      "Run build_gaf_parquet('", species, "') first.",
      call. = FALSE
    )

  owns_con <- is.null(con)
  if (owns_con)
    con <- DBI::dbConnect(duckdb::duckdb())

  # Attach parquet as a view so it is addressable by tbl()
  view_name <- paste0("gaf_", tolower(species))
  DBI::dbExecute(con, sprintf(
    "CREATE OR REPLACE VIEW %s AS
     SELECT
       *,
       -- taxon_subject: integer extracted from 'taxon:9606' or 'taxon:9606|taxon:562'
       TRY_CAST(
         regexp_extract(split_part(taxon, '|', 1), '[0-9]+', 0)
       AS INTEGER) AS taxon_subject,
       -- taxon_interactor: integer from second taxon if present, else NULL
       TRY_CAST(
         CASE WHEN regexp_matches(taxon, '[|]')
              THEN regexp_extract(split_part(taxon, '|', 2), '[0-9]+', 0)
              ELSE NULL
         END
       AS INTEGER) AS taxon_interactor,
       -- ro_predicate from aspect: P=involved_in, F=enables, C=located_in
       CASE aspect
         WHEN 'P' THEN 'RO:0002331'
         WHEN 'F' THEN 'RO:0002327'
         WHEN 'C' THEN 'RO:0001025'
         ELSE NULL
       END AS ro_predicate
     FROM read_parquet('%s')",
    view_name, path
  ))

  tbl <- dplyr::tbl(con, view_name)

  # Attach a finalizer to disconnect if we own the connection.
  # This runs when the tbl is garbage collected — not ideal, but avoids
  # leaking connections when gaf_tbl() is called interactively.
  # Users working programmatically should pass their own con and manage it.
  if (owns_con) {
    reg.finalizer(
      environment(attr(tbl, "src")$con),
      function(e) tryCatch(
        DBI::dbDisconnect(con, shutdown = TRUE),
        error = function(x) NULL
      ),
      onexit = TRUE
    )
  }

  tbl
}


#' Collect a GAF tbl into an R tibble with proper type coercion
#'
#' Calls \code{dplyr::collect()} on a lazy GAF tbl and applies
#' post-collection type conversions that cannot be expressed in SQL:
#' \code{date} is coerced from VARCHAR to \code{Date}, and empty
#' strings in optional columns are converted to \code{NA}.
#'
#' Accepts the same filtering arguments as \code{\link{parse_gaf}} so
#' the result is directly comparable regardless of which backend was used.
#'
#' @param tbl a lazy tbl as returned by \code{\link{gaf_tbl}}, optionally
#'   with dplyr verbs already applied.
#' @param filter_not logical.  Exclude NOT annotations.  Default \code{TRUE}.
#' @param filter_taxon integer or \code{NULL}.  Filter to primary taxon.
#' @param evidence_codes character vector or \code{NULL}.  Filter to
#'   specific evidence codes.
#'
#' @return a tibble equivalent to the output of \code{\link{parse_gaf}}.
#'
#' @examples
#' if (has_gaf_parquet("human")) {
#'   gaf_tbl("human") |>
#'     dplyr::filter(db_object_symbol == "ORMDL3") |>
#'     gaf_collect()
#' }
#'
#' @seealso \code{\link{gaf_tbl}}, \code{\link{parse_gaf}}
#'
#' @export
gaf_collect <- function(tbl,
                        filter_not     = TRUE,
                        filter_taxon   = NULL,
                        evidence_codes = NULL) {

  # Apply filters as lazy SQL before collect() — predicate pushdown
  if (filter_not)
    tbl <- tbl |>
      dplyr::filter(is.na(qualifier) | qualifier != "NOT")

  if (!is.null(filter_taxon)) {
    if (!is.numeric(filter_taxon) || length(filter_taxon) != 1L)
      stop("`filter_taxon` must be a single integer.", call. = FALSE)
    tbl <- tbl |>
      dplyr::filter(taxon_subject == as.integer(filter_taxon))
  }

  if (!is.null(evidence_codes)) {
    if (!is.character(evidence_codes) || length(evidence_codes) == 0L)
      stop("`evidence_codes` must be a non-empty character vector.",
           call. = FALSE)
    tbl <- tbl |>
      dplyr::filter(evidence_code %in% evidence_codes)
  }

  raw <- dplyr::collect(tbl)

  # Post-collection type coercions
  raw$date <- as.Date(raw$date, format = "%Y%m%d")

  optional_cols <- c(
    "qualifier", "with_or_from", "db_object_synonym",
    "annotation_extension", "gene_product_form_id"
  )
  for (col in intersect(optional_cols, colnames(raw)))
    raw[[col]] <- dplyr::na_if(trimws(raw[[col]]), "")

  tibble::as_tibble(raw)
}
