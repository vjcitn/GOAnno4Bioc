# gaf_cache.R — BiocFileCache-managed retrieval of GAF files
#
# Species URL table is static, with filenames verified against:
#   - goa_yeast.gaf.gz: Biopython UniProt.GOA documentation
#   - goa_cow.gaf.gz: geneontology/helpdesk GitHub discussion #346
#   - mgi.gaf.gz (mouse), rgd.gaf.gz (rat), fb.gaf.gz (fly),
#     wb.gaf.gz (worm), zfin.gaf.gz (zebrafish): GOC downloads page
#   - tair.gaf.gz (arabidopsis), goa_chicken, dictybase, goa_dog,
#     goa_pig: EBI GOA FTP directory structure
#
# If a URL proves stale, pass the corrected URL directly to
# gaf_cache(url = "...") or override just the filename via
# gaf_cache(species, gaf_file = "correct_name.gaf.gz").
#
# NOTE: current_release_numbers.txt on the EBI FTP does not contain
# filenames — its format is not suitable for dynamic URL discovery.
# The static table below is the correct approach.

.GOA_FTP_BASE <- "https://ftp.ebi.ac.uk/pub/databases/GO/goa"

# Verified static species table.
# UNIPROT (goa_uniprot_all.gaf.gz, ~5GB) and PDB are intentionally
# omitted as they are not species-specific; supply their URLs directly
# to gaf_cache(url = "...").
.GAF_SPECIES <- data.frame(
  species   = c(
    "arabidopsis", "chicken",  "cow",    "dicty",
    "dog",         "fly",      "human",  "mouse",
    "pig",         "rat",      "worm",   "yeast",
    "zebrafish"
  ),
  directory = c(
    "ARABIDOPSIS", "CHICKEN",  "COW",    "DICTY",
    "DOG",         "FLY",      "HUMAN",  "MOUSE",
    "PIG",         "RAT",      "WORM",   "YEAST",
    "ZEBRAFISH"
  ),
  filename  = c(
    "tair.gaf.gz",       "goa_chicken.gaf.gz", "goa_cow.gaf.gz",
    "dictybase.gaf.gz",  "goa_dog.gaf.gz",     "fb.gaf.gz",
    "goa_human.gaf.gz",  "mgi.gaf.gz",
    "goa_pig.gaf.gz",    "rgd.gaf.gz",          "wb.gaf.gz",
    "goa_yeast.gaf.gz",  "zfin.gaf.gz"
  ),
  taxon_id  = c(
    3702L,   9031L,  9913L,  44689L,
    9615L,   7227L,  9606L,  10090L,
    9823L,  10116L,  6239L,  559292L,
    7955L
  ),
  stringsAsFactors = FALSE
)


#' List species with known GAF download URLs
#'
#' Returns a data frame of species for which EBI GOA distributes a
#' named species-specific GAF file, with their resolved download URLs
#' and primary NCBI taxon IDs.
#'
#' The all-species UniProt file
#' (\code{UNIPROT/goa_uniprot_all.gaf.gz}, ~5 GB) and the PDB file
#' are not included as they are not species-specific; supply their URLs
#' directly to \code{\link{gaf_cache}}.
#'
#' If a URL in this table is stale (EBI occasionally renames files),
#' use \code{gaf_cache(species, gaf_file = "new_name.gaf.gz")} or
#' \code{gaf_cache(url = "https://...")}.
#'
#' @return a data frame with columns \code{species}, \code{directory},
#'   \code{filename}, \code{taxon_id}, \code{url}.
#'
#' @examples
#' gaf_known_species()
#'
#' @export
gaf_known_species <- function() {
  df     <- .GAF_SPECIES
  df$url <- paste0(.GOA_FTP_BASE, "/", df$directory, "/", df$filename)
  df[, c("species", "directory", "filename", "taxon_id", "url")]
}


#' Retrieve and cache a GAF file via BiocFileCache
#'
#' Downloads a GAF file for the specified species from the EBI GOA FTP
#' and caches it locally using \code{BiocFileCache}.  On subsequent
#' calls the cached file is returned without re-downloading (unless
#' \code{force = TRUE}).
#'
#' @param species character scalar matching a \code{species} value from
#'   \code{\link{gaf_known_species}}, e.g. \code{"human"}, \code{"mouse"}.
#'   Case-insensitive.  Ignored if \code{url} is supplied.
#' @param url character scalar.  A fully-resolved GAF URL.  Used when
#'   \code{species} is \code{NULL} or to override the static URL for a
#'   known species.
#' @param gaf_file character scalar.  Override just the filename within
#'   the species FTP directory, e.g. \code{"goa_human.gaf.gz"}.  Useful
#'   when EBI renames the standard file without changing the directory.
#'   Only used when \code{species} is supplied and \code{url} is
#'   \code{NULL}.
#' @param force logical.  Re-download even if a cached copy exists.
#'   Default \code{FALSE}.
#'
#' @return the local file path to the cached \code{.gaf.gz} file,
#'   suitable for passing to \code{\link{parse_gaf}}.
#'
#' @examples
#' path <- gaf_cache("human")
#' parse_gaf(path, filter_taxon = 9606L)
#'
#' # Override filename if EBI has renamed the file
#' path <- gaf_cache("human", gaf_file = "goa_human.gaf.gz")
#'
#' # Supply a fully custom URL
#' path <- gaf_cache(
#'   url = paste0(
#'     "https://ftp.ebi.ac.uk/pub/databases/GO/goa/",
#'     "HUMAN/goa_human.gaf.gz"
#'   )
#' )
#'
#' @seealso \code{\link{parse_gaf}}, \code{\link{gaf_known_species}},
#'   \code{\link{get_gaf}}
#'
#' @export
gaf_cache <- function(species  = NULL,
                      url      = NULL,
                      gaf_file = NULL,
                      force    = FALSE) {
  if (is.null(species) && is.null(url))
    stop("Supply either `species` or `url`.", call. = FALSE)

  if (!is.null(species) && is.null(url)) {
    known <- gaf_known_species()
    idx   <- match(tolower(trimws(species)), tolower(known$species))

    if (is.na(idx))
      stop(
        "Unknown species '", species, "'.\n",
        "Available: ", paste(known$species, collapse = ", "), "\n",
        "Or supply a custom URL via gaf_cache(url = '...').",
        call. = FALSE
      )

    if (!is.null(gaf_file)) {
      url <- paste0(
        .GOA_FTP_BASE, "/", known$directory[[idx]], "/", gaf_file
      )
    } else {
      url <- known$url[[idx]]
    }
  }

  bfc  <- BiocFileCache::BiocFileCache(ask = FALSE)
  hits <- BiocFileCache::bfcquery(bfc, url, field = "fpath", exact = TRUE)

  if (nrow(hits) > 0L && !force) {
    path <- unname(BiocFileCache::bfcrpath(bfc, rids = hits$rid))
    message("Using cached GAF: ", path)
    return(path)
  }

  message("Downloading GAF from: ", url)
  unname(BiocFileCache::bfcadd(bfc, rname = url, fpath = url))
}


#' Parse a species GAF file in one step
#'
#' Convenience wrapper combining \code{\link{gaf_cache}} and
#' \code{\link{parse_gaf}}.
#'
#' @param species character scalar, e.g. \code{"human"}, \code{"mouse"}.
#' @param ... additional arguments passed to \code{\link{parse_gaf}},
#'   e.g. \code{filter_not}, \code{evidence_codes}, \code{filter_taxon}.
#' @param force logical passed to \code{\link{gaf_cache}}.
#'
#' @return a tibble as returned by \code{\link{parse_gaf}}.
#'
#' @examples
#' gaf <- get_gaf("human", filter_taxon = 9606L,
#'                evidence_codes = GAF_EVIDENCE_EXPERIMENTAL)
#' gaf
#'
#' @export
get_gaf <- function(species, ..., force = FALSE) {
  path <- gaf_cache(species = species, force = force)
  parse_gaf(path, ...)
}
