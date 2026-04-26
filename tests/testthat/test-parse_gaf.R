# test-parse_gaf.R — parse_gaf() and column constants

gaf_path <- function()
  system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")

# ── Input validation ──────────────────────────────────────────────────────────

test_that("parse_gaf() errors on missing file", {
  expect_error(
    GOAnno4Bioc::parse_gaf("/nonexistent/path.gaf.gz"),
    "File not found"
  )
})

test_that("parse_gaf() errors on non-character path", {
  expect_error(GOAnno4Bioc::parse_gaf(123L), "single non-empty string")
})

test_that("parse_gaf() errors on invalid filter_taxon", {
  expect_error(
    GOAnno4Bioc::parse_gaf(gaf_path(), filter_taxon = c(9606L, 10090L)),
    "single integer"
  )
})

test_that("parse_gaf() errors on empty evidence_codes", {
  expect_error(
    GOAnno4Bioc::parse_gaf(gaf_path(), evidence_codes = character(0)),
    "non-empty character vector"
  )
})

# ── Return type and structure ─────────────────────────────────────────────────

test_that("parse_gaf() returns a tibble", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_s3_class(gaf, "tbl_df")
})

test_that("parse_gaf() has 20 columns", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_equal(ncol(gaf), 20L)
})

test_that("parse_gaf() contains all expected columns", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_true(all(GOAnno4Bioc::GAF_COLUMNS %in% colnames(gaf)))
  expect_true("ro_predicate"     %in% colnames(gaf))
  expect_true("taxon_subject"    %in% colnames(gaf))
  expect_true("taxon_interactor" %in% colnames(gaf))
})

test_that("parse_gaf() date column is Date class", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_s3_class(gaf$date, "Date")
})

test_that("parse_gaf() taxon_subject is integer", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_type(gaf$taxon_subject, "integer")
})

# ── qualifier NA handling ─────────────────────────────────────────────────────
# GAF uses a literal space in empty qualifier fields, not an empty string.
# trimws() + na_if("") must correctly convert both to NA.

test_that("parse_gaf() qualifier is NA not space for unannotated rows", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path(), filter_not = FALSE)
  non_not <- gaf[is.na(gaf$qualifier) | gaf$qualifier != "NOT", ]
  expect_true(all(is.na(non_not$qualifier)))
})

# ── Content correctness ───────────────────────────────────────────────────────

test_that("parse_gaf() go_id values have GO: prefix", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_true(all(startsWith(gaf$go_id, "GO:")))
})

test_that("parse_gaf() aspect values are P, F, or C", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_true(all(gaf$aspect %in% c("P", "F", "C")))
})

test_that("parse_gaf() ro_predicate values are valid RO CURIEs", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_true(all(gaf$ro_predicate %in%
    unname(GOAnno4Bioc::GAF_ASPECT_TO_RO)))
})

test_that("parse_gaf() ro_predicate is consistent with aspect", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_equal(
    gaf$ro_predicate,
    unname(GOAnno4Bioc::GAF_ASPECT_TO_RO[gaf$aspect])
  )
})

test_that("parse_gaf() taxon_subject is 9606 for all human rows", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  human_rows <- gaf[is.na(gaf$taxon_interactor), ]
  expect_true(all(human_rows$taxon_subject == 9606L))
})

test_that("parse_gaf() correctly parses interacting taxon", {
  gaf   <- GOAnno4Bioc::parse_gaf(gaf_path(), filter_not = FALSE)
  inter <- gaf[!is.na(gaf$taxon_interactor), ]
  # IRAK4 row has taxon:9606|taxon:11676 (HIV-1)
  expect_gt(nrow(inter), 0L)
  expect_true(all(inter$taxon_interactor == 11676L))
})

test_that("parse_gaf() db_reference retains pipes before expansion", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  # At least one row should have a pipe-separated db_reference
  expect_true(any(grepl("|", gaf$db_reference, fixed = TRUE)))
})

test_that("parse_gaf() with_or_from retains pipes before expansion", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  non_na <- gaf$with_or_from[!is.na(gaf$with_or_from)]
  expect_true(any(grepl("|", non_na, fixed = TRUE)))
})

# ── filter_not ────────────────────────────────────────────────────────────────

test_that("parse_gaf() excludes NOT annotations by default", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path())
  expect_true(all(is.na(gaf$qualifier) | gaf$qualifier != "NOT"))
})

test_that("parse_gaf(filter_not=FALSE) retains NOT annotations", {
  gaf_all  <- GOAnno4Bioc::parse_gaf(gaf_path(), filter_not = FALSE)
  gaf_filt <- GOAnno4Bioc::parse_gaf(gaf_path(), filter_not = TRUE)
  expect_gt(nrow(gaf_all), nrow(gaf_filt))
  expect_true(any(gaf_all$qualifier == "NOT", na.rm = TRUE))
})

# ── filter_taxon ──────────────────────────────────────────────────────────────

test_that("parse_gaf(filter_taxon=9606) keeps only primary human rows", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path(), filter_taxon = 9606L)
  expect_true(all(gaf$taxon_subject == 9606L))
})

test_that("parse_gaf(filter_taxon=9999) returns zero rows", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path(), filter_taxon = 9999L)
  expect_equal(nrow(gaf), 0L)
})

# ── evidence_codes ────────────────────────────────────────────────────────────

test_that("parse_gaf(evidence_codes) filters correctly", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path(),
    evidence_codes = GOAnno4Bioc::GAF_EVIDENCE_EXPERIMENTAL)
  expect_true(all(
    gaf$evidence_code %in% GOAnno4Bioc::GAF_EVIDENCE_EXPERIMENTAL
  ))
})

test_that("parse_gaf() IEA-only filter works", {
  gaf <- GOAnno4Bioc::parse_gaf(gaf_path(), evidence_codes = "IEA")
  expect_true(all(gaf$evidence_code == "IEA"))
  expect_gt(nrow(gaf), 0L)
})

# ── GAF_COLUMNS constant ──────────────────────────────────────────────────────

test_that("GAF_COLUMNS has 17 elements", {
  expect_length(GOAnno4Bioc::GAF_COLUMNS, 17L)
})

test_that("GAF_COLUMNS is a character vector with no NAs", {
  expect_type(GOAnno4Bioc::GAF_COLUMNS, "character")
  expect_false(anyNA(GOAnno4Bioc::GAF_COLUMNS))
})

# ── GAF_ASPECT_TO_RO constant ─────────────────────────────────────────────────

test_that("GAF_ASPECT_TO_RO maps all three aspects", {
  expect_setequal(names(GOAnno4Bioc::GAF_ASPECT_TO_RO), c("P", "F", "C"))
})

test_that("GAF_ASPECT_TO_RO values are valid RO CURIEs", {
  expect_true(all(startsWith(
    unname(GOAnno4Bioc::GAF_ASPECT_TO_RO), "RO:"
  )))
})
