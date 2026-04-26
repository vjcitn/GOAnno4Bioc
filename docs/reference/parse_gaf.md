<div id="main" class="col-md-9" role="main">

# Parse a GAF 2.x annotation file into a tibble

<div class="ref-description section level2">

Reads a GAF (Gene Association Format) file — plain or gzip-compressed —
and returns a tibble with one row per annotation. Both GAF 2.1 and 2.2
are supported. The optional columns 16 (`annotation_extension`) and 17
(`gene_product_form_id`) are included when present.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
parse_gaf(path, filter_not = TRUE, filter_taxon = NULL, evidence_codes = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   path:

    character scalar. Path to a GAF file (`.gaf`, `.gaf.gz`, or any
    readable connection).

-   filter\_not:

    logical. If `TRUE` (default), rows where `qualifier` is `"NOT"` are
    excluded. NOT annotations assert that a gene product is explicitly
    *not* involved in the GO term and should usually be excluded from
    enrichment analyses.

-   filter\_taxon:

    integer or `NULL`. If non-`NULL`, only rows whose primary taxon
    matches this NCBI taxon ID are returned. Default `NULL` retains all
    taxa.

-   evidence\_codes:

    character vector or `NULL`. If non-`NULL`, only rows whose
    `evidence_code` is in this vector are returned. See
    `GAF_EVIDENCE_EXPERIMENTAL` and `GAF_EVIDENCE_COMPUTATIONAL` for
    curated sets. Default `NULL` retains all evidence codes.

</div>

<div class="section level2">

## Value

a `tibble` with 20 columns as described above.

</div>

<div class="section level2">

## Column descriptions

-   db:

    Source database, e.g. `"UniProtKB"`

-   db\_object\_id:

    Accession in source db, e.g. `"P12345"`

-   db\_object\_symbol:

    Gene symbol, e.g. `"IL6"`

-   qualifier:

    Annotation qualifier: `NA`, `"NOT"`, `"contributes_to"`, or
    `"colocalizes_with"`

-   go\_id:

    GO CURIE, e.g. `"GO:0006954"`

-   db\_reference:

    Pipe-separated references, e.g. `"PMID:12345678|PMID:23456789"`

-   evidence\_code:

    GAF evidence code, e.g. `"IEA"`

-   with\_or\_from:

    Pipe-separated supporting identifiers; `NA` if absent

-   aspect:

    Single character: `"P"` (BP), `"F"` (MF), `"C"` (CC)

-   db\_object\_name:

    Full name of annotated entity

-   db\_object\_synonym:

    Pipe-separated synonyms; `NA` if absent

-   db\_object\_type:

    Entity type, e.g. `"protein"`

-   taxon:

    Raw taxon field, e.g. `"taxon:9606"` or `"taxon:9606|taxon:562"` for
    interacting-taxon annotations

-   taxon\_subject:

    Primary taxon NCBI ID as integer, e.g. `9606L`

-   taxon\_interactor:

    Interacting organism NCBI ID, or `NA` for single-taxon annotations

-   date:

    Annotation date as `Date`

-   assigned\_by:

    Database that created the annotation

-   annotation\_extension:

    Optional RO-based annotation extensions; `NA` if absent

-   gene\_product\_form\_id:

    Optional isoform identifier; `NA` if absent

-   ro\_predicate:

    RO predicate CURIE derived from `aspect`: `"RO:0002331"`
    (BP/involved\_in), `"RO:0002327"` (MF/enables), `"RO:0001025"`
    (CC/located\_in). See `GAF_ASPECT_TO_RO` for the full mapping
    rationale.

</div>

<div class="section level2">

## Pipe-separated fields

Several columns contain pipe-separated multi-value fields:
`db_reference`, `with_or_from`, `db_object_synonym`, and
`annotation_extension`. These are retained as character strings in the
returned tibble. Use `gaf_expand_column` to unnest a specific column
into long format.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`gaf_expand_column`, `gaf_to_term_association`, `GAF_COLUMNS`,
`GAF_ASPECT_TO_RO`

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_path <- system.file("extdata", "mini.gaf.gz", package = "GOAnno4Bioc")
gaf <- parse_gaf(gaf_path)
gaf
#> # A tibble: 9 × 20
#>   db    db_object_id db_object_symbol qualifier go_id db_reference evidence_code
#>   <chr> <chr>        <chr>            <chr>     <chr> <chr>        <chr>        
#> 1 UniP… P05231       IL6              NA        GO:0… PMID:212685… IDA          
#> 2 UniP… P05231       IL6              NA        GO:0… PMID:2126852 IDA          
#> 3 UniP… P05231       IL6              NA        GO:0… PMID:2126852 IDA          
#> 4 UniP… P01375       TNF              NA        GO:0… PMID:3877632 IEA          
#> 5 UniP… P01375       TNF              NA        GO:0… PMID:3877632 IPI          
#> 6 UniP… Q9Y6K5       IRAK4            NA        GO:0… PMID:116067… IMP          
#> 7 UniP… P04637       TP53             NA        GO:0… PMID:3460971 IDA          
#> 8 UniP… P04637       TP53             NA        GO:0… PMID:3460971 IDA          
#> 9 UniP… O00206       TLR4             NA        GO:0… PMID:9813127 IDA          
#> # ℹ 13 more variables: with_or_from <chr>, aspect <chr>, ro_predicate <chr>,
#> #   db_object_name <chr>, db_object_synonym <chr>, db_object_type <chr>,
#> #   taxon <chr>, taxon_subject <int>, taxon_interactor <int>, date <date>,
#> #   assigned_by <chr>, annotation_extension <chr>, gene_product_form_id <chr>

# Experimental evidence only
parse_gaf(gaf_path, evidence_codes = GAF_EVIDENCE_EXPERIMENTAL)
#> # A tibble: 8 × 20
#>   db    db_object_id db_object_symbol qualifier go_id db_reference evidence_code
#>   <chr> <chr>        <chr>            <chr>     <chr> <chr>        <chr>        
#> 1 UniP… P05231       IL6              NA        GO:0… PMID:212685… IDA          
#> 2 UniP… P05231       IL6              NA        GO:0… PMID:2126852 IDA          
#> 3 UniP… P05231       IL6              NA        GO:0… PMID:2126852 IDA          
#> 4 UniP… P01375       TNF              NA        GO:0… PMID:3877632 IPI          
#> 5 UniP… Q9Y6K5       IRAK4            NA        GO:0… PMID:116067… IMP          
#> 6 UniP… P04637       TP53             NA        GO:0… PMID:3460971 IDA          
#> 7 UniP… P04637       TP53             NA        GO:0… PMID:3460971 IDA          
#> 8 UniP… O00206       TLR4             NA        GO:0… PMID:9813127 IDA          
#> # ℹ 13 more variables: with_or_from <chr>, aspect <chr>, ro_predicate <chr>,
#> #   db_object_name <chr>, db_object_synonym <chr>, db_object_type <chr>,
#> #   taxon <chr>, taxon_subject <int>, taxon_interactor <int>, date <date>,
#> #   assigned_by <chr>, annotation_extension <chr>, gene_product_form_id <chr>

# Human annotations only
parse_gaf(gaf_path, filter_taxon = 9606L)
#> # A tibble: 9 × 20
#>   db    db_object_id db_object_symbol qualifier go_id db_reference evidence_code
#>   <chr> <chr>        <chr>            <chr>     <chr> <chr>        <chr>        
#> 1 UniP… P05231       IL6              NA        GO:0… PMID:212685… IDA          
#> 2 UniP… P05231       IL6              NA        GO:0… PMID:2126852 IDA          
#> 3 UniP… P05231       IL6              NA        GO:0… PMID:2126852 IDA          
#> 4 UniP… P01375       TNF              NA        GO:0… PMID:3877632 IEA          
#> 5 UniP… P01375       TNF              NA        GO:0… PMID:3877632 IPI          
#> 6 UniP… Q9Y6K5       IRAK4            NA        GO:0… PMID:116067… IMP          
#> 7 UniP… P04637       TP53             NA        GO:0… PMID:3460971 IDA          
#> 8 UniP… P04637       TP53             NA        GO:0… PMID:3460971 IDA          
#> 9 UniP… O00206       TLR4             NA        GO:0… PMID:9813127 IDA          
#> # ℹ 13 more variables: with_or_from <chr>, aspect <chr>, ro_predicate <chr>,
#> #   db_object_name <chr>, db_object_synonym <chr>, db_object_type <chr>,
#> #   taxon <chr>, taxon_subject <int>, taxon_interactor <int>, date <date>,
#> #   assigned_by <chr>, annotation_extension <chr>, gene_product_form_id <chr>
```

</div>

</div>

</div>
