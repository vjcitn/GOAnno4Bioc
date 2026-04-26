<div id="main" class="col-md-9" role="main">

# List species with known GAF download URLs

<div class="ref-description section level2">

Returns a data frame of species for which EBI GOA distributes a named
species-specific GAF file, with their resolved download URLs and primary
NCBI taxon IDs.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gaf_known_species()
```

</div>

</div>

<div class="section level2">

## Value

a data frame with columns `species`, `directory`, `filename`,
`taxon_id`, `url`.

</div>

<div class="section level2">

## Details

The all-species UniProt file (`UNIPROT/goa_uniprot_all.gaf.gz`, \~5 GB)
and the PDB file are not included as they are not species-specific;
supply their URLs directly to `gaf_cache`.

If a URL in this table is stale (EBI occasionally renames files), use
`gaf_cache(species, gaf_file = "new_name.gaf.gz")` or
`gaf_cache(url = "https://...")`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
gaf_known_species()
#>        species   directory           filename taxon_id
#> 1  arabidopsis ARABIDOPSIS        tair.gaf.gz     3702
#> 2      chicken     CHICKEN goa_chicken.gaf.gz     9031
#> 3          cow         COW     goa_cow.gaf.gz     9913
#> 4        dicty       DICTY   dictybase.gaf.gz    44689
#> 5          dog         DOG     goa_dog.gaf.gz     9615
#> 6          fly         FLY          fb.gaf.gz     7227
#> 7        human       HUMAN   goa_human.gaf.gz     9606
#> 8        mouse       MOUSE         mgi.gaf.gz    10090
#> 9          pig         PIG     goa_pig.gaf.gz     9823
#> 10         rat         RAT         rgd.gaf.gz    10116
#> 11        worm        WORM          wb.gaf.gz     6239
#> 12       yeast       YEAST   goa_yeast.gaf.gz   559292
#> 13   zebrafish   ZEBRAFISH        zfin.gaf.gz     7955
#>                                                                      url
#> 1     https://ftp.ebi.ac.uk/pub/databases/GO/goa/ARABIDOPSIS/tair.gaf.gz
#> 2  https://ftp.ebi.ac.uk/pub/databases/GO/goa/CHICKEN/goa_chicken.gaf.gz
#> 3          https://ftp.ebi.ac.uk/pub/databases/GO/goa/COW/goa_cow.gaf.gz
#> 4      https://ftp.ebi.ac.uk/pub/databases/GO/goa/DICTY/dictybase.gaf.gz
#> 5          https://ftp.ebi.ac.uk/pub/databases/GO/goa/DOG/goa_dog.gaf.gz
#> 6               https://ftp.ebi.ac.uk/pub/databases/GO/goa/FLY/fb.gaf.gz
#> 7      https://ftp.ebi.ac.uk/pub/databases/GO/goa/HUMAN/goa_human.gaf.gz
#> 8            https://ftp.ebi.ac.uk/pub/databases/GO/goa/MOUSE/mgi.gaf.gz
#> 9          https://ftp.ebi.ac.uk/pub/databases/GO/goa/PIG/goa_pig.gaf.gz
#> 10             https://ftp.ebi.ac.uk/pub/databases/GO/goa/RAT/rgd.gaf.gz
#> 11             https://ftp.ebi.ac.uk/pub/databases/GO/goa/WORM/wb.gaf.gz
#> 12     https://ftp.ebi.ac.uk/pub/databases/GO/goa/YEAST/goa_yeast.gaf.gz
#> 13      https://ftp.ebi.ac.uk/pub/databases/GO/goa/ZEBRAFISH/zfin.gaf.gz
```

</div>

</div>

</div>
