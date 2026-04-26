# test-gaf_utils.R — utility function tests
#
# The mini.gaf.gz fixture contains pipe-separated values in:
#   db_reference    — IL6 row has PMID:2126852|PMID:9843981
#                     IRAK4 row has PMID:11606775|PMID:15240741
#   with_or_from    — TNF IPI row has UniProtKB:P19438|UniProtKB:Q9Y6K5
#   db_object_synonym — IL6, TNF, TP53 rows have pipe-separated synonyms
# These are required for gaf_expand_column tests to be genuinely discriminating.

gaf_path <- function()
  system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")

gaf_fixture <- function(filter_not = TRUE)
  GOAnno4Bioc::parse_gaf(gaf_path(), filter_not = filter_not)

# ── gaf_expand_column ─────────────────────────────────────────────────────────

test_that("gaf_expand_column() errors on invalid column", {
  expect_error(
    GOAnno4Bioc::gaf_expand_column(gaf_fixture(), "go_id"),
    "must be one of"
  )
})

test_that("gaf_expand_column() returns a tibble", {
  result <- GOAnno4Bioc::gaf_expand_column(gaf_fixture(), "db_reference")
  expect_s3_class(result, "tbl_df")
})

test_that("gaf_expand_column(db_reference) returns more rows than input", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_expand_column(gaf, "db_reference")
  # fixture has two rows with pipe-separated PMIDs
  expect_gt(nrow(result), nrow(gaf))
})

test_that("gaf_expand_column(db_reference) leaves no pipes in column", {
  result <- GOAnno4Bioc::gaf_expand_column(gaf_fixture(), "db_reference")
  non_na <- result$db_reference[!is.na(result$db_reference)]
  expect_false(any(grepl("|", non_na, fixed = TRUE)))
})

test_that("gaf_expand_column(with_or_from) returns more rows than input", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_expand_column(gaf, "with_or_from")
  # fixture TNF IPI row has two pipe-separated with_or_from IDs
  expect_gt(nrow(result), nrow(gaf))
})

test_that("gaf_expand_column(with_or_from) leaves no pipes in column", {
  result <- GOAnno4Bioc::gaf_expand_column(gaf_fixture(), "with_or_from")
  non_na <- result$with_or_from[!is.na(result$with_or_from)]
  expect_false(any(grepl("|", non_na, fixed = TRUE)))
})

test_that("gaf_expand_column(db_object_synonym) returns more rows", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_expand_column(gaf, "db_object_synonym")
  # fixture has multiple pipe-separated synonyms per gene
  expect_gt(nrow(result), nrow(gaf))
})

test_that("gaf_expand_column(db_object_synonym) leaves no pipes", {
  result <- GOAnno4Bioc::gaf_expand_column(gaf_fixture(), "db_object_synonym")
  non_na <- result$db_object_synonym[!is.na(result$db_object_synonym)]
  expect_false(any(grepl("|", non_na, fixed = TRUE)))
})

test_that("gaf_expand_column() non-pipe columns are unaffected", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_expand_column(gaf, "annotation_extension")
  # all annotation_extension values in fixture are NA — no splitting occurs
  expect_equal(nrow(result), nrow(gaf))
})

# ── gaf_add_subject_curie ─────────────────────────────────────────────────────

test_that("gaf_add_subject_curie() adds subject_curie as first column", {
  result <- GOAnno4Bioc::gaf_add_subject_curie(gaf_fixture())
  expect_equal(colnames(result)[1], "subject_curie")
})

test_that("gaf_add_subject_curie() CURIEs have db:id format", {
  result <- GOAnno4Bioc::gaf_add_subject_curie(gaf_fixture())
  expect_true(all(grepl("^[^:]+:.+$", result$subject_curie)))
})

test_that("gaf_add_subject_curie() CURIEs match db and db_object_id", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_add_subject_curie(gaf)
  expected <- paste0(gaf$db, ":", gaf$db_object_id)
  expect_equal(result$subject_curie, expected)
})

# ── gaf_evidence_summary ──────────────────────────────────────────────────────

test_that("gaf_evidence_summary() returns a tibble", {
  result <- GOAnno4Bioc::gaf_evidence_summary(gaf_fixture())
  expect_s3_class(result, "tbl_df")
})

test_that("gaf_evidence_summary() has expected columns", {
  result <- GOAnno4Bioc::gaf_evidence_summary(gaf_fixture())
  expect_setequal(colnames(result), c("evidence_code", "n", "experimental"))
})

test_that("gaf_evidence_summary() experimental column is logical", {
  result <- GOAnno4Bioc::gaf_evidence_summary(gaf_fixture())
  expect_type(result$experimental, "logical")
})

test_that("gaf_evidence_summary() n values sum to nrow(gaf)", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_evidence_summary(gaf)
  expect_equal(sum(result$n), nrow(gaf))
})

test_that("gaf_evidence_summary() IDA is marked experimental", {
  result  <- GOAnno4Bioc::gaf_evidence_summary(gaf_fixture())
  ida_row <- result[result$evidence_code == "IDA", ]
  if (nrow(ida_row) > 0L) expect_true(ida_row$experimental)
})

test_that("gaf_evidence_summary() IEA is not marked experimental", {
  result  <- GOAnno4Bioc::gaf_evidence_summary(gaf_fixture())
  iea_row <- result[result$evidence_code == "IEA", ]
  if (nrow(iea_row) > 0L) expect_false(iea_row$experimental)
})

# ── gaf_aspect_summary ────────────────────────────────────────────────────────

test_that("gaf_aspect_summary() has expected columns", {
  result <- GOAnno4Bioc::gaf_aspect_summary(gaf_fixture())
  expect_setequal(colnames(result), c("aspect", "evidence_category", "n"))
})

test_that("gaf_aspect_summary() evidence_category values are valid", {
  result <- GOAnno4Bioc::gaf_aspect_summary(gaf_fixture())
  expect_true(all(result$evidence_category %in%
    c("experimental", "computational", "other")))
})

test_that("gaf_aspect_summary() counts sum to nrow(gaf)", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_aspect_summary(gaf)
  expect_equal(sum(result$n), nrow(gaf))
})

# ── gaf_interspecies ──────────────────────────────────────────────────────────

test_that("gaf_interspecies() returns only rows with taxon_interactor", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_interspecies(gaf)
  expect_true(all(!is.na(result$taxon_interactor)))
})

test_that("gaf_interspecies() returns fewer rows than input", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_interspecies(gaf)
  expect_lt(nrow(result), nrow(gaf))
})

test_that("gaf_interspecies() returns at least one row from fixture", {
  result <- GOAnno4Bioc::gaf_interspecies(gaf_fixture())
  expect_gt(nrow(result), 0L)
})

# ── gaf_to_term_association ───────────────────────────────────────────────────

test_that("gaf_to_term_association() returns a tibble", {
  result <- GOAnno4Bioc::gaf_to_term_association(gaf_fixture())
  expect_s3_class(result, "tbl_df")
})

test_that("gaf_to_term_association() has same nrow as input", {
  gaf    <- gaf_fixture()
  result <- GOAnno4Bioc::gaf_to_term_association(gaf)
  expect_equal(nrow(result), nrow(gaf))
})

test_that("gaf_to_term_association() has required semsql columns", {
  result   <- GOAnno4Bioc::gaf_to_term_association(gaf_fixture())
  required <- c("subject", "predicate", "object",
                "evidence_type", "publication", "source")
  expect_true(all(required %in% colnames(result)))
})

test_that("gaf_to_term_association() subject is db:id format", {
  result <- GOAnno4Bioc::gaf_to_term_association(gaf_fixture())
  expect_true(all(grepl("^[^:]+:.+$", result$subject)))
})

test_that("gaf_to_term_association() object values have GO: prefix", {
  result <- GOAnno4Bioc::gaf_to_term_association(gaf_fixture())
  expect_true(all(startsWith(result$object, "GO:")))
})

test_that("gaf_to_term_association() predicate values are RO CURIEs", {
  result <- GOAnno4Bioc::gaf_to_term_association(gaf_fixture())
  expect_true(all(startsWith(result$predicate, "RO:")))
})

test_that("gaf_to_term_association() publication has no pipes", {
  result <- GOAnno4Bioc::gaf_to_term_association(gaf_fixture())
  non_na <- result$publication[!is.na(result$publication)]
  expect_false(any(grepl("|", non_na, fixed = TRUE)))
})

# ── gaf_known_species ─────────────────────────────────────────────────────────

test_that("gaf_known_species() returns a data frame", {
  result <- GOAnno4Bioc::gaf_known_species()
  expect_s3_class(result, "data.frame")
})

test_that("gaf_known_species() has expected columns", {
  result <- GOAnno4Bioc::gaf_known_species()
  expect_setequal(
    colnames(result),
    c("species", "directory", "filename", "taxon_id", "url")
  )
})

test_that("gaf_known_species() includes human and mouse", {
  result <- GOAnno4Bioc::gaf_known_species()
  expect_true("human" %in% result$species)
  expect_true("mouse" %in% result$species)
})

test_that("gaf_known_species() URLs start with https://", {
  result <- GOAnno4Bioc::gaf_known_species()
  expect_true(all(startsWith(result$url, "https://")))
})

test_that("gaf_known_species() human taxon_id is 9606", {
  result <- GOAnno4Bioc::gaf_known_species()
  expect_equal(result$taxon_id[result$species == "human"], 9606L)
})

test_that("gaf_known_species() has 13 species", {
  result <- GOAnno4Bioc::gaf_known_species()
  expect_equal(nrow(result), 13L)
})

test_that("gaf_cache() errors on unknown species", {
  expect_error(
    GOAnno4Bioc::gaf_cache("klingon"),
    "Unknown species"
  )
})

test_that("gaf_cache() errors when neither species nor url supplied", {
  expect_error(
    GOAnno4Bioc::gaf_cache(),
    "Supply either"
  )
})
