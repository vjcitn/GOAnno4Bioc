<div id="main" class="col-md-9" role="main">

# Extract the primary database accession as a CURIE

<div class="ref-description section level2">

Combines `db` and `db_object_id` into a CURIE-style identifier such as
`"UniProtKB:P12345"`. This is the format used in the semsql
`gene_go_edge` schema for the `subject` column.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gaf_add_subject_curie(gaf)
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

`gaf` with an additional `subject_curie` column prepended.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
gaf <- parse_gaf(gaf_path)
gaf_add_subject_curie(gaf)
#> # A tibble: 9 × 21
#>   subject_curie db    db_object_id db_object_symbol qualifier go_id db_reference
#>   <chr>         <chr> <chr>        <chr>            <chr>     <chr> <chr>       
#> 1 UniProtKB:P0… UniP… P05231       IL6              NA        GO:0… PMID:212685…
#> 2 UniProtKB:P0… UniP… P05231       IL6              NA        GO:0… PMID:2126852
#> 3 UniProtKB:P0… UniP… P05231       IL6              NA        GO:0… PMID:2126852
#> 4 UniProtKB:P0… UniP… P01375       TNF              NA        GO:0… PMID:3877632
#> 5 UniProtKB:P0… UniP… P01375       TNF              NA        GO:0… PMID:3877632
#> 6 UniProtKB:Q9… UniP… Q9Y6K5       IRAK4            NA        GO:0… PMID:116067…
#> 7 UniProtKB:P0… UniP… P04637       TP53             NA        GO:0… PMID:3460971
#> 8 UniProtKB:P0… UniP… P04637       TP53             NA        GO:0… PMID:3460971
#> 9 UniProtKB:O0… UniP… O00206       TLR4             NA        GO:0… PMID:9813127
#> # ℹ 14 more variables: evidence_code <chr>, with_or_from <chr>, aspect <chr>,
#> #   ro_predicate <chr>, db_object_name <chr>, db_object_synonym <chr>,
#> #   db_object_type <chr>, taxon <chr>, taxon_subject <int>,
#> #   taxon_interactor <int>, date <date>, assigned_by <chr>,
#> #   annotation_extension <chr>, gene_product_form_id <chr>
```

</div>

</div>

</div>
