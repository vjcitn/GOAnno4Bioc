# test-gaf_parquet.R — parquet cache and gaf_tbl() tests
#
# Tests are divided into two groups:
#   1. No-network tests that build a synthetic parquet from the mini fixture
#   2. Live parquet tests that skip unless a real species parquet exists
#
# The synthetic parquet is built into a temp directory so it does not
# pollute the real BiocFileCache.

# ── Shared synthetic parquet fixture ─────────────────────────────────────────

# Build a small parquet from the mini GAF fixture and return its path.
# Uses DuckDB directly so it does not depend on build_gaf_parquet() itself.
.make_test_parquet <- function() {
  testthat::skip_if_not_installed("duckdb")

  gaf_gz   <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
  out_path <- tempfile(fileext = ".parquet")

  col_names <- paste(
    sprintf("'%s'", GOAnno4Bioc::GAF_COLUMNS),
    collapse = ", "
  )
  col_types <- paste(
    sprintf("'%s': 'VARCHAR'", GOAnno4Bioc::GAF_COLUMNS),
    collapse = ", "
  )

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  DBI::dbExecute(con, sprintf(
    "COPY (
       SELECT * FROM read_csv(
         '%s',
         delim         = '\t',
         header        = false,
         compression   = 'gzip',
         comment       = '!',
         column_names  = [%s],
         types         = {%s},
         ignore_errors = true
       )
     ) TO '%s'
     (FORMAT PARQUET, COMPRESSION ZSTD)",
    gaf_gz, col_names, col_types, out_path
  ))

  out_path
}


# ── has_gaf_parquet ───────────────────────────────────────────────────────────

test_that("has_gaf_parquet() returns logical scalar", {
  result <- GOAnno4Bioc::has_gaf_parquet("human")
  expect_type(result, "logical")
  expect_length(result, 1L)
})

test_that("has_gaf_parquet() returns FALSE for nonexistent species", {
  expect_false(GOAnno4Bioc::has_gaf_parquet("klingon"))
})


# ── build_gaf_parquet ─────────────────────────────────────────────────────────

test_that("build_gaf_parquet() produces a readable parquet file", {
  testthat::skip_if_not_installed("duckdb")
  testthat::skip_if_not_installed("BiocFileCache")
  testthat::skip_on_ci()   # requires network to fetch gaf.gz

  path <- GOAnno4Bioc::build_gaf_parquet("human")
  expect_true(file.exists(path))
  expect_true(grepl("\\.parquet$", path))

  # Verify it is readable
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  n <- DBI::dbGetQuery(con,
    sprintf("SELECT COUNT(*) AS n FROM '%s'", path))$n
  expect_gt(n, 0L)
})


# ── Synthetic parquet tests ───────────────────────────────────────────────────

test_that("synthetic parquet has expected columns", {
  pq <- .make_test_parquet()

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  cols <- DBI::dbGetQuery(con,
    sprintf("DESCRIBE SELECT * FROM '%s'", pq))$column_name

  expect_true(all(GOAnno4Bioc::GAF_COLUMNS %in% cols))
})

test_that("synthetic parquet row count matches parse_gaf (filter_not=FALSE)", {
  pq <- .make_test_parquet()

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  n_parquet <- DBI::dbGetQuery(con,
    sprintf("SELECT COUNT(*) AS n FROM '%s'", pq))$n

  gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
  n_parse  <- nrow(GOAnno4Bioc::parse_gaf(gaf_path, filter_not = FALSE))

  expect_equal(n_parquet, n_parse)
})


# ── gaf_collect ───────────────────────────────────────────────────────────────

test_that("gaf_collect() returns a tibble", {
  testthat::skip_if_not_installed("duckdb")

  pq  <- .make_test_parquet()
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  DBI::dbExecute(con, sprintf(
    "CREATE VIEW test_gaf AS
     SELECT *,
       TRY_CAST(regexp_extract(split_part(taxon, '|', 1), '[0-9]+', 0) AS INTEGER) AS taxon_subject,
       TRY_CAST(
         CASE WHEN contains(taxon, '|')
              THEN regexp_extract(split_part(taxon, '|', 2), '[0-9]+', 0)
              ELSE NULL END
       AS INTEGER) AS taxon_interactor,
       CASE aspect
         WHEN 'P' THEN 'RO:0002331'
         WHEN 'F' THEN 'RO:0002327'
         WHEN 'C' THEN 'RO:0001025'
         ELSE NULL
       END AS ro_predicate
     FROM read_parquet('%s')", pq
  ))

  tbl    <- dplyr::tbl(con, "test_gaf")
  result <- GOAnno4Bioc::gaf_collect(tbl)

  expect_s3_class(result, "tbl_df")
})

test_that("gaf_collect() date column is Date class", {
  testthat::skip_if_not_installed("duckdb")

  pq  <- .make_test_parquet()
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  DBI::dbExecute(con, sprintf(
    "CREATE VIEW test_gaf2 AS
     SELECT *,
       TRY_CAST(regexp_extract(split_part(taxon, '|', 1), '[0-9]+', 0) AS INTEGER) AS taxon_subject,
       TRY_CAST(
         CASE WHEN contains(taxon, '|')
              THEN regexp_extract(split_part(taxon, '|', 2), '[0-9]+', 0)
              ELSE NULL END
       AS INTEGER) AS taxon_interactor,
       CASE aspect
         WHEN 'P' THEN 'RO:0002331'
         WHEN 'F' THEN 'RO:0002327'
         WHEN 'C' THEN 'RO:0001025'
         ELSE NULL
       END AS ro_predicate
     FROM read_parquet('%s')", pq
  ))

  result <- dplyr::tbl(con, "test_gaf2") |> GOAnno4Bioc::gaf_collect()
  expect_s3_class(result$date, "Date")
})

test_that("gaf_collect() filter_not excludes NOT rows", {
  testthat::skip_if_not_installed("duckdb")

  pq  <- .make_test_parquet()
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  DBI::dbExecute(con, sprintf(
    "CREATE VIEW test_gaf3 AS
     SELECT *,
       TRY_CAST(regexp_extract(split_part(taxon, '|', 1), '[0-9]+', 0) AS INTEGER) AS taxon_subject,
       TRY_CAST(
         CASE WHEN contains(taxon, '|')
              THEN regexp_extract(split_part(taxon, '|', 2), '[0-9]+', 0)
              ELSE NULL END
       AS INTEGER) AS taxon_interactor,
       CASE aspect
         WHEN 'P' THEN 'RO:0002331'
         WHEN 'F' THEN 'RO:0002327'
         WHEN 'C' THEN 'RO:0001025'
         ELSE NULL
       END AS ro_predicate
     FROM read_parquet('%s')", pq
  ))

  tbl     <- dplyr::tbl(con, "test_gaf3")
  all_r   <- GOAnno4Bioc::gaf_collect(tbl, filter_not = FALSE)
  filt_r  <- GOAnno4Bioc::gaf_collect(tbl, filter_not = TRUE)

  expect_gte(nrow(all_r), nrow(filt_r))
})

test_that("gaf_collect() filter_taxon works", {
  testthat::skip_if_not_installed("duckdb")

  pq  <- .make_test_parquet()
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  DBI::dbExecute(con, sprintf(
    "CREATE VIEW test_gaf4 AS
     SELECT *,
       TRY_CAST(regexp_extract(split_part(taxon, '|', 1), '[0-9]+', 0) AS INTEGER) AS taxon_subject,
       TRY_CAST(
         CASE WHEN contains(taxon, '|')
              THEN regexp_extract(split_part(taxon, '|', 2), '[0-9]+', 0)
              ELSE NULL END
       AS INTEGER) AS taxon_interactor,
       CASE aspect
         WHEN 'P' THEN 'RO:0002331'
         WHEN 'F' THEN 'RO:0002327'
         WHEN 'C' THEN 'RO:0001025'
         ELSE NULL
       END AS ro_predicate
     FROM read_parquet('%s')", pq
  ))

  result <- dplyr::tbl(con, "test_gaf4") |>
    GOAnno4Bioc::gaf_collect(filter_taxon = 9606L)

  expect_true(all(result$taxon_subject == 9606L))
})


# ── gaf_tbl ───────────────────────────────────────────────────────────────────

test_that("gaf_tbl() errors when no parquet cache exists", {
  expect_error(
    GOAnno4Bioc::gaf_tbl("klingon"),
    "No parquet cache"
  )
})

test_that("gaf_tbl() returns lazy tbl when parquet exists", {
  testthat::skip_if_not(GOAnno4Bioc::has_gaf_parquet("human"),
    "human parquet not built")

  result <- GOAnno4Bioc::gaf_tbl("human")
  expect_s3_class(result, "tbl_lazy")
})

test_that("gaf_tbl() result has expected columns", {
  testthat::skip_if_not(GOAnno4Bioc::has_gaf_parquet("human"),
    "human parquet not built")

  t <- GOAnno4Bioc::gaf_tbl("human")
  on.exit(GOAnno4Bioc::gaf_tbl_disconnect(t), add = TRUE)

  cols <- colnames(t)
  expect_true(all(GOAnno4Bioc::GAF_COLUMNS %in% cols))
  expect_true("ro_predicate"     %in% cols)
  expect_true("taxon_subject"    %in% cols)
  expect_true("taxon_interactor" %in% cols)
})

test_that("gaf_tbl() supports symbol filter before collect", {
  testthat::skip_if_not(GOAnno4Bioc::has_gaf_parquet("human"),
    "human parquet not built")

  t <- GOAnno4Bioc::gaf_tbl("human")
  on.exit(GOAnno4Bioc::gaf_tbl_disconnect(t), add = TRUE)

  result <- t |>
    dplyr::filter(db_object_symbol == "ORMDL3") |>
    GOAnno4Bioc::gaf_collect()

  expect_true(all(result$db_object_symbol == "ORMDL3"))
  expect_gt(nrow(result), 0L)
})


# ── get_gaf backend selection ─────────────────────────────────────────────────

test_that("get_gaf() uses gaf backend when parquet absent", {
  testthat::skip_if_not_installed("BiocFileCache")
  testthat::skip_on_ci()
  testthat::skip_if(GOAnno4Bioc::has_gaf_parquet("human"),
    "human parquet exists — backend auto-test not applicable")

  # Should fall back to parse_gaf without error
  result <- GOAnno4Bioc::get_gaf("human",
    filter_taxon = 9606L, evidence_codes = "IDA")
  expect_s3_class(result, "tbl_df")
})

test_that("get_gaf(backend='parquet') errors when parquet absent", {
  testthat::skip_if(GOAnno4Bioc::has_gaf_parquet("klingon"))
  expect_error(
    GOAnno4Bioc::get_gaf("klingon", backend = "parquet"),
    "No parquet cache"
  )
})
