# test-gene_report.R — gene_report() tests
#
# Most tests run without a live GO.ddb connection — they verify the
# structure and HTML formatting of the report.  Tests that check GO
# label enrichment are guarded by go_connection_active().

gaf_path <- function()
  system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")

gaf_fixture <- function()
  GOAnno4Bioc::parse_gaf(gaf_path(), filter_not = FALSE)

# ── Input validation ──────────────────────────────────────────────────────────

test_that("gene_report() errors on non-character symbol", {
  expect_error(
    GOAnno4Bioc::gene_report(gaf_fixture(), symbol = 123L),
    "single character string"
  )
})

test_that("gene_report() errors when symbol not found", {
  expect_error(
    GOAnno4Bioc::gene_report(gaf_fixture(), symbol = "NOTHERE"),
    "No rows found"
  )
})

test_that("gene_report() warns on multiple symbols", {
  gaf <- gaf_fixture()
  expect_warning(
    GOAnno4Bioc::gene_report(gaf),
    "Multiple gene symbols"
  )
})

# ── Return type ───────────────────────────────────────────────────────────────

test_that("gene_report() returns a datatables object invisibly", {
  testthat::skip_if_not_installed("DT")
  testthat::skip_if_not_installed("htmltools")
  result <- GOAnno4Bioc::gene_report(gaf_fixture(), symbol = "IL6")
  expect_s3_class(result, "datatables")
})

# ── Column selection ──────────────────────────────────────────────────────────

test_that("gene_report() default columns are present in output data", {
  testthat::skip_if_not_installed("DT")
  testthat::skip_if_not_installed("htmltools")
  result <- suppressWarnings(
    GOAnno4Bioc::gene_report(gaf_fixture(), symbol = "IL6")
  )
  # DT stores the data in result$x$data
  data_cols <- colnames(result$x$data)
  expect_true("go_id"         %in% data_cols)
  expect_true("evidence_code" %in% data_cols)
  expect_true("db_reference"  %in% data_cols)
})

test_that("gene_report(columns='all') includes all gaf columns", {
  testthat::skip_if_not_installed("DT")
  testthat::skip_if_not_installed("htmltools")
  result <- suppressWarnings(
    GOAnno4Bioc::gene_report(gaf_fixture(), symbol = "IL6", columns = "all")
  )
  data_cols <- colnames(result$x$data)
  expect_true("taxon_subject" %in% data_cols)
  expect_true("date"          %in% data_cols)
})

# ── PubMed link formatting ────────────────────────────────────────────────────

test_that(".format_references() produces href for PMID entries", {
  result <- GOAnno4Bioc:::.format_references(
    "PMID:2126852",
    "https://pubmed.ncbi.nlm.nih.gov/"
  )
  expect_true(grepl("href", result))
  expect_true(grepl("2126852", result))
  expect_true(grepl("pubmed", result))
})

test_that(".format_references() handles pipe-separated PMIDs", {
  result <- GOAnno4Bioc:::.format_references(
    "PMID:2126852|PMID:9843981",
    "https://pubmed.ncbi.nlm.nih.gov/"
  )
  expect_true(grepl("2126852", result))
  expect_true(grepl("9843981", result))
  # Both should be linked
  expect_equal(
    length(regmatches(result, gregexpr("href", result))[[1L]]),
    2L
  )
})

test_that(".format_references() handles GO_REF entries", {
  result <- GOAnno4Bioc:::.format_references(
    "GO_REF:0000033",
    "https://pubmed.ncbi.nlm.nih.gov/"
  )
  expect_true(grepl("href", result))
  expect_true(grepl("geneontology", result))
})

test_that(".format_references() passes through unrecognised prefixes", {
  result <- GOAnno4Bioc:::.format_references(
    "AGRICOLA:IND123",
    "https://pubmed.ncbi.nlm.nih.gov/"
  )
  expect_false(grepl("href", result))
  expect_true(grepl("AGRICOLA:IND123", result))
})

test_that(".format_references() returns NA for NA input", {
  result <- GOAnno4Bioc:::.format_references(
    NA_character_,
    "https://pubmed.ncbi.nlm.nih.gov/"
  )
  expect_true(is.na(result))
})

# ── GO label fallback ─────────────────────────────────────────────────────────

test_that(".fetch_go_labels() returns data frame with go_id and go_label", {
  result <- GOAnno4Bioc:::.fetch_go_labels("GO:0006954")
  expect_s3_class(result, "data.frame")
  expect_true("go_id"    %in% colnames(result))
  expect_true("go_label" %in% colnames(result))
})

test_that(".fetch_go_labels() returns NA labels when GO.ddb not connected", {
  # Disconnect if active, then check graceful fallback
  if (requireNamespace("GO.ddb", quietly = TRUE) &&
      GO.ddb::go_connection_active()) {
    testthat::skip("GO.ddb is connected — skipping fallback test")
  }
  result <- suppressWarnings(
    GOAnno4Bioc:::.fetch_go_labels("GO:0006954")
  )
  expect_true(is.na(result$go_label[[1L]]))
})

test_that("gene_report() warns gracefully when GO.ddb not connected", {
  testthat::skip_if_not_installed("DT")
  testthat::skip_if_not_installed("htmltools")
  if (requireNamespace("GO.ddb", quietly = TRUE) &&
      GO.ddb::go_connection_active()) {
    testthat::skip("GO.ddb is connected — skipping no-connection warning test")
  }
  expect_warning(
    GOAnno4Bioc::gene_report(gaf_fixture(), symbol = "IL6"),
    "GO.ddb"
  )
})

# ── GO label enrichment (requires live GO.ddb connection) ─────────────────────

test_that("gene_report() includes go_label column when GO.ddb is active", {
  testthat::skip_if_not_installed("DT")
  testthat::skip_if_not_installed("htmltools")
  testthat::skip_if_not_installed("GO.ddb")
  if (!GO.ddb::go_connection_active())
    testthat::skip("GO.ddb not connected")

  result <- GOAnno4Bioc::gene_report(gaf_fixture(), symbol = "IL6")
  data_cols <- colnames(result$x$data)
  expect_true("go_label" %in% data_cols)

  labels <- result$x$data$go_label
  expect_true(any(!is.na(labels)))
})
