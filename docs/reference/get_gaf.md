<div id="main" class="col-md-9" role="main">

# Parse a species GAF file in one step

<div class="ref-description section level2">

Convenience wrapper combining `gaf_cache` and `parse_gaf`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
get_gaf(species, ..., force = FALSE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   species:

    character scalar, e.g. `"human"`, `"mouse"`.

-   ...:

    additional arguments passed to `parse_gaf`, e.g. `filter_not`,
    `evidence_codes`, `filter_taxon`.

-   force:

    logical passed to `gaf_cache`.

</div>

<div class="section level2">

## Value

a tibble as returned by `parse_gaf`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf <- get_gaf("human", filter_taxon = 9606L,
               evidence_codes = GAF_EVIDENCE_EXPERIMENTAL)
#> Using cached GAF: /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/d6e436535dcd_goa_human.gaf.gz
gaf
#> # A tibble: 423,057 × 20
#>    db        db_object_id db_object_symbol qualifier       go_id    db_reference
#>    <chr>     <chr>        <chr>            <chr>           <chr>    <chr>       
#>  1 UniProtKB A0A024RBG1   NUDT4B           enables         GO:0005… PMID:339617…
#>  2 UniProtKB A0A075B6N1   TRBV19           part_of         GO:0042… PMID:210819…
#>  3 UniProtKB A0A075B6T8   TRAV9-1          involved_in     GO:0002… PMID:167993…
#>  4 UniProtKB A0A075B6T8   TRAV9-1          is_active_in    GO:0019… PMID:167993…
#>  5 UniProtKB A0A087WT01   TRAV27           enables         GO:0005… PMID:210819…
#>  6 UniProtKB A0A087WT01   TRAV27           involved_in     GO:0006… PMID:126822…
#>  7 UniProtKB A0A087WT01   TRAV27           involved_in     GO:0050… PMID:126822…
#>  8 UniProtKB A0A087WT01   TRAV27           part_of         GO:0042… PMID:210819…
#>  9 UniProtKB A0A087X1C5   CYP2D7           NOT|enables     GO:0070… PMID:188385…
#> 10 UniProtKB A0A087X1C5   CYP2D7           NOT|involved_in GO:0006… PMID:188385…
#> # ℹ 423,047 more rows
#> # ℹ 14 more variables: evidence_code <chr>, with_or_from <chr>, aspect <chr>,
#> #   ro_predicate <chr>, db_object_name <chr>, db_object_synonym <chr>,
#> #   db_object_type <chr>, taxon <chr>, taxon_subject <int>,
#> #   taxon_interactor <int>, date <date>, assigned_by <chr>,
#> #   annotation_extension <chr>, gene_product_form_id <chr>
```

</div>

</div>

</div>
