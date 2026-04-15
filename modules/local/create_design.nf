process CREATE_DESIGN {
    tag "${meta.id}"
    label 'process_single'
    
    input:
    val meta

    output:
    path "${meta.id}_design.csv"              , emit: design

    script:
    def outdir = "${params.outdir}/${meta.source}/${meta.id}"
    """
    echo "project,run,fastq_1,fastq_2" > "${meta.id}_design.csv"

    for dir in ${outdir}/*; do
        [ -d "\$dir" ] || continue
        run_id=\$(basename "\$dir")
        fastqs=\$(find "\$dir" -type f \\( \\
            -name "*.fastq" -o -name "*.fastq.gz" -o \\
            -name "*.fq" -o -name "*.fq.gz" \\
        \\) | sort)
        echo "\$fastqs"
        count=\$(echo "\$fastqs" | wc -l)

        if [ "\$count" -eq 1 ]; then
            # single-end
            fq1=\$(echo "\$fastqs")
            echo "${meta.id},\$run_id,\$fq1," >> ${meta.id}_design.csv

        else
            # paired-end
            fq1=\$(echo "\$fastqs" | grep -E '(_R1|_1)\\.' | head -n 1)
            fq2=\$(echo "\$fastqs" | grep -E '(_R2|_2)\\.' | head -n 1)

            if [ -n "\$fq1" ] && [ -n "\$fq2" ]; then
                echo "${meta.id},\$run_id,\$fq1,\$fq2" >> ${meta.id}_design.csv
            else
                echo "WARNING: could not pair FASTQs in \$dir" >&2
            fi
        fi
    done
    """
}