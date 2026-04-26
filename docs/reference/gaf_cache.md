<div id="main" class="col-md-9" role="main">

# Retrieve and cache a GAF file via BiocFileCache

<div class="ref-description section level2">

Downloads a GAF file for the specified species from the EBI GOA FTP and
caches it locally using `BiocFileCache`. On subsequent calls the cached
file is returned without re-downloading (unless `force = TRUE`).

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gaf_cache(species = NULL, url = NULL, gaf_file = NULL, force = FALSE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   species:

    character scalar matching a `species` value from
    `gaf_known_species`, e.g. `"human"`, `"mouse"`. Case-insensitive.
    Ignored if `url` is supplied.

-   url:

    character scalar. A fully-resolved GAF URL. Used when `species` is
    `NULL` or to override the static URL for a known species.

-   gaf\_file:

    character scalar. Override just the filename within the species FTP
    directory, e.g. `"goa_human.gaf.gz"`. Useful when EBI renames the
    standard file without changing the directory. Only used when
    `species` is supplied and `url` is `NULL`.

-   force:

    logical. Re-download even if a cached copy exists. Default `FALSE`.

</div>

<div class="section level2">

## Value

the local file path to the cached `.gaf.gz` file, suitable for passing
to `parse_gaf`.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`parse_gaf`, `gaf_known_species`, `get_gaf`

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
path <- gaf_cache("human")
#> Using cached GAF: /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/d6e436535dcd_goa_human.gaf.gz
parse_gaf(path, filter_taxon = 9606L)
#> # A tibble: 816,793 × 20
#>    db        db_object_id db_object_symbol qualifier   go_id      db_reference  
#>    <chr>     <chr>        <chr>            <chr>       <chr>      <chr>         
#>  1 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0000298 GO_REF:0000033
#>  2 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0005515 PMID:33961781 
#>  3 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0008486 GO_REF:0000003
#>  4 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0008486 GO_REF:0000024
#>  5 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0008486 GO_REF:0000033
#>  6 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0016462 GO_REF:0000002
#>  7 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0016787 GO_REF:0000002
#>  8 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0034431 GO_REF:0000033
#>  9 UniProtKB A0A024RBG1   NUDT4B           enables     GO:0034432 GO_REF:0000033
#> 10 UniProtKB A0A024RBG1   NUDT4B           involved_in GO:0071543 GO_REF:0000033
#> # ℹ 816,783 more rows
#> # ℹ 14 more variables: evidence_code <chr>, with_or_from <chr>, aspect <chr>,
#> #   ro_predicate <chr>, db_object_name <chr>, db_object_synonym <chr>,
#> #   db_object_type <chr>, taxon <chr>, taxon_subject <int>,
#> #   taxon_interactor <int>, date <date>, assigned_by <chr>,
#> #   annotation_extension <chr>, gene_product_form_id <chr>

# Override filename if EBI has renamed the file
path <- gaf_cache("human", gaf_file = "goa_human.gaf.gz")
#> Using cached GAF: /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/d6e436535dcd_goa_human.gaf.gz

# Supply a fully custom URL
path <- gaf_cache(
  url = paste0(
    "https://ftp.ebi.ac.uk/pub/databases/GO/goa/",
    "HUMAN/goa_human.gaf.gz"
  )
)
#> Using cached GAF: /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/d6e436535dcd_goa_human.gaf.gz
```

</div>

</div>

</div>
