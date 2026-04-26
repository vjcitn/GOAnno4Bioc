<div id="main" class="col-md-9" role="main">

# Summarise annotation counts by evidence code

<div class="ref-description section level2">

Returns a summary tibble showing how many annotations exist per evidence
code, sorted by descending count. Useful for a quick quality check after
parsing.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gaf_evidence_summary(gaf)
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

a tibble with columns `evidence_code`, `n`, `experimental` (logical).

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
gaf <- parse_gaf(gaf_path)
gaf_evidence_summary(gaf)
#> # A tibble: 4 × 3
#>   evidence_code     n experimental
#>   <chr>         <int> <lgl>       
#> 1 IDA               6 TRUE        
#> 2 IEA               1 FALSE       
#> 3 IMP               1 TRUE        
#> 4 IPI               1 TRUE        
```

</div>

</div>

</div>
