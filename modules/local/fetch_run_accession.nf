process FETCH_RUN_ACCESSION {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/entrez-direct_curl:8e1fff63811a14c6':
        'community.wave.seqera.io/library/entrez-direct_curl:38ebc0edc63c3e60' }"

    input:
    val(meta)

    output:
    tuple val(meta), path("${meta.id}_accession.csv") , emit: accession 

    script:
    def ena_prj_url = params.ena_prj_url ?: "https://www.ebi.ac.uk/ena/portal/api/search?result=read_run&query=study_accession=${meta.id}&fields=run_accession&format=csv"
    def ddbj_prj_url = params.ddbj_prj_url ?: "https://www.ebi.ac.uk/ena/portal/api/search?result=read_run&query=study_accession=${meta.id}&fields=experiment_accession&format=csv"

    if ( meta.source == "ENA")
        """
        curl -s "${ena_prj_url}" \\
        | tail -n +2 > ${meta.id}_accession.csv
        """
    else if ( meta.source == "NCBI")
        """
        esearch -db sra -query "${meta.id}" \\
        | efetch -format runinfo \\
        | cut -d ',' -f 1 \\
        | tail -n +2 > ${meta.id}_accession.csv
        """
    else if ( meta.source == "DDBJ" )
        """
        curl -s "${ddbj_prj_url}" \\
        | tail -n +2 \\
        | tr '\t' ',' > ${meta.id}_accession.csv
        """
}