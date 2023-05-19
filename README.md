# ![nf-core/treeval](docs/images/nf-core-treeval_logo_light.png#gh-light-mode-only) ![nf-core/treeval](docs/images/nf-core-treeval_logo_dark.png#gh-dark-mode-only)

[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/treeval/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/treeval)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23treeval-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/treeval)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

TreeVal is a modern replacement for the gEVAL pipelines previously in use at Sanger. This pipeline generates supplemental data for the use of genome curation, these data are uploaded to a local JBrowse2 instance for display.

**nf-core/treeval** is a bioinformatics best-practice analysis pipeline for A pipeline to generate jBrowse compatible datafiles for genome curation.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

## Test Data
We have included two test data sets:
- test_full: includes a full dataset of genome, pacbio, hic and geneset data.
- test: includes a truncated version of the above

Both test sets can be used for either the FULL or RAPID entry points.


## Pipeline summary

The version 1 pipeline will be made up of the following steps:

- INPUT_READ

  - The reading of the input yaml and conversion into channels for the sub-workflows.

- GENERATE_GENOME

  - Generate .genome for the input genome.
  - Uses SAMTOOLS FAIDX.

- GENERATE_ALIGNMENT

  - Peptides will run pep_alignment.nf

    - Uses Miniprot.

  - CDNA, RNA and CDS will run through nuc_alignment.nf
    - Uses Minimap2.

- INSILICO DIGEST

  - Generates a map of enzymatic digests using 3 Bionano enzymes
  - Uses Bionano software.

- SELFCOMP

  - Identifies regions of self-complementary sequence
  - Uses Mummer.

- SYNTENY

  - Generates syntenic alignments between other high quality genomes.
  - Uses Minimap2.

- ANCESTRAL ELEMENT ANALYSIS
  - Lepidopteran Element Analysis
    - Uses BUSCO and custom python scripts to parse ancestral lep genes
  - This will eventually have a number of clade specific sub-workflows.

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.10.1`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(you can use [`Conda`](https://conda.io/miniconda.html) both to install Nextflow itself and also to manage software within pipelines. Please only use it within pipelines as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_.

3. Download the pipeline and test it on a minimal dataset with a single command:

   ```bash
   nextflow run nf-core/treeval -profile test,YOURPROFILE --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   > - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Start running your own analysis!

   ```bash
   nextflow run main.nf  -profile singularity --input treeval.yaml
   ```

   Internally, where we use LSF. This command may look like:
   ```bash
    bsub -Is -tty -e error -o out -n 2 -q {QUEUE} -M4000 -R'select[mem>4000] rusage[mem=4000] span[hosts=1]' 'nextflow run main.nf -profile singularity,sanger --input treeval.yaml --outdir treeval_output -entry {FULL|RAPID}'
   ```

## Documentation

The nf-core/treeval pipeline comes with documentation about the pipeline [usage](https://nf-co.re/treeval/usage), [parameters](https://nf-co.re/treeval/parameters) and [output](https://nf-co.re/treeval/output).

## Credits

nf-core/treeval was originally written by Damon-Lee Pointon (@DLBPointon), Yumi Sims (@yumisims) and William Eagles (@weaglesBio).

We thank the following people for their extensive assistance in the development of this pipeline:

@muffato
@gq1
@ksenia-krasheninnikova
@priyanka-surana

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#treeval` channel](https://nfcore.slack.com/channels/treeval) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- If you use  nf-core/treeval for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

### Tools

BedTools

Bionano CMAP

BUSCO

Minimap2

Miniprot

Mummer

Python3

Samtools

TABIX

UCSC

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
