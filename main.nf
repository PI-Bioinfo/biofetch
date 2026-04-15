#!/usr/bin/env nextflow
include { BIOFETCH                              } from "${projectDir}/workflows/biofetch.nf"

workflow {
    BIOFETCH()
}