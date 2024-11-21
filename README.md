Collection of practices. Documents are currently in [Wiki page](https://github.com/wdlingit/cop/wiki).

### scripts (hyper linked to related documents)

1. gb2tsv.pl: extract information in FEATURE section of genbank files into tab-delimited text format.
1. [isoformSummary.pl](https://github.com/wdlingit/cop/wiki/Summarize-ISOseq-isoforms): ISOseq isoform summarizing script.
1. [RPFpeptidePredict.pl](https://github.com/wdlingit/cop/wiki/Ribo-seq-based-ORF-prediction): Riboseq based ORF finding.
1. [GmtIntersectFisher.pl](https://github.com/wdlingit/cop/wiki/From-ontology-annotation-results-to-enrichment-computation): Enrichment computation with [GMT](https://docs.gsea-msigdb.org/#GSEA/Data_Formats/#gmt-gene-matrix-transposed-file-format-gmt) files.
1. [genOntoHeatmapData.pl](https://github.com/wdlingit/cop/wiki/From-ontology-annotation-results-to-enrichment-computation): Generate heatmap data matrix based on enrichment results.
1. [genOntoDataframe.pl](https://github.com/wdlingit/cop/wiki/From-ontology-annotation-results-to-enrichment-computation): Generate dataframe based on enrichment results.
1. tsv2xlsx.pl: Translate a TSV file into a XLSX file. Perl module Excel::Writer::XLSX is required.
1. xlsx2tsv.pl: Translate a data sheet in a XLSX file into a TSV file. Perl module Spreadsheet::ParseXLSX is required.

### documents

1. [General setup](https://github.com/wdlingit/cop/wiki/General-setup): General setup of used tools
1. [From ontology annotation results to enrichment computation](https://github.com/wdlingit/cop/wiki/From-ontology-annotation-results-to-enrichment-computation): (i) transferring an annotation table into a GSEA GMT file (ii) steps of enrichment computation
1. [GFF3 handling, Araport11 AtRTD2 merge](https://github.com/wdlingit/cop/wiki/GFF3-handling,-Araport11-AtRTD2-merge)
1. [GFF3 handling, Araport11 example](https://github.com/wdlingit/cop/wiki/GFF3-handling,-Araport11-example)
1. [Ribo seq 3bp periodicity preference](https://github.com/wdlingit/cop/wiki/Ribo-seq-3bp-periodicity-preference): Example of computing 3bp periodicity preference of Ribo-seq data
1. [Ribo seq based ORF prediction](https://github.com/wdlingit/cop/wiki/Ribo-seq-based-ORF-prediction)
1. [Ribo seq read mapping](https://github.com/wdlingit/cop/wiki/Ribo-seq-read-mapping): A simple package for mapping Ribo-seq reads and computing expression levels. The default setting is for arabidopsis.
1. [Ribo seq read mapping, customization example](https://github.com/wdlingit/cop/wiki/Ribo-seq-read-mapping,-customization-example): A walkthrough example of a multi-stage approach for mapping Ribo-seq reads (of one sample).
1. [Riboseq multi stage mapping and filtering](https://github.com/wdlingit/cop/wiki/Riboseq-multi-stage-mapping-and-filtering): This is an index page pointing to parts of a complete procedure that we applied to a number of Riboseq read datasets for mapping them to the arabidopsis genome. In the procedure, we tried leveraging on existing genome annotation and supports from available RNAseq datasets. Given that reads been adapter clipped by tools like cutadapt and not filtered by rRNA read removal tools like sortmerna, the procedure used to map our Riboseq read datasets to the arabidopsis genome with mapping ratios more than 90%.
1. [Summarize ISOseq isoforms](https://github.com/wdlingit/cop/wiki/Summarize-ISOseq-isoforms): This page describes programs and terminologies applied in the paper An improved repertoire of splicing variants and their potential roles in Arabidopsis photomorphogenic development (PMID: 35139889). The programs and scripts applied are aimed to: (i) compare isoforms detected in ISOseq reads against database gene models and report alternative splicing events in reads (ii) summarize detected existing and novel isoforms for comparing samples in terms of expressed isoforms.
