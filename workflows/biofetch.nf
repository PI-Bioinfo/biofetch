#!/usr/bin/env nextflow
include { SRATOOLS_PREFETCH                      } from '../modules/nf-core/sratools/prefetch'
include { SRATOOLS_FASTERQDUMP                   } from '../modules/nf-core/sratools/fasterqdump'
include { CREATE_DESIGN                          } from '../modules/local/create_design'
include { FETCH_RUN_ACCESSION                    } from '../modules/local/fetch_run_accession'
include { CURL_DDBJ                              } from '../modules/local/curl_ddbj'
include { FFQ as FFQ_DDBJ                        } from '../modules/nf-core/ffq/main'
include { FFQ                                    } from '../modules/nf-core/ffq/main'
include { ENA_DATAGET                            } from '../modules/local/ena-browser-tools/enadataget'

workflow BIOFETCH {

    ch_accession                = Channel.empty()
    ch_project_accession        = Channel.empty()
    ch_run_accession            = Channel.empty()
    ch_retrieved_fastq          = Channel.empty()

    // Get accessions as channel
    if (file(params.input).exists()) {
        ch_samplesheet = Channel.fromPath( params.input, checkIfExists: true )
        ch_accession   = ch_accession.mix(ch_samplesheet.splitCsv( header: ["id"] ))
    } else {
        ch_accession   = ch_accession.mix( Channel.of(params.input).map{ value -> ["id" : value] } )
    }

    // Identify the source of ch_accession
    ch_accession.branch{ it ->
        def prefix = it.id.take(3)
        project:  prefix == "PRJ"
        study:    prefix != "PRJ"
    }.set { ch_branch_accession }

    ch_project_accession = ch_project_accession.mix(ch_branch_accession.project)
        .map { it ->
            def prefix = it.id.take(5)
            def source = [
                'PRJEB': 'ENA',
                'PRJNA': 'NCBI',
                'PRJDB': 'DDBJ'
            ][prefix] ?: 'UNKNOWN'
            return [ source: source, id: it.id ]
        }
    ch_run_accession = ch_run_accession.mix(ch_branch_accession.study)
        .map { it ->
            def prefix = it.id.take(3)
            def source = [
                'ERR': 'ENA',
                'GSE': 'NCBI',
                'DRR': 'DDBJ'
            ][prefix] ?: 'UNKNOWN'
            return [ source: source, id: it.id, run_id: it.id ]
        }

    FETCH_RUN_ACCESSION(
        ch_project_accession
    )

    FETCH_RUN_ACCESSION.out.accession
        .flatMap{ meta, accession_file ->
            def run_ids = accession_file.splitCsv( header: false )
            if( meta.source == 'DDBJ' ) {
                run_ids.collect { cols ->
                    meta + [
                        experiment_id: cols[1],
                        run_id       : cols[0]
                    ]
                }
            } else {
                run_ids.flatten().collect { run_id -> meta + [run_id: run_id] }
            }
        }
        .set{ ch_fetch_run_accession_output }

    ch_run_accession = ch_run_accession.mix( ch_fetch_run_accession_output )
        .branch {
            ENA:  it.source  == "ENA"
            NCBI: it.source  == "NCBI"
            DDBJ: it.source  == "DDBJ"
        }

    /*
    Module: Retrieving sequencing from ERR accession
    */

    ENA_DATAGET(
        ch_run_accession.ENA
    )

    ch_retrieved_fastq = ch_retrieved_fastq.mix(ENA_DATAGET.out.fastq)
    ch_run_accession.NCBI.map{ meta -> tuple(meta, meta.run_id) }
        .set{ ch_sratools_prefetech_input }

    /*
    Module: Retrieving sequencing data from DRR accession
    */
    ch_sra_fasterqdump_input = Channel.empty()
    CURL_DDBJ(
        ch_run_accession.DDBJ
    )

    ch_sra_fasterqdump_input = ch_sra_fasterqdump_input.mix(CURL_DDBJ.out.sra)
    

    /*
    Module: Retrieving sequencing data from SRA accession
    */
    if ( params.rand_select ) {
        ch_sratools_prefetech_input = ch_sratools_prefetech_input.randomSample( params.rand_select)
    }
    
    SRATOOLS_PREFETCH(
        ch_sratools_prefetech_input,
        [],
        []
    )
    ch_sra_fasterqdump_input = ch_sra_fasterqdump_input.mix(SRATOOLS_PREFETCH.out.sra)
    ch_sra_fasterqdump_input = ch_sra_fasterqdump_input.map{ meta, sra ->
            def new_meta = meta + ["single_end": true]
            return [new_meta, sra]
        }
    ch_sra_fasterqdump_input.take(5).view()
    SRATOOLS_FASTERQDUMP(
        ch_sra_fasterqdump_input,
        [],
        []
    )

    ch_retrieved_fastq = ch_retrieved_fastq.mix(SRATOOLS_FASTERQDUMP.out.reads)
    ch_retrieved_fastq.map{ meta, reads -> [source:meta.source, id:meta.id] }
        .collect()
        .map { it.unique() }
        .flatMap{ it }
        .set{ ch_design_input }

    ch_retrieved_fastq.map { meta, fastq -> meta.run_id }
        .collect()
        .set { ch_ffq_input }


    /*
    Module: Retrieving metadata
    */
    // FFQ(
    //     ch_ffq_input
    // )

    if ( !params.skip_design ) {    
        CREATE_DESIGN(
            ch_design_input
        )
    }
}