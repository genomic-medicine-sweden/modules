process TAXPASTA_MERGE {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::taxpasta=0.1.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/taxpasta:0.1.1--pyhdfd78af_0':
        'quay.io/biocontainers/taxpasta:0.1.1--pyhdfd78af_0' }"


    input:
    tuple val(meta), path(profile)
    path samplesheet

    output:
    tuple val(meta), path("*.{tsv,csv,arrow,parquet,biom}"), emit: profiles
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Taxpasta requires a --profiler option and will fail without it.
    // That needs to be configured since we can't set a default here.
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    taxpasta merge \\
        $args \\
        $profile

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxpasta: \$(taxpasta --version)
    END_VERSIONS
    """
}