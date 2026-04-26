<div id="main" class="col-md-9" role="main">

# Convert a parsed GAF tibble to semsql term\_association format

<div class="ref-description section level2">

Transforms the output of `parse_gaf` into the column structure of the
semsql `term_association` table, suitable for writing to parquet and
loading into a GO.ddb-compatible DuckDB connection.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gaf_to_term_association(gaf)
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

a tibble in semsql term\_association column order, ready for
`arrow::write_parquet()` or DuckDB ingestion.

</div>

<div class="section level2">

## Details

The mapping is:

|                 |                                     |
|-----------------|-------------------------------------|
| `subject`       | `db:db_object_id` CURIE             |
| `predicate`     | `ro_predicate` derived from Aspect  |
| `object`        | `go_id`                             |
| `evidence_type` | `evidence_code`                     |
| `publication`   | first pipe-separated `db_reference` |
| `source`        | `assigned_by`                       |

Additionally retains `taxon_subject`, `taxon_interactor`,
`db_object_symbol`, and `db_object_type` as extended columns not in the
minimal semsql schema but useful for downstream analysis.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`parse_gaf`, `write_parquet`

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
gaf <- parse_gaf(gaf_path)
gaf_to_term_association(gaf)
#> # A tibble: 9 × 14
#>   subject          predicate  object     evidence_type publication source symbol
#>   <chr>            <chr>      <chr>      <chr>         <chr>       <chr>  <chr> 
#> 1 UniProtKB:P05231 RO:0002331 GO:0006954 IDA           PMID:21268… UniPr… IL6   
#> 2 UniProtKB:P05231 RO:0002327 GO:0005125 IDA           PMID:21268… UniPr… IL6   
#> 3 UniProtKB:P05231 RO:0001025 GO:0005615 IDA           PMID:21268… UniPr… IL6   
#> 4 UniProtKB:P01375 RO:0002331 GO:0006954 IEA           PMID:38776… UniPr… TNF   
#> 5 UniProtKB:P01375 RO:0002327 GO:0005102 IPI           PMID:38776… UniPr… TNF   
#> 6 UniProtKB:Q9Y6K5 RO:0002331 GO:0045087 IMP           PMID:11606… UniPr… IRAK4 
#> 7 UniProtKB:P04637 RO:0002331 GO:0006977 IDA           PMID:34609… UniPr… TP53  
#> 8 UniProtKB:P04637 RO:0002327 GO:0003700 IDA           PMID:34609… UniPr… TP53  
#> 9 UniProtKB:O00206 RO:0002331 GO:0045087 IDA           PMID:98131… UniPr… TLR4  
#> # ℹ 7 more variables: db_object_type <chr>, taxon_subject <int>,
#> #   taxon_interactor <int>, qualifier <chr>, date <date>,
#> #   annotation_extension <chr>, gene_product_form_id <chr>
```

</div>

</div>

</div>
