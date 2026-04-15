process ENA_DATAGET {
    tag "${meta.run_id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/enabrowsertools:1.7.2--0d3f6123db2ffdf5':
        'community.wave.seqera.io/library/enabrowsertools:1.7.2--da63041b2d7f672c' }"

    input:
    val(meta)

    output:
    tuple val(meta), path("${meta.run_id}/*.fastq.gz")         , emit: fastq

    script:
    """
    enaDataGet.py -f fastq -m ${meta.run_id}
    """
}