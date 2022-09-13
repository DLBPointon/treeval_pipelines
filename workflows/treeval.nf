/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowTreeval.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.fasta ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

<<<<<<< HEAD
=======
// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
>>>>>>> ca06873 (Remove local testing logic #4)
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
<<<<<<< HEAD
include { INPUT_READ        } from '../subworkflows/local/yaml_input'
include { GENERATE_GENOME   } from '../subworkflows/local/generate_genome'
include { INSILICO_DIGEST   } from '../subworkflows/local/insilico_digest'
include { GENE_ALIGNMENT } from '../subworkflows/local/gene_alignment'
=======
<<<<<<< HEAD
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { GENERATE_GENOME } from '../subworkflows/local/generate_genome'
>>>>>>> ca06873 (Remove local testing logic #4)
include { SYNTENY } from '../subworkflows/local/synteny'

// include { SELFCOMP          } from '../subworkflows/local/selfcomp'
// include { SYNTENY           } from '../subworkflows/local/synteny'
=======

include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { GENERATE_GENOME   } from '../subworkflows/local/generate_genome'
include { INSILICO_DIGEST   } from '../subworkflows/local/insilico_digest'
include { SYNTENY } from '../subworkflows/local/synteny'
>>>>>>> 3c3325b (Remove local testing logic #4)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TREEVAL {

    //
    // PRE-PIPELINE CHANNEL SETTING - channel setting for required files
    //
    ch_versions = Channel.empty()

    Channel
        .fromPath( 'assets/gene_alignment/assm_*.as', checkIfExists: true)
        .map { it -> 
            tuple ([ type    :   it.toString().split('/')[-1].split('_')[-1].split('.as')[0] ],
                    file(it)
                )}
        .set { gene_alignment_asfiles }
    
    Channel
        .fromPath( 'assets/digest/digest.as', checkIfExists: true )
        .set { digest_asfile }

    //
    // SUBWORKFLOW: reads the yaml and pushing out into a channel per yaml field
    //
    input_ch = Channel.fromPath(params.input, checkIfExists: true)

    INPUT_READ ( input_ch )

    //
    // SUBWORKFLOW: Takes input fasta file and sample ID to generate a my.genome file
    //    
    GENERATE_GENOME ( INPUT_CHECK.out.assembly_id, INPUT_CHECK.out.reference )
    ch_versions = ch_versions.mix(GENERATE_GENOME.out.versions)

    //
    //SUBWORKFLOW: 
    //
    ch_enzyme = Channel.of( "bspq1","bsss1","DLE1" )

    INSILICO_DIGEST ( INPUT_READ.out.assembly_id,
                      GENERATE_GENOME.out.dot_genome,
                      GENERATE_GENOME.out.reference_tuple,
                      ch_enzyme,
                      digest_asfile )
    ch_versions = ch_versions.mix(INSILICO_DIGEST.out.versions)

    //
    //SUBWORKFLOW: Takes input fasta to generate BB files containing alignment data
    //
    GENE_ALIGNMENT ( GENERATE_GENOME.out.dot_genome,
                     GENERATE_GENOME.out.reference_tuple,
                     INPUT_READ.out.assembly_classT,
                     INPUT_READ.out.align_data_dir,
                     INPUT_READ.out.align_geneset,
                     gene_alignment_asfiles )
    ch_versions = ch_versions.mix(GENERATE_GENOME.out.versions)

    //
    //SUBWORKFLOW: 
    //
    //SELFCOMP ( GENERATE_GENOME.out.reference_tuple,
    //           GENERATE_GENOME.out.dot_genome,
    //           INPUT_READ.out.mummer_chunk,
    //           INPUT_READ.out.motif_len,
    //           INPUT_READ.out.selfcomp_as )
    //ch_versions = ch_versions.mix(SELFCOMP.out.versions)

    //
    //SUBWORKFLOW: 
    //
    //SYNTENY ( GENERATE_GENOME.out.reference_tuple, as_file? )
    //ch_versions = ch_versions.mix(SYNTENY.out.versions)
    SYNTENY ( GENERATE_GENOME.out.reference_tuple, INPUT_CHECK.out.synteny_path,  INPUT_READ.out.assembly_class)
    ch_versions = ch_versions.mix(SYNTENY.out.versions)

    //
    // SUBWORKFLOW: Collates version data from prior subworflows
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
