<div id="main" class="col-md-9" role="main">

# Summarise annotation counts by aspect and evidence type

<div class="ref-description section level2">

Convenience cross-tabulation of ontology aspect (BP/MF/CC) against broad
evidence category (experimental vs computational vs other).

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gaf_aspect_summary(gaf)
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

a tibble with columns `aspect`, `evidence_category`, `n`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
gaf <- parse_gaf(gaf_path)
gaf_aspect_summary(gaf)
#> # A tibble: 4 × 3
#>   aspect evidence_category     n
#>   <chr>  <chr>             <int>
#> 1 C      experimental          1
#> 2 F      experimental          3
#> 3 P      computational         1
#> 4 P      experimental          4
```

</div>

</div>

</div>
