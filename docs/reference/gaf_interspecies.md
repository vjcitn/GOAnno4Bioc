<div id="main" class="col-md-9" role="main">

# Filter to interacting-taxon annotations

<div class="ref-description section level2">

Returns only rows where a second (interacting) taxon is present in
column 13 — i.e., host-pathogen annotations such as human gene products
annotated in the context of SARS-CoV-2, HIV-1, or bacterial infection.
These are excluded from most standard enrichment workflows but may be of
specific interest for immunology or infectious disease research.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gaf_interspecies(gaf)
```

</div>

</div>

<div class="section level2">

## Arguments

-   gaf:

    a tibble as returned by `parse_gaf`.

</div>

<div class="section level2">

## Value

a tibble, subset of `gaf`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
gaf <- parse_gaf(gaf_path)
gaf_interspecies(gaf)
#> # A tibble: 1 × 20
#>   db    db_object_id db_object_symbol qualifier go_id db_reference evidence_code
#>   <chr> <chr>        <chr>            <chr>     <chr> <chr>        <chr>        
#> 1 UniP… Q9Y6K5       IRAK4            NA        GO:0… PMID:116067… IMP          
#> # ℹ 13 more variables: with_or_from <chr>, aspect <chr>, ro_predicate <chr>,
#> #   db_object_name <chr>, db_object_synonym <chr>, db_object_type <chr>,
#> #   taxon <chr>, taxon_subject <int>, taxon_interactor <int>, date <date>,
#> #   assigned_by <chr>, annotation_extension <chr>, gene_product_form_id <chr>
```

</div>

</div>

</div>
