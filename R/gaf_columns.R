# gaf_columns.R — GAF 2.2 column definitions and controlled vocabularies
#
# Reference: http://geneontology.org/docs/go-annotation-file-gaf-format-2.2/
#
# GAF 2.2 has 17 tab-separated columns.  Lines beginning with '!' are
# comments or header lines and are skipped during parsing.  The format
# supports both GAF 2.1 and 2.2 — the parser handles both transparently
# since the first 15 columns are identical and columns 16-17 are optional.

#' GAF 2.2 column names in order
#'
#' A character vector of the 17 column names used in GAF 2.2 files,
#' in their defined order.  Used internally by \code{\link{parse_gaf}}
#' to name the columns of the returned tibble.
#'
#' @export
GAF_COLUMNS <- c(
  "db",                  #  1 - source database (e.g. UniProtKB)
  "db_object_id",        #  2 - unique ID in source db
  "db_object_symbol",    #  3 - gene/protein symbol
  "qualifier",           #  4 - optional: NOT | contributes_to | colocalizes_with
  "go_id",               #  5 - GO:nnnnnnn
  "db_reference",        #  6 - pipe-separated references (PMID, GO_REF)
  "evidence_code",       #  7 - ECO/GAF evidence code (IEA, EXP, IDA, ...)
  "with_or_from",        #  8 - pipe-separated supporting IDs (may be empty)
  "aspect",              #  9 - P (BP) | F (MF) | C (CC)
  "db_object_name",      # 10 - full name of annotated entity
  "db_object_synonym",   # 11 - pipe-separated synonyms
  "db_object_type",      # 12 - protein | gene | RNA | complex | ...
  "taxon",               # 13 - taxon:nnnn or taxon:nnnn|taxon:mmmm
  "date",                # 14 - YYYYMMDD
  "assigned_by",         # 15 - database that made the annotation
  "annotation_extension",# 16 - optional: comma-separated RO extensions
  "gene_product_form_id" # 17 - optional: isoform identifier
)

#' Aspect-to-RO predicate map
#'
#' Maps the single-character GAF Aspect code (column 9) to the Relation
#' Ontology predicate CURIE used in the semsql gene-GO annotation schema.
#'
#' The Aspect code is a compressed namespace indicator in the GAF format:
#' \describe{
#'   \item{P}{biological_process}
#'   \item{F}{molecular_function}
#'   \item{C}{cellular_component}
#' }
#'
#' The mapping to RO predicates reflects the distinct biological semantics
#' of each namespace:
#' \describe{
#'   \item{P}{\code{RO:0002331} (involved_in) — the gene product participates
#'     in a biological process}
#'   \item{F}{\code{RO:0002327} (enables) — the gene product provides the
#'     catalytic or binding activity for a molecular function}
#'   \item{C}{\code{RO:0001025} (located_in) — the gene product is spatially
#'     located in a cellular component}
#' }
#'
#' Making the predicate explicit (rather than leaving it implicit in the
#' Aspect code) enables typed predicate filtering in the semsql annotation
#' schema, so queries like "genes that enable any descendant of GO:0003824"
#' can be expressed directly rather than requiring a namespace pre-filter.
#'
#' @export
GAF_ASPECT_TO_RO <- c(
  P = "RO:0002331",  # involved_in  (biological_process)
  F = "RO:0002327",  # enables      (molecular_function)
  C = "RO:0001025"   # located_in   (cellular_component)
)

#' Experimental evidence codes
#'
#' GAF evidence codes considered to be based on direct experimental
#' evidence, as opposed to computational or author-inferred codes.
#' Useful for filtering to high-confidence annotations.
#'
#' @export
GAF_EVIDENCE_EXPERIMENTAL <- c(
  "EXP",  # Inferred from Experiment
  "IDA",  # Inferred from Direct Assay
  "IPI",  # Inferred from Physical Interaction
  "IMP",  # Inferred from Mutant Phenotype
  "IGI",  # Inferred from Genetic Interaction
  "IEP",  # Inferred from Expression Pattern
  "HTP",  # Inferred from High Throughput Experiment
  "HDA",  # Inferred from High Throughput Direct Assay
  "HMP",  # Inferred from High Throughput Mutant Phenotype
  "HGI",  # Inferred from High Throughput Genetic Interaction
  "HEP"   # Inferred from High Throughput Expression Pattern
)

#' Computational evidence codes
#'
#' GAF evidence codes based on computational analysis rather than
#' direct experiment.
#'
#' @export
GAF_EVIDENCE_COMPUTATIONAL <- c(
  "ISS",  # Inferred from Sequence or Structural Similarity
  "ISO",  # Inferred from Sequence Orthology
  "ISA",  # Inferred from Sequence Alignment
  "ISM",  # Inferred from Sequence Model
  "IGC",  # Inferred from Genomic Context
  "IBA",  # Inferred from Biological Aspect of Ancestor
  "IBD",  # Inferred from Biological Aspect of Descendant
  "IKR",  # Inferred from Key Residues
  "IRD",  # Inferred from Rapid Divergence
  "RCA",  # Inferred from Reviewed Computational Analysis
  "IEA"   # Inferred from Electronic Annotation
)
