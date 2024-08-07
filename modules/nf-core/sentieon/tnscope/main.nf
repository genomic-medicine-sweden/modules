process SENTIEON_TNSCOPE {
    tag "$meta.id"
    label 'process_high'
    label 'sentieon'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/sentieon:202308.02--ffce1b7074ce9924' :
        'nf-core/sentieon:202308.02--c641bc397cbf79d5' }"

    input:
    tuple val(meta), path(bam), path(bai)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)
    tuple val(meta4), path(cosmic), path(cosmic_tbi)
    tuple val(meta5), path(pon), path(pon_tbi)
    tuple val(meta6), path(dbsnp), path(dbsnp_tbi)
    tuple val(meta7), path(interval)

    output:
    tuple val(meta), path("*.vcf.gz")    , emit: vcf
    tuple val(meta), path("*.vcf.gz.tbi"), emit: index
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args         = task.ext.args   ?: ''
    def args2        = task.ext.args2  ?: ''
    def interval_str = interval      ? "--interval ${interval}" : ''
    def cosmic_str = cosmic          ? "--cosmic ${cosmic}"          : ''
    def dbsnp_str  = dbsnp           ? "--dbsnp ${dbsnp}"            : ''
    def pon_str    = pon             ? "--pon ${pon}"                : ''
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def sentieonLicense = secrets.SENTIEON_LICENSE_BASE64 ?
        "export SENTIEON_LICENSE=\$(mktemp);echo -e \"${secrets.SENTIEON_LICENSE_BASE64}\" | base64 -d > \$SENTIEON_LICENSE; " :
        ""
    """
    $sentieonLicense

    sentieon driver \\
        -t $task.cpus \\
        -r $fasta \\
        -i $bam \\
        $interval_str \\
        $args \\
        --algo TNscope \\
        --tumor_sample ${meta.id} \\
        $args2 \\
        $cosmic_str \\
        $dbsnp_str \\
        $pon_str \\
        ${prefix}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sentieon: \$(echo \$(sentieon driver --version 2>&1) | sed -e "s/sentieon-genomics-//g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.vcf.gz
    touch ${prefix}.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sentieon: \$(echo \$(sentieon driver --version 2>&1) | sed -e "s/sentieon-genomics-//g" )
    END_VERSIONS
    """
}
