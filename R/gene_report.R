# gene_report.R — interactive gene annotation report via DT::datatable

#' Produce an interactive annotation report for a gene
#'
#' Takes a GAF tibble (as returned by \code{\link{parse_gaf}}) filtered
#' to a single gene, enriches it with GO term labels from GO.ddb, formats
#' PubMed references as HTML hyperlinks, and presents the result as an
#' interactive \code{\link[DT]{datatable}}.
#'
#' GO.ddb must have an active connection (via \code{GO.ddb::make_go_con()})
#' before calling this function.  If GO.ddb is not installed or no
#' connection is active, GO term labels are omitted with a warning and
#' raw GO IDs are shown instead.
#'
#' @param gaf a tibble as returned by \code{\link{parse_gaf}}, filtered
#'   to a single gene symbol.  If multiple symbols are present, only the
#'   first (alphabetically) is reported and a warning is issued.
#' @param symbol character scalar.  If supplied, \code{gaf} is filtered
#'   to this symbol before processing.  Ignored if \code{NULL} (default).
#' @param columns character vector of columns to include in the report.
#'   Default is a curated readable subset.  Use \code{"all"} to include
#'   every column.
#' @param pubmed_base character scalar.  Base URL for PubMed links.
#'   Default \code{"https://pubmed.ncbi.nlm.nih.gov/"}.
#' @param dt_options named list of additional options passed to
#'   \code{\link[DT]{datatable}} via its \code{options} argument.
#' @param ... additional arguments passed to \code{\link[DT]{datatable}}.
#'
#' @return a \code{datatables} object (invisibly) which renders as an
#'   interactive HTML table in RMarkdown, Shiny, or the RStudio viewer.
#'
#' @examples
#' gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
#' gaf <- parse_gaf(gaf_path)
#' gene_report(gaf, symbol = "IL6")
#'
#' @seealso \code{\link{parse_gaf}}, \code{\link[DT]{datatable}}
#'
#' @export
gene_report <- function(
    gaf,
    symbol     = NULL,
    columns    = c("go_id", "go_label", "qualifier", "aspect",
                   "evidence_code", "db_reference", "assigned_by", "date"),
    pubmed_base = "https://pubmed.ncbi.nlm.nih.gov/",
    dt_options  = list(pageLength = 20, scrollX = TRUE),
    ...) {

  # ── Filter to symbol if supplied ─────────────────────────────────────────────
  if (!is.null(symbol)) {
    if (!is.character(symbol) || length(symbol) != 1L)
      stop("`symbol` must be a single character string.", call. = FALSE)
    gaf <- gaf[gaf$db_object_symbol == symbol, ]
    if (nrow(gaf) == 0L)
      stop("No rows found for symbol '", symbol, "'.", call. = FALSE)
  }

  # Warn if multiple symbols are present
  symbols <- unique(gaf$db_object_symbol)
  if (length(symbols) > 1L) {
    warning(
      "Multiple gene symbols present: ",
      paste(sort(symbols), collapse = ", "),
      ". Filtering to '", sort(symbols)[[1L]], "'.",
      call. = FALSE
    )
    gaf <- gaf[gaf$db_object_symbol == sort(symbols)[[1L]], ]
  }

  gene_sym  <- unique(gaf$db_object_symbol)
  gene_name <- unique(gaf$db_object_name)[[1L]]

  # ── Fetch GO labels from GO.ddb ───────────────────────────────────────────────
  go_labels <- .fetch_go_labels(unique(gaf$go_id))

  # ── Merge labels into gaf ─────────────────────────────────────────────────────
  gaf <- merge(
    gaf,
    go_labels,
    by    = "go_id",
    all.x = TRUE,
    sort  = FALSE
  )

  # ── Format db_reference as PubMed hyperlinks ──────────────────────────────────
  gaf$db_reference <- .format_references(gaf$db_reference, pubmed_base)

  # ── Select and order columns ──────────────────────────────────────────────────
  if (identical(columns, "all")) {
    display_cols <- colnames(gaf)
  } else {
    # Keep only columns that exist — go_label may be absent if GO.ddb unavailable
    display_cols <- intersect(columns, colnames(gaf))
  }

  display <- gaf[, display_cols, drop = FALSE]

  # ── Render datatable ──────────────────────────────────────────────────────────
  caption <- sprintf(
    "GO annotations for %s (%s) &mdash; %d annotation(s)",
    gene_sym, gene_name, nrow(gaf)
  )

  dt <- DT::datatable(
    display,
    caption   = htmltools::HTML(caption),
    escape    = FALSE,         # allow HTML in db_reference and go_id columns
    rownames  = FALSE,
    filter    = "top",
    options   = dt_options,
    ...
  )

  invisible(dt)
}


# ── Internal helpers ──────────────────────────────────────────────────────────

# Fetch GO term labels from GO.ddb if available.
# Returns a data.frame with columns go_id and go_label.
# Falls back gracefully if GO.ddb is not installed or not connected.
.fetch_go_labels <- function(go_ids) {
  empty <- data.frame(
    go_id    = go_ids,
    go_label = NA_character_,
    stringsAsFactors = FALSE
  )

  if (!requireNamespace("GO.ddb", quietly = TRUE)) {
    warning(
      "GO.ddb is not installed — GO term labels will be omitted.\n",
      "Install GO.ddb and call GO.ddb::make_go_con() to enable labels.",
      call. = FALSE
    )
    return(empty)
  }

  if (!GO.ddb::go_connection_active()) {
    warning(
      "No active GO.ddb connection — GO term labels will be omitted.\n",
      "Call GO.ddb::make_go_con() before gene_report().",
      call. = FALSE
    )
    return(empty)
  }

  tryCatch({
    labels <- GO.ddb::lookup_curie(go_ids, mapto = "term") |>
      dplyr::collect()
    data.frame(
      go_id    = labels$id,
      go_label = labels$label,
      stringsAsFactors = FALSE
    )
  }, error = function(e) {
    warning(
      "GO label lookup failed: ", conditionMessage(e),
      " — GO term labels will be omitted.",
      call. = FALSE
    )
    empty
  })
}


# Format a db_reference string into HTML hyperlinks.
# Handles pipe-separated multiple references.
# Currently supports PMID: and GO_REF: prefixes.
.format_references <- function(refs, pubmed_base) {
  vapply(refs, function(ref) {
    if (is.na(ref)) return(NA_character_)

    parts <- strsplit(ref, "|", fixed = TRUE)[[1L]]

    links <- vapply(trimws(parts), function(r) {
      if (startsWith(r, "PMID:")) {
        pmid <- sub("^PMID:", "", r)
        sprintf(
          '<a href="%s%s" target="_blank">%s</a>',
          pubmed_base, pmid, r
        )
      } else if (startsWith(r, "GO_REF:")) {
        sprintf(
          '<a href="https://identifiers.org/%s" target="_blank">%s</a>',
          r, r   # r is already "GO_REF:0000033" — identifiers.org accepts this directly
        )
      } else {
        # Return unlinked for unrecognised prefixes (e.g. AGRICOLA:, CGD:)
        r
      }
    }, character(1L))

    paste(links, collapse = " | ")
  }, character(1L))
}
