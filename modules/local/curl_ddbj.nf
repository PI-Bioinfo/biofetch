process CURL_DDBJ {
    tag "${meta.id}"
    label 'process_single'
    
    input:
    val(meta)

    output:
    tuple val(meta), path("${meta.run_id}/*sra")        , emit: sra

    script:
    def drx_id        = "${meta.experiment_id}".substring(3,6)
    def ddbj_sra_link = "ftp://ftp.ddbj.nig.ac.jp/ddbj_database/dra/sra/ByExp/sra/DRX/DRX${drx_id}"
    """
    mkdir -p ${meta.run_id}
    curl "${ddbj_sra_link}/${meta.experiment_id}/${meta.run_id}/${meta.run_id}.sra" -o ${meta.run_id}/${meta.run_id}.sra
    """
}