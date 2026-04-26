<div id="main" class="col-md-9" role="main">

# Expand a pipe-separated GAF column into long format

<div class="ref-description section level2">

Several GAF columns contain pipe-separated multi-value fields:
`db_reference`, `with_or_from`, `db_object_synonym`, and
`annotation_extension`. This function unnests one such column into long
format, with one value per row and all other columns repeated.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gaf_expand_column(gaf, column)
```

</div>

</div>

<div class="section level2">

## Arguments

-   gaf:

    a tibble as returned by `parse_gaf`.

-   column:

    character scalar naming the column to expand. Must be one of
    `"db_reference"`, `"with_or_from"`, `"db_object_synonym"`, or
    `"annotation_extension"`.

</div>

<div class="section level2">

## Value

a tibble with \\(\\geq\\) as many rows as `gaf` — one per pipe-separated
value in `column`. Rows where `column` is `NA` are retained with `NA` in
the expanded column.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
gaf <- parse_gaf(gaf_path)

# db_reference has pipe-separated PMIDs in some rows
gaf_expand_column(gaf, "db_reference")
#> # A tibble: 11 × 20
#>    db        db_object_id db_object_symbol qualifier go_id      db_reference 
#>    <chr>     <chr>        <chr>            <chr>     <chr>      <chr>        
#>  1 UniProtKB P05231       IL6              NA        GO:0006954 PMID:2126852 
#>  2 UniProtKB P05231       IL6              NA        GO:0006954 PMID:9843981 
#>  3 UniProtKB P05231       IL6              NA        GO:0005125 PMID:2126852 
#>  4 UniProtKB P05231       IL6              NA        GO:0005615 PMID:2126852 
#>  5 UniProtKB P01375       TNF              NA        GO:0006954 PMID:3877632 
#>  6 UniProtKB P01375       TNF              NA        GO:0005102 PMID:3877632 
#>  7 UniProtKB Q9Y6K5       IRAK4            NA        GO:0045087 PMID:11606775
#>  8 UniProtKB Q9Y6K5       IRAK4            NA        GO:0045087 PMID:15240741
#>  9 UniProtKB P04637       TP53             NA        GO:0006977 PMID:3460971 
#> 10 UniProtKB P04637       TP53             NA        GO:0003700 PMID:3460971 
#> 11 UniProtKB O00206       TLR4             NA        GO:0045087 PMID:9813127 
#> # ℹ 14 more variables: evidence_code <chr>, with_or_from <chr>, aspect <chr>,
#> #   ro_predicate <chr>, db_object_name <chr>, db_object_synonym <chr>,
#> #   db_object_type <chr>, taxon <chr>, taxon_subject <int>,
#> #   taxon_interactor <int>, date <date>, assigned_by <chr>,
#> #   annotation_extension <chr>, gene_product_form_id <chr>

# with_or_from has pipe-separated IDs in some rows
gaf_expand_column(gaf, "with_or_from")
#> # A tibble: 10 × 20
#>    db        db_object_id db_object_symbol qualifier go_id      db_reference    
#>    <chr>     <chr>        <chr>            <chr>     <chr>      <chr>           
#>  1 UniProtKB P05231       IL6              NA        GO:0006954 PMID:2126852|PM…
#>  2 UniProtKB P05231       IL6              NA        GO:0005125 PMID:2126852    
#>  3 UniProtKB P05231       IL6              NA        GO:0005615 PMID:2126852    
#>  4 UniProtKB P01375       TNF              NA        GO:0006954 PMID:3877632    
#>  5 UniProtKB P01375       TNF              NA        GO:0005102 PMID:3877632    
#>  6 UniProtKB P01375       TNF              NA        GO:0005102 PMID:3877632    
#>  7 UniProtKB Q9Y6K5       IRAK4            NA        GO:0045087 PMID:11606775|P…
#>  8 UniProtKB P04637       TP53             NA        GO:0006977 PMID:3460971    
#>  9 UniProtKB P04637       TP53             NA        GO:0003700 PMID:3460971    
#> 10 UniProtKB O00206       TLR4             NA        GO:0045087 PMID:9813127    
#> # ℹ 14 more variables: evidence_code <chr>, with_or_from <chr>, aspect <chr>,
#> #   ro_predicate <chr>, db_object_name <chr>, db_object_synonym <chr>,
#> #   db_object_type <chr>, taxon <chr>, taxon_subject <int>,
#> #   taxon_interactor <int>, date <date>, assigned_by <chr>,
#> #   annotation_extension <chr>, gene_product_form_id <chr>
```

</div>

</div>

</div>
