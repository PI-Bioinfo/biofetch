process GEO_TO_PRJ_ID {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/entrez-direct_curl:b4ef66c35d9a3323':
        'community.wave.seqera.io/library/entrez-direct_curl:a21faa318ca2ea3b' }"

    input:
    val(meta)

    output:
    tuple val(meta), path("${meta.id}_prj_id.txt") , emit: prj_id 

    script:
    """
    esearch -db gds -query ${meta.id} | efetch -format docsum | xtract -pattern DocumentSummary -element BioProject > ${meta.id}_prj_id.txt
    """
}