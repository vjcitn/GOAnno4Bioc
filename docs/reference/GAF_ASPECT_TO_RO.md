<div id="main" class="col-md-9" role="main">

# Aspect-to-RO predicate map

<div class="ref-description section level2">

Maps the single-character GAF Aspect code (column 9) to the Relation
Ontology predicate CURIE used in the semsql gene-GO annotation schema.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
GAF_ASPECT_TO_RO
```

</div>

</div>

<div class="section level2">

## Format

An object of class `character` of length 3.

</div>

<div class="section level2">

## Details

The Aspect code is a compressed namespace indicator in the GAF format:

-   P:

    biological\_process

-   F:

    molecular\_function

-   C:

    cellular\_component

The mapping to RO predicates reflects the distinct biological semantics
of each namespace:

-   P:

    `RO:0002331` (involved\_in) — the gene product participates in a
    biological process

-   F:

    `RO:0002327` (enables) — the gene product provides the catalytic or
    binding activity for a molecular function

-   C:

    `RO:0001025` (located\_in) — the gene product is spatially located
    in a cellular component

Making the predicate explicit (rather than leaving it implicit in the
Aspect code) enables typed predicate filtering in the semsql annotation
schema, so queries like "genes that enable any descendant of GO:0003824"
can be expressed directly rather than requiring a namespace pre-filter.

</div>

</div>
