<div id="main" class="col-md-9" role="main">

# Produce an interactive annotation report for a gene

<div class="ref-description section level2">

Takes a GAF tibble (as returned by `parse_gaf`) filtered to a single
gene, enriches it with GO term labels from GO.ddb, formats PubMed
references as HTML hyperlinks, and presents the result as an interactive
`datatable`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gene_report(
  gaf,
  symbol = NULL,
  columns = c("go_id", "go_label", "qualifier", "aspect", "evidence_code",
    "db_reference", "assigned_by", "date"),
  pubmed_base = "https://pubmed.ncbi.nlm.nih.gov/",
  dt_options = list(pageLength = 20, scrollX = TRUE),
  ...
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   gaf:

    a tibble as returned by `parse_gaf`, filtered to a single gene
    symbol. If multiple symbols are present, only the first
    (alphabetically) is reported and a warning is issued.

-   symbol:

    character scalar. If supplied, `gaf` is filtered to this symbol
    before processing. Ignored if `NULL` (default).

-   columns:

    character vector of columns to include in the report. Default is a
    curated readable subset. Use `"all"` to include every column.

-   pubmed\_base:

    character scalar. Base URL for PubMed links. Default
    `"https://pubmed.ncbi.nlm.nih.gov/"`.

-   dt\_options:

    named list of additional options passed to `datatable` via its
    `options` argument.

-   ...:

    additional arguments passed to `datatable`.

</div>

<div class="section level2">

## Value

a `datatables` object (invisibly) which renders as an interactive HTML
table in RMarkdown, Shiny, or the RStudio viewer.

</div>

<div class="section level2">

## Details

GO.ddb must have an active connection (via `GO.ddb::make_go_con()`)
before calling this function. If GO.ddb is not installed or no
connection is active, GO term labels are omitted with a warning and raw
GO IDs are shown instead.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`parse_gaf`, `datatable`

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
gaf <- parse_gaf(gaf_path)
gene_report(gaf, symbol = "IL6")
#> Warning: No active GO.ddb connection — GO term labels will be omitted.
#> Call GO.ddb::make_go_con() before gene_report().
```

</div>

</div>

</div>
