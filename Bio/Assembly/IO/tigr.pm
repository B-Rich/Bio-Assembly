#
# BioPerl module for Bio::Assembly::IO::tigr
#
# Copyright by Florent Angly
#
# You may distribute this module under the same terms as Perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Assembly::IO::tigr - Driver to read and write assembly files in the TIGR
Assembler v2 default format.

=head1 SYNOPSIS

    # Building an input stream
    use Bio::Assembly::IO;

    # Assembly loading methods
    my $asmio = Bio::Assembly::IO->new( -file   => 'SGC0-424.tasm',
                                        -format => 'tigr' );
    my $scaffold = $asmio->next_assembly;

    # Do some things on contigs...

    # Assembly writing methods
    my $outasm = Bio::Assembly::IO->new( -file   => ">SGC0-modified.tasm",
                                         -format => 'tigr' );
    $outasm->write_assembly( -scaffold => $assembly,
                             -singlets => 1 );

=head1 DESCRIPTION

This package loads and writes assembly information in/from files in the default
TIGR Assembler v2 format. The files are lassie-formatted and often have the
.tasm extension. This module was written to be used as a driver module for
Bio::Assembly::IO input/output.

=head2 Implementation

Assemblies are loaded into Bio::Assembly::Scaffold objects composed of
Bio::Assembly::Contig and Bio::Assembly::Singlet objects. Since aligned reads
and contig gapped consensus can be obtained in the tasm files, only
aligned/gapped sequences are added to the different BioPerl objects.

Additional assembly information is stored as features. Contig objects have
SeqFeature information associated with the primary_tag:

    _main_contig_feature:$contig_id -> misc contig information
    _quality_clipping:$read_id      -> quality clipping position

Read objects have sub_seqFeature information associated with the
primary_tag:

    _main_read_feature:$read_id     -> misc read information

Singlets are considered by TIGR Assembler as contigs of one sequence and are
represented here with features having these primary_tag: 

    _main_contig_feature:$contig_id
    _quality_clipping:$read_primary_id
    _main_read_feature:$read_primary_id
    _aligned_coord:$read_primary_id

=head1 THE TIGR TASM LASSIEFORMAT

=head2 Description

In the TIGR tasm lassie format, contigs are separated by a line containing a single
pipe character "|", whereas the reads in a contig are separated by a blank line.
Singlets can be present in the file and are represented as a contig
composed of a single sequence.

Other than the two above-mentioned separators, each line has an attribute name,
followed a tab and then an attribute value.

The tasm format is used by more TIGR applications than just TIGR Assembler.
Some of the attributes are not used by TIGR Assembler or have constant values.
They are indicated by an asterisk *

Contigs have the following attributes:

    asmbl_id   -> contig ID
    sequence   -> contig ungapped consensus sequence (ambiguities are lowercase)
    lsequence  -> gapped consensus sequence (lowercase ambiguities)
    quality    -> gapped consensus quality score (in hexadecimal)
    seq_id     -> *
    com_name   -> *
    type       -> *
    method     -> always 'asmg' *
    ed_status  -> *
    redundancy -> percent of redundancy of the contig consensus
    perc_N     -> percent of ambiguities in the contig consensus
    seq#       -> number of sequences in the contig
    full_cds   -> *
    cds_start  -> start of coding sequence *
    cds_end    -> end of coding sequence *
    ed_pn      -> name of editor (always 'GRA') *
    ed_date    -> date and time of edition
    comment    -> some comments *
    frameshift -> *

Each read has the following attributes:

    seq_name  -> read name
    asm_lend  -> position of first base on contig ungapped consensus sequence
    asm_rend  -> position of last base on contig ungapped consensus sequence
    seq_lend  -> start of quality-trimmed sequence (aligned read coordinates)
    seq_rend  -> end of quality-trimmed sequence (aligned read coordinates)
    best      -> always '0' *
    comment   -> some comments *
    db        -> database name associated with the sequence (e.g. >my_db|seq1234)
    offset    -> offset of the sequence (gapped consensus coordinates)
    lsequence -> aligned read sequence (ambiguities are uppercase)

When asm_rend E<lt> asm_lend, the sequence was on the complementary DNA strand but
its reverse complement is shown in the aligned sequence of the assembly file,
not the original read.

Ambiguities are reflected in the contig consensus sequence as
lowercase IUPAC characters: a c g t u m r w s y k x n . In the read
sequences, however, ambiguities are uppercase: M R W S Y K X N

=head2 Example

Example of a contig containing three sequences:

    sequence	CGATGCTGTACGGCTGTTGCGACAGATTGCGCTGGGTCGATACCGCGTTGGTGATCGGCTTGTTCAGCGGGCTCTGGTTCGGCGACAGCGCGGCGATCTTGGCGGCTGCGAAGGTTGCCGGCGCAATCATGCGCTGCTGACCGTTGACCTGGTCCTGCCAGTACACCCAGTCGCCCACCATGACCTTCAGCGCGTAGCTGTCACAGCCGGCTGTGGTCAGCGCAGTGGCGACGGTGGTGTAGGAGGCGCCAGCAACACCTTGGGTGATCATGTAGCAGCCTTCTGACAGGCCGTAGGTCAGCATGGTCGGCCACTGGGTACCAGTCAGTCGGGTCAACCGAGATTCGCAsCTGAGCGCCACTGCCGCGCAGAGCGTACATGCCCTTGCGGGTCGCGCCGGTAACACCATCCACGCCGATCAGAACTGCGTCGGTGATGGTGGTGTTACCCGAGGTGCCAGTGGTGAAGGCGACGGTCTGGGTGCTGGCCACAGGCGCCAGAGTGGTCGCGCCAACGGTGGCGATGACCAGTTGCGATGGGCCACGGATACCTGACTGCCCGTTGTTCACGGCGCTGACGATGTTCTGCCACAGCGCCAGGCCAGAGCCGGTGATGTTGTCGAACACTTCGGGCGCAACGCCAGGGAGCGAGACGGTCAGCTTCCAGCTCGAAGCAGCGGAGCCAGTAGCCAGGGCGGCGCTGAGCGAGTTGCCGAGCGTGCCGGTGTAGAACGCGGTCAGCGTGGCGCCGGTGGCGGCGGCAGTGTCCTTCAGCGCACTGGTCGCGGCGGTGTCGGTGCCGTCAGTGACGCGCACGGCGCGGATGTTCGAGGCGCCGCCCTGGATTGATACCGCCAGCGCGGTGCACAGGTCGTACTTGCGCACGGTCyGAGTGCCGAACTTCTGCGATGCGTCACCTGGCGAGCCGATAaGCGTGGCGCTGTTCACCGGCCCCCAGTCAGCAATGCCGACGATGCCGAGAATGTCAGTCGGGACGCCATTGATGTAGCGGGTCTTGGGCGCCACTATTTGTATGTACAAATCTGGCGCAGATAAAGCCGCCGTATTCAAATAACCAGCAGGATAGATAGGCATCACGCCTCCAGAATGAAAAAGGCCACCGATTAGGTGGCCTTTGTTGTGTTCGGCTGGCTGTTAGAGCAGCAGCCCGTTTTCCCGCGCAAACGCGAATGGGTCCTTGTCATGCTTCCTGCAATTGCAGGTAGGACAAAGAATTTGCAGGTTGGATTTGTCGTTCGATCCGCCCTTTGCAAGCGGGAACACGTGGTCAACGTGATACCCATCCCTTATGGATATAGTGCACATGGCGCATTTCCAGCGCTGAGCAGCCAGCAAAAATTTTATGTCGTCGCCGGTGTGTGAGCCGACAGCATTTTTCTTGCGAGCCTTGTATGTCCGCGAGAGTGAACGAACTTGCTCCTTGTTGGCTGTCTTCCAGAGCTTTTGAGTAAGCGCACAGAGATCCTTGTTTCTTGATCTCCACTCTCTGGTTGCGGAAAT
    lsequence	CGATGCTGTACGGCTGTTGCGACAGATTGCGCTGGGTCGATACCGCGTTGGTGATCGGCTTGTTCAGCGGGCTCTGGTTCGGCGACAGCGCGGCGATCTTGGCGGCTGCGAAGGTTGCCGGCGCAATCATGCGCTGCTGACCGTTGACCTGGTCCTGCCAGTACACCCAGTCGCCCACCATGACCTTCAGCGCGTAGCTGTCACAGCCGGCTGTGGTCAGCGCAGTGGCGACGGTGGTGTAGGAGGCGCCAGCAACACCTTGGGTGATCATGTAGCAGCCTTCTGACAGGCCGTAGGTCAGCATGGTCGGCCACTGGGTACCAGTCAGTCGGGTCAACCGAGATTCG-CAsCTGAGCGCCACTGCCGCGCAGAGCGTACATGCCCTTGCGGGTCGCGCCGGTAACACCATCCACGCCGATCAGAACTGCGTCGGTGATGGTGGTGTTACCCGAGGTGCCAGTGGTGAAGGCGACGGTCTGGGTGCTGGCCACAGGCGCCAGAGTGGTCGCGCCAACGGTGGCGATGACCAGTTGCGATGGGCCACGGATACCTGACTGCCCGTTGTTCACGGCGCTGACGATGTTCTGCCACAGCGCCAGGCCAGAGCCGGTGATGTTGTCGAACACTTCGGGCGCAACGCCAGGGAGCGAGACGGTCAGCTTCCAGCTCGAAGCAGCGGAGCCAGTAGCCAGGGCGGCGCTGAGCGAGTTGCCGAGCGTGCCGGTGTAGAACGCGGTCAGCGTGGCGCCGGTGGCGGCGGCAGTGTCCTTCAGCGCACTGGTCGCGGCGGTGTCGGTGCCGTCAGTGACGCGCACGGCGCGGATGTTCGAGGCGCCGCCCTGGATTGATACCGCCAGCGCGGTGCACAGGTCGTACTTGCGCACGGTCyGAGTGCCGAACTTCTGCGATGCGTCACCTGGCGAGCCGATAaGCGTGGCGCTGTTCACCGGCCCCCAGTCAGCAATGCCGACGATGCCGAGAATGTCAGTCGGGACGCCATTGATGTAGCGGGTCTTGGGCGCCACTATTTGTATGTACAAATCTGGCGCAGATAAAGCCGCCGTATTCAAATAACCAGCAGGATAGATAGGCATCACGCCTCCAGAATGAAAAAGGCCACCGATTAGGTGGCCTTTGTTGTGTTCGGCTGGCTGTTAGAGCAGCAGCCCGTTTTCCCGCGCAAACGCGAATGGGTCCTTGTCATGCTTCCTGCAATTGCAGGTAGGACAAAGAATTTGCAGGTTGGATTTGTCGTTCGATCCGCCCTTTGCAAGCGGGAACACGTGGTCAACGTGATACCCATCCCTTATGGATATAGTGCACATGGCGCATTTCCAGCGCTGAGCAGCCAGCAAAAATTTTATGTCGTCGCCGGTGTGTGAGCCGACAGCATTTTTCTTGCGAGCCTTGTATGTCCGCGAGAGTGAACGAACTTGCTCCTTGTTGGCTGTCTTCCAGAGCTTTTGAGTAAGCGCACAGAGATCCTTGTTTCTTGATCTCCACTCTCTGGTTGCGGAAAT
    quality	0x0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0505050505050505050E0505160505050505050505050505050505050505050505050505050505050303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0404040404040404041604040404040404040404040404040404040404040404040404040404040404040404040404040404040E0404040404040404040B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B
    asmbl_id	93
    seq_id	
    com_name	
    type	
    method	asmg
    ed_status	
    redundancy	1.11
    perc_N	0.20
    seq#	3
    full_cds	
    cds_start	
    cds_end	
    ed_pn	GRA
    ed_date	08/16/07 17:10:12
    comment	
    frameshift	

    seq_name	SDSU_RFPERU_010_C09.x01.phd.1
    asm_lend	1
    asm_rend	4423
    seq_lend	1
    seq_rend	442
    best	0
    comment	
    db	
    offset	0
    lsequence	CGATGCTGTACGGCTGTTGCGACAGATTGCGCTGGGTCGATACCGCGTTGGTGATCGGCTTGTTCAGCGGGCTCTGGTTCGGCGACAGCGCGGCGATCTTGGCGGCTGCGAAGGTTGCCGGCGCAATCATGCGCTGCTGACCGTTGACCTGGTCCTGCCAGTACACCCAGTCGCCCACCATGACCTTCAGCGCGTAGCTGTCACAGCCGGCTGTGGTCAGCGCAGTGGCGACGGTGGTGTAGGAGGCGCCAGCAACACCTTGGGTGATCATGTAGCAGCCTTCTGACAGGCCGTAGGTCAGCATGGTCGGCCACTGGGTACCAGTCAGTCGGGTCAACCGAGATTCG-CAGCTGAGCGCCACTGCCGCGCAGAGCGTACATGCCCTTGCGGGTCGCGCCGGTAACACCATCCACGCCGATCAGAACTGCGTCGGTGATGGTGG

    seq_name	SDSU_RFPERU_002_H12.x01.phd.1
    asm_lend	339
    asm_rend	940
    seq_lend	1
    seq_rend	602
    best	0
    comment	
    db	
    offset	338
    lsequence	CGAGATTCGCCACCTGAGCGCCACTGCCGCGCAGAGCGTACATGCCCTTGCGGGTCGCGCCGGTAACACCATCCACGCCGATCAGAACTGCGTCGGTGATGGTGGTGTTACCCGAGGTGCCAGTGGTGAAGGCGACGGTCTGGGTGCTGGCCACAGGCGCCAGAGTGGTCGCGCCAACGGTGGCGATGACCAGTTGCGATGGGCCACGGATACCTGACTGCCCGTTGTTCACGGCGCTGACGATGTTCTGCCACAGCGCCAGGCCAGAGCCGGTGATGTTGTCGAACACTTCGGGCGCAACGCCAGGGAGCGAGACGGTCAGCTTCCAGCTCGAAGCAGCGGAGCCAGTAGCCAGGGCGGCGCTGAGCGAGTTGCCGAGCGTGCCGGTGTAGAACGCGGTCAGCGTGGCGCCGGTGGCGGCGGCAGTGTCCTTCAGCGCACTGGTCGCGGCGGTGTCGGTGCCGTCAGTGACGCGCACGGCGCGGATGTTCGAGGCGCCGCCCTGGATTGATACCGCCAGCGCGGTGCACAGGTCGTACTTGCGCACGGTCCGAGTGCCGAACTTCTGCGATGCGTCACCTGGCGAGCCGATA-GCGTGGCGC

    seq_name	SDSU_RFPERU_009_E07.x01.phd.1
    asm_lend	880
    asm_rend	1520
    seq_lend	641
    seq_rend	1
    best	0
    comment	
    db	
    offset	8803
    lsequence	CGCACGGTCTGAGTGCCGAACTTCTGCGATGCGTCACCTGGCGAGCCGATAAGCGTGGCGCTGTTCACCGGCCCCCAGTCAGCAATGCCGACGATGCCGAGAATGTCAGTCGGGACGCCATTGATGTAGCGGGTCTTGGGCGCCACTATTTGTATGTACAAATCTGGCGCAGATAAAGCCGCCGTATTCAAATAACCAGCAGGATAGATAGGCATCACGCCTCCAGAATGAAAAAGGCCACCGATTAGGTGGCCTTTGTTGTGTTCGGCTGGCTGTTAGAGCAGCAGCCCGTTTTCCCGCGCAAACGCGAATGGGTCCTTGTCATGCTTCCTGCAATTGCAGGTAGGACAAAGAATTTGCAGGTTGGATTTGTCGTTCGATCCGCCCTTTGCAAGCGGGAACACGTGGTCAACGTGATACCCATCCCTTATGGATATAGTGCACATGGCGCATTTCCAGCGCTGAGCAGCCAGCAAAAATTTTATGTCGTCGCCGGTGTGTGAGCCGACAGCATTTTTCTTGCGAGCCTTGTATGTCCGCGAGAGTGAACGAACTTGCTCCTTGTTGGCTGTCTTCCAGAGCTTTTGAGTAAGCGCACAGAGATCCTTGTTTCTTGATCTCCACTCTCTGGTTGCGGAAAT
    |

...

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
BioPerl modules. Send your comments and suggestions preferably to the
BioPerl mailing lists. Your participation is much appreciated.

  bioperl-l@bioperl.org                 - General discussion
  http://bio.perl.org/MailList.html     - About the mailing lists

=head2 Reporting Bugs

Report bugs to the BioPerl bug tracking system to help us keep track
the bugs and their resolution. Bug reports can be submitted via email
or the web:

  bioperl-bugs@bio.perl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Florent E Angly

Email florent dot angly at gmail dot com

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a "_".

=cut

package Bio::Assembly::IO::tigr;

use strict;
use Bio::Seq::Quality;
use Bio::LocatableSeq;
use Bio::Assembly::IO;
use Bio::Assembly::Scaffold;
use Bio::Assembly::Contig;
use Bio::Assembly::Singlet;

use base qw(Bio::Assembly::IO);

my $progname = 'TIGR Assembler';

=head2 next_assembly

 Title   : next_assembly
 Usage   : my $scaffold = $asmio->next_assembly()
 Function: return the next assembly in the tasm-formatted stream
 Returns : Bio::Assembly::Scaffold object
 Args    : none

=cut

sub next_assembly {
    my $self = shift; # object reference
    
    # Create a new scaffold to hold the contigs
    my $scaffoldobj = Bio::Assembly::Scaffold->new(-source => $progname);
    
    # Contig and read related
    my $contigobj;
    my $iscontig = 1;
    my %contiginfo;
    my $isread = 0;
    my %readinfo;
    
    # Loop over all assembly file lines
    while ($_ = $self->_readline) {
        chomp;
        if ( /^\|/ ) {  # a line with a single pipe |
            # The end of a read from a contig, the start of a new contig
            $iscontig = 1;
            $isread   = 0;
            # Store read info
            if ($contiginfo{'seqnum'} > 1) {
                # This is a read in a contig
                my $readobj = $self->_store_read(\%readinfo, $contigobj);
            } elsif ($contiginfo{'seqnum'} == 1) {
                # This is a singlet
                my $singletobj = $self->_store_singlet(\%readinfo, \%contiginfo,
                    $scaffoldobj);
            } else {
                # That should not happen
                $self->throw("Unhandled exception");
            }
            # Clear read info
            undef %readinfo;
            # Clear contig info
            undef $contigobj;
            undef %contiginfo;
        } elsif ( /^$/ ) {  # a blank line
            if ($iscontig) {
                # The end of a contig, the start of a read in that contig
                $iscontig = 0;
                $isread   = 1;
                # Store contig info
                $contigobj = $self->_store_contig( \%contiginfo, $contigobj,
                    $scaffoldobj ) if $contiginfo{'seqnum'} > 1;
            } elsif ($isread) {
                # The end of read in a contig, the start of a new one in
                # the same contig
                $iscontig = 0;
                $isread   = 1;
                # Store read info
                if ($contiginfo{'seqnum'} > 1) {
                    # This is a read in a contig
                    my $readobj = $self->_store_read(\%readinfo, $contigobj);
                } elsif ($contiginfo{'seqnum'} == 1) {
                    # This is a singlet
                    my $singletobj = $self->_store_singlet(\%readinfo,
                        \%contiginfo, $scaffoldobj);
                } else {
                  # That should not happen
                  $self->throw("Unhandled exception");
                }
                # Clear read info
                undef %readinfo;
            } else {
                # That should not happen
                $self->throw("Unhandled exception");
            }
        } else {
            if ($iscontig) {
                # Parse contig
                if    (/^sequence\t(.*)/)     {$contiginfo{'sequence'}   = $1; next}
                elsif (/^lsequence\t(.*)/)    {$contiginfo{'lsequence'}  = $1; next}
                elsif (/^quality\t(.*)/)      {$contiginfo{'quality'}    = $1; next}
                elsif (/^asmbl_id\t(.*)/)     {$contiginfo{'asmbl_id'}   = $1; next}
                elsif (/^seq_id\t(.*)/)       {$contiginfo{'seq_id'}     = $1; next}
                elsif (/^com_name\t(.*)/)     {$contiginfo{'com_name'}   = $1; next}
                elsif (/^type\t(.*)/)         {$contiginfo{'type'}       = $1; next}
                elsif (/^method\t(.*)/)       {$contiginfo{'method'}     = $1; next}
                elsif (/^ed_status\t(.*)/)    {$contiginfo{'ed_status'}  = $1; next}
                elsif (/^redundancy\t(.*)/)   {$contiginfo{'redundancy'} = $1; next}
                elsif (/^perc_N\t(.*)/)       {$contiginfo{'perc_N'}     = $1; next}
                elsif (/^seq\#\t(.*)/)        {$contiginfo{'seqnum'}     = $1; next}
                elsif (/^full_cds\t(.*)/)     {$contiginfo{'full_cds'}   = $1; next}
                elsif (/^cds_start\t(.*)/)    {$contiginfo{'cds_start'}  = $1; next}
                elsif (/^cds_end\t(.*)/)      {$contiginfo{'cds_end'}    = $1; next}
                elsif (/^ed_pn\t(.*)/)        {$contiginfo{'ed_pn'}      = $1; next}
                elsif (/^ed_date\t(.*\s.*)/)  {$contiginfo{'ed_date'}    = $1; next}
                elsif (/^comment\t(.*)/)      {$contiginfo{'comment'}    = $1; next}
                elsif (/^frameshift\t(.*)/)   {$contiginfo{'frameshift'} = $1; next}
                else {
                    $self->throw("Format unknown at line $.:\n$_\nIs your file".
                        " really a TIGR Assembler tasm-formatted file?");
                }
            } elsif ($isread) {
                # Parse read info
                if    (/^seq_name\t(.*)/)  {$readinfo{'seq_name'}  = $1; next}
                elsif (/^asm_lend\t(.*)/)  {$readinfo{'asm_lend'}  = $1; next}
                elsif (/^asm_rend\t(.*)/)  {$readinfo{'asm_rend'}  = $1; next}
                elsif (/^seq_lend\t(.*)/)  {$readinfo{'seq_lend'}  = $1; next}
                elsif (/^seq_rend\t(.*)/)  {$readinfo{'seq_rend'}  = $1; next}
                elsif (/^best\t(.*)/)      {$readinfo{'best'}      = $1; next}
                elsif (/^comment\t(.*)/)   {$readinfo{'comment'}   = $1; next}
                elsif (/^db\t(.*)/)        {$readinfo{'db'}        = $1; next}
                elsif (/^offset\t(.*)/)    {$readinfo{'offset'}    = $1; next}
                elsif (/^lsequence\t(.*)/) {$readinfo{'lsequence'} = $1; next}
                else {
                    $self->throw("Format unknown at line $.:\n$_\nIs your file".
                        " really a TIGR Assembler tasm-formatted file?");
                }
            } else {
                # That shouldn't happen
                $self->throw("Unhandled exception");                
            }
        }
    }
    # Store read info for last read
    if (defined $contiginfo{'seqnum'}) {
        if ($contiginfo{'seqnum'} > 1) {
            # This is a read in a contig
            my $readobj = $self->_store_read(\%readinfo, $contigobj);
        } elsif ($contiginfo{'seqnum'} == 1) {
            # This is a singlet
            my $singletobj = $self->_store_singlet(\%readinfo, \%contiginfo,
                $scaffoldobj);
        } else {
            # That should not happen
            $self->throw("Unhandled exception");
        }
    }
    # Clear read info for last read
    undef %readinfo;
    # Clear contig info for last contig
    undef $contigobj;
    undef %contiginfo;
    
    $scaffoldobj->update_seq_list();
    
    return $scaffoldobj;
}

=head2 _qual_hex2dec

    Title   : _qual_hex2dec
    Usage   : my dec_quality = $self->_qual_hex2dec($hex_quality);
    Function: convert an hexadecimal quality score into a decimal quality score 
    Returns : string
    Args    : string

=cut

sub _qual_hex2dec {
    my ($self, $qual) = @_;
    $qual =~ s/^0x(.*)$/$1/;
    $qual =~ s/(..)/hex($1).' '/eg;
    return $qual;
}

=head2 _qual_dec2hex

    Title   : _qual_dec2hex
    Usage   : my hex_quality = $self->_qual_dec2hex($dec_quality);
    Function: convert a decimal quality score into an hexadecimal quality score 
    Returns : string
    Args    : string

=cut

sub _qual_dec2hex {
    my ($self, $qual) = @_;
    $qual =~ s/(\d+)\s*/sprintf('%02X', $1)/eg;
    $qual = '0x'.$qual;
    return $qual;
}

=head2 _store_contig

    Title   : _store_contig
    Usage   : my $contigobj; $contigobj = $self->_store_contig(
              \%contiginfo, $contigobj, $scaffoldobj);
    Function: store information of a contig belonging to a scaffold in the
              appropriate object
    Returns : Bio::Assembly::Contig object
    Args    : hash, Bio::Assembly::Contig, Bio::Assembly::Scaffold

=cut

sub _store_contig {
    my ($self, $contiginfo, $contigobj, $scaffoldobj) = @_;

    # Create a contig and attach it to scaffold
    $contigobj = Bio::Assembly::Contig->new(
        -id     => $$contiginfo{'asmbl_id'},
        -source => $progname,
        -strand => 1
    );
    $scaffoldobj->add_contig($contigobj);

    # Create a gapped consensus sequence and attach it to contig
    #$$contiginfo{'llength'} = length($$contiginfo{'lsequence'});
    my $consensus = Bio::LocatableSeq->new(
        -id    => $$contiginfo{'asmbl_id'},
        -seq   => $$contiginfo{'lsequence'},
        -start => 1,
    );
    $contigobj->set_consensus_sequence($consensus);

    # Create an gapped consensus quality score and attach it to contig
    $$contiginfo{'quality'} = $self->_qual_hex2dec($$contiginfo{'quality'});
    my $qual = Bio::Seq::Quality->new(
        -id   => $$contiginfo{'asmbl_id'},
        -qual => $$contiginfo{'quality'}
    );
    $contigobj->set_consensus_quality($qual);

    # Add other misc contig information as features of the contig
    my $contigtags = Bio::SeqFeature::Generic->new(
        -primary_tag => "_main_contig_feature:$$contiginfo{'asmbl_id'}",
        -start       => 1,
        -strand      => 1,
        -tag         => { 'seq_id'     => $$contiginfo{'seq_id'},
                          'com_name'   => $$contiginfo{'com_name'},
                          'type'       => $$contiginfo{'type'},
                          'method'     => $$contiginfo{'method'},
                          'ed_status'  => $$contiginfo{'ed_status'},
                          'full_cds'   => $$contiginfo{'full_cds'},
                          'cds_start'  => $$contiginfo{'cds_start'},
                          'cds_end'    => $$contiginfo{'cds_end'},
                          'ed_pn'      => $$contiginfo{'ed_pn'},
                          'ed_date'    => $$contiginfo{'ed_date'},
                          'comment'    => $$contiginfo{'comment'},
                          'frameshift' => $$contiginfo{'frameshift'} }
    );
    $contigobj->add_features([ $contigtags ], 1);

    return $contigobj;
}

=head2 _store_read

    Title   : _store_read
    Usage   : my $readobj = $self->_store_read(\%readinfo, $contigobj);
    Function: store information of a read belonging to a contig in the appropriate object
    Returns : Bio::LocatableSeq
    Args    : hash, Bio::Assembly::Contig

=cut

sub _store_read {
   my ($self, $readinfo, $contigobj) = @_;
   
   # Create an aligned read object
   #$$readinfo{'llength'} = length($$readinfo{'lsequence'});
   $$readinfo{'strand'}  = ($$readinfo{'seq_rend'} > $$readinfo{'seq_lend'} ? 1 : -1);
   my $readobj = Bio::LocatableSeq->new(
       # the ids of sequence objects are supposed to include the db name in it, i.e. "big_db|seq1234"
       # that's how sequence ids coming from the fasta parser are at least
       -display_id => $self->_merge_seq_name_and_db($$readinfo{'seq_name'}, $$readinfo{'db'}),
       -primary_id => $self->_merge_seq_name_and_db($$readinfo{'seq_name'}, $$readinfo{'db'}),
       -seq        => $$readinfo{'lsequence'},      
       -start      => 1,
       -strand     => $$readinfo{'strand'},
       -alphabet   => 'dna'
   );

   # Add read location and sequence to contig
   # (from 'ungapped consensus' to 'gapped consensus' coordinates)
   $$readinfo{'aln_start'} = $contigobj->change_coord('ungapped consensus', 'gapped consensus', $$readinfo{'asm_lend'});
   $$readinfo{'aln_end'}   = $contigobj->change_coord('ungapped consensus', 'gapped consensus', $$readinfo{'asm_rend'});   
   my $alncoord = Bio::SeqFeature::Generic->new(
       -primary_tag => $readobj->id,
       -start       => $$readinfo{'aln_start'},
       -end         => $$readinfo{'aln_end'},
       -strand      => $$readinfo{'strand'},
       -tag         => { 'contig' => $contigobj->id() }
   );
   $contigobj->set_seq_coord($alncoord, $readobj);
   
   # Add quality clipping read information in contig features
   # (from 'aligned read' to 'gapped consensus' coordinates)
   $$readinfo{'clip_start'} = $contigobj->change_coord('aligned '.$readobj->id, 'gapped consensus', $$readinfo{'seq_lend'});
   $$readinfo{'clip_end'}   = $contigobj->change_coord('aligned '.$readobj->id, 'gapped consensus', $$readinfo{'seq_rend'});
   my $clipcoord = Bio::SeqFeature::Generic->new(
       -primary_tag => '_quality_clipping:'.$readobj->id,
       -start       => $$readinfo{'clip_start'},
       -end         => $$readinfo{'clip_end'},
       -strand      => $$readinfo{'strand'}
   );
   $clipcoord->attach_seq($readobj);
   $contigobj->add_features([ $clipcoord ], 0);
   
   # Add other misc read information as subsequence feature
   my $readtags = Bio::SeqFeature::Generic->new(
       -primary_tag => '_main_read_feature:'.$readobj->id,
       -start       => $$readinfo{'aln_start'},
       -end         => $$readinfo{'aln_end'},
       -strand      => $$readinfo{'strand'},
       -tag         => { 'best'    => $$readinfo{'best'},
                         'comment' => $$readinfo{'comment'} }
   );
   $alncoord->add_sub_SeqFeature($readtags);

   return $readobj;
}

=head2 _store_singlet

    Title   : _store_singlet
    Usage   : my $singletobj = $self->_store_read(\%readinfo, \%contiginfo,
                  $scaffoldobj);
    Function: store information of a singlet belonging to a scaffold in the appropriate object
    Returns : Bio::Assembly::Singlet
    Args    : hash, hash, Bio::Assembly::Scaffold

=cut

sub _store_singlet {
    my ($self, $readinfo, $contiginfo, $scaffoldobj) = @_;
    # Singlets in TIGR_Assembler are represented as a contig of one sequence
    # We try to simulate this duality by playing around with the Singlet object
    
    my $contigid = $$contiginfo{'asmbl_id'};
    my $readid   = $self->_merge_seq_name_and_db($$readinfo{'seq_name'}, $$readinfo{'db'});
    
    # Create a sequence object
    #$$contiginfo{'llength'} = length($$contiginfo{'lsequence'});
    my $seqobj = Bio::Seq::Quality->new(
       -primary_id => $contigid, # unique id in assembly (contig name)
       -display_id => $readid,
       -seq        => $$contiginfo{'lsequence'}, # do not use $$readinfo as ambiguities are uppercase
       -start      => 1,
       -strand     => $$readinfo{'strand'},
       -alphabet   => 'dna',
       -qual => $self->_qual_hex2dec($$contiginfo{'quality'})    
   );

   # Create singlet from sequence and add it to scaffold
   my $singletobj = Bio::Assembly::Singlet->new;
   $singletobj->seq_to_singlet($seqobj);
   $scaffoldobj->add_singlet($singletobj);

   # Add other misc contig information as features of the singlet
   my $contigtags = Bio::SeqFeature::Generic->new(
        -primary_tag => "_main_contig_feature:$contigid",
        -start       => 1,
        -strand      => 1,
        -tag         => { 'seq_id'     => $$contiginfo{'seq_id'},
                          'com_name'   => $$contiginfo{'com_name'},
                          'type'       => $$contiginfo{'type'},
                          'method'     => $$contiginfo{'method'},
                          'ed_status'  => $$contiginfo{'ed_status'},
                          'full_cds'   => $$contiginfo{'full_cds'},
                          'cds_start'  => $$contiginfo{'cds_start'},
                          'cds_end'    => $$contiginfo{'cds_end'},
                          'ed_pn'      => $$contiginfo{'ed_pn'},
                          'ed_date'    => $$contiginfo{'ed_date'},
                          'comment'    => $$contiginfo{'comment'},
                          'frameshift' => $$contiginfo{'frameshift'} }
   );
   $singletobj->add_features([ $contigtags ], 1);

   # Add read location and sequence to singlet features
   # (from 'ungapped consensus' to 'gapped consensus' coordinates)
   $$readinfo{'aln_start'} = $$readinfo{'asm_lend'};
   $$readinfo{'aln_end'}   = $$readinfo{'asm_rend'};
   my $alncoord = Bio::SeqFeature::Generic->new(
       -primary_tag => "_aligned_coord:$readid",
       -start       => $$readinfo{'aln_start'},
       -end         => $$readinfo{'aln_end'},
       -strand      => $$readinfo{'strand'},
       -tag         => { 'contig' => $contigid }
   );
   $alncoord->attach_seq($singletobj->seqref);
   $singletobj->add_features([ $alncoord ], 0);

   # Add quality clipping read information in singlet features
   # (from 'aligned read' to 'gapped consensus' coordinates)
   $$readinfo{'clip_start'} = $$readinfo{'seq_lend'};
   $$readinfo{'clip_end'}   = $$readinfo{'seq_rend'};
   my $clipcoord = Bio::SeqFeature::Generic->new(
       -primary_tag => "_quality_clipping:$readid",
       -start       => $$readinfo{'clip_start'},
       -end         => $$readinfo{'clip_end'},
       -strand      => $$readinfo{'strand'},
       -tag         => { 'contig' => $contigid }
   );
   $clipcoord->attach_seq($singletobj->seqref);
   $singletobj->add_features([ $clipcoord ], 0);
   
   # Add other misc read information as subsequence feature
   my $readtags = Bio::SeqFeature::Generic->new(
       -primary_tag => "_main_read_feature:$readid",
       -start       => $$readinfo{'aln_start'},
       -end         => $$readinfo{'aln_end'},
       -strand      => $$readinfo{'strand'},
       -tag         => { 'best'    => $$readinfo{'best'},
                         'comment' => $$readinfo{'comment'} }
   );
   $alncoord->add_sub_SeqFeature($readtags);
      
   return $singletobj;
}

=head2 write_assembly

    Title   : write_assembly
    Usage   : $ass_io->write_assembly($assembly)
    Function: Write the assembly object in TIGR Assembler compatible tasm lassie  
              format
    Returns : 1 on success, 0 for error
    Args    : A Bio::Assembly::Scaffold object

=cut

sub write_assembly {
    my ($self,@args) = @_;    
    my ($scaffoldobj, $singlets) = $self->_rearrange([qw(SCAFFOLD SINGLETS)], @args);
    
    # Sanity check
    if ( !$scaffoldobj || !$scaffoldobj->isa('Bio::Assembly::Scaffold') ) {
        $self->warn("Must provide a Bio::Align::AlignI object when calling
            write_assembly");
        next;
    }

    # Get list of objects - contigs and singlets
    my @cont_ids = $scaffoldobj->get_contig_ids;
    my @sing_ids = $scaffoldobj->get_singlet_ids;
    my %did;
    my $decimal_format = '%.2f';
    for (my $i = 0; $i < scalar @sing_ids ; $i++) {
      # singlet display id (string)
      my $display_id = $sing_ids[$i];
      # singlet primary id (unique, numerical)
      my $primary_id = $scaffoldobj->get_singlet_by_id($display_id)->seqref->primary_id;
      $sing_ids[$i] = $primary_id;
      $did{$primary_id} = $display_id;
    }
    my @ids = (@cont_ids, @sing_ids);
    @ids = sort { $a <=> $b } @ids; # list with contig ids and singlet primary id
    my $numobj = scalar @ids;

    # Output all contigs and singlets (sorted by increasing id number)
    for (my $i = 0 ; $i < $numobj ; $i++) {
        
        my $objid = $ids[$i];
        
        if (defined $did{$objid}) { 
            # This is a singlet
            next unless ($singlets);

            my $contigid = $objid;
            my $readid   = $did{$objid};            
            my $singletobj = $scaffoldobj->get_singlet_by_id($readid);
            
            # Get contig information
            my $contanno = (grep
                { $_->primary_tag eq "_main_contig_feature:$contigid" }
                $singletobj->get_features_collection->get_all_features
            )[0];
            my %contiginfo;
            $contiginfo{'sequence'}   = $singletobj->seqref->seq;
            $contiginfo{'lsequence'}  = $contiginfo{'sequence'};
            $contiginfo{'quality'}    = $self->_qual_dec2hex(
                join ' ', @{$singletobj->seqref->qual});
            $contiginfo{'asmbl_id'}   = $contigid;
            $contiginfo{'seq_id'}     = ($contanno->get_tag_values('seq_id'))[0];   
            $contiginfo{'com_name'}   = ($contanno->get_tag_values('com_name'))[0];
            $contiginfo{'type'}       = ($contanno->get_tag_values('type'))[0];
            $contiginfo{'method'}     = ($contanno->get_tag_values('method'))[0];
            $contiginfo{'ed_status'}  = ($contanno->get_tag_values('ed_status'))[0];
            $contiginfo{'redundancy'} = sprintf($decimal_format, 1);
            $contiginfo{'perc_N'}     = sprintf(
                $decimal_format, $self->_perc_N($contiginfo{'sequence'}));
            $contiginfo{'seqnum'}     = 1;
            $contiginfo{'full_cds'}   = ($contanno->get_tag_values('full_cds'))[0];
            $contiginfo{'cds_start'}  = ($contanno->get_tag_values('cds_start'))[0];
            $contiginfo{'cds_end'}    = ($contanno->get_tag_values('cds_end'))[0];
            $contiginfo{'ed_pn'}      = ($contanno->get_tag_values('ed_pn'))[0];
            $contiginfo{'ed_date'}    = $self->_date_time;
            $contiginfo{'comment'}    = ($contanno->get_tag_values('comment'))[0];
            $contiginfo{'frameshift'} = ($contanno->get_tag_values('frameshift'))[0];

            # Check that no tag value is undef
            $contiginfo{'seq_id'}     = '' unless defined $contiginfo{'seq_id'};
            $contiginfo{'com_name'}   = '' unless defined $contiginfo{'com_name'};
            $contiginfo{'type'}       = '' unless defined $contiginfo{'type'};
            $contiginfo{'method'}     = '' unless defined $contiginfo{'method'};
            $contiginfo{'ed_status'}  = '' unless defined $contiginfo{'ed_status'};
            $contiginfo{'full_cds'}   = '' unless defined $contiginfo{'full_cds'};
            $contiginfo{'cds_start'}  = '' unless defined $contiginfo{'cds_start'};
            $contiginfo{'cds_end'}    = '' unless defined $contiginfo{'cds_end'};
            $contiginfo{'ed_pn'}      = '' unless defined $contiginfo{'ed_pn'};
            $contiginfo{'comment'}    = '' unless defined $contiginfo{'comment'};
            $contiginfo{'frameshift'} = '' unless defined $contiginfo{'frameshift'};
            
            # Print contig information
            $self->_print(
                "sequence\t$contiginfo{'sequence'}\n".
                "lsequence\t$contiginfo{'lsequence'}\n".
                "quality\t$contiginfo{'quality'}\n".
                "asmbl_id\t$contiginfo{'asmbl_id'}\n".
                "seq_id\t$contiginfo{'seq_id'}\n".
                "com_name\t$contiginfo{'com_name'}\n".
                "type\t$contiginfo{'type'}\n".
                "method\t$contiginfo{'method'}\n".
                "ed_status\t$contiginfo{'ed_status'}\n".
                "redundancy\t$contiginfo{'redundancy'}\n".
                "perc_N\t$contiginfo{'perc_N'}\n".
                "seq#\t$contiginfo{'seqnum'}\n".
                "full_cds\t$contiginfo{'full_cds'}\n".
                "cds_start\t$contiginfo{'cds_start'}\n".
                "cds_end\t$contiginfo{'cds_end'}\n".
                "ed_pn\t$contiginfo{'ed_pn'}\n".
                "ed_date\t$contiginfo{'ed_date'}\n".
                "comment\t$contiginfo{'comment'}\n".
                "frameshift\t$contiginfo{'frameshift'}\n".
                "\n"
            );
                        
            # Get read information
            my ($seq_name, $db) = $self->_split_seq_name_and_db($readid);
            my $clipcoord = (grep
                { $_->primary_tag eq "_quality_clipping:$readid"}
                $singletobj->get_features_collection->get_all_features
            )[0];
            my $alncoord  = (grep
                { $_->primary_tag eq "_aligned_coord:$readid"}
                $singletobj->get_features_collection->get_all_features
            )[0];
            my $readanno = (grep
                { $_->primary_tag eq "_main_read_feature:$readid" }
                $singletobj->get_seq_coord($singletobj->seqref)->get_SeqFeatures
            )[0];
            my %readinfo;
            $readinfo{'seq_name'}  = $seq_name;
            $readinfo{'asm_lend'}  = $alncoord->location->start;
            $readinfo{'asm_rend'}  = $alncoord->location->end;
            $readinfo{'seq_lend'}  = $clipcoord->location->start;
            $readinfo{'seq_rend'}  = $clipcoord->location->end;
            $readinfo{'best'}      = ($readanno->get_tag_values('best'))[0];
            $readinfo{'comment'}   = ($readanno->get_tag_values('comment'))[0];
            $readinfo{'db'}        = $db;         
            $readinfo{'offset'}    = 0;
            # ambiguities in read sequence are uppercase
            $readinfo{'lsequence'} = uc($contiginfo{'lsequence'});
            
            # Check that no tag value is undef
            $readinfo{'best'}    = '' unless defined $readinfo{'best'};
            $readinfo{'comment'} = '' unless defined $readinfo{'comment'};

            # Print read information
            $self->_print(
                "seq_name\t$readinfo{'seq_name'}\n".
                "asm_lend\t$readinfo{'asm_lend'}\n".
                "asm_rend\t$readinfo{'asm_rend'}\n".
                "seq_lend\t$readinfo{'seq_lend'}\n".
                "seq_rend\t$readinfo{'seq_rend'}\n".
                "best\t$readinfo{'best'}\n".
                "comment\t$readinfo{'comment'}\n".
                "db\t$readinfo{'db'}\n".
                "offset\t$readinfo{'offset'}\n".
                "lsequence\t$readinfo{'lsequence'}\n"
            );
            if ($i+1 < $numobj) {
                $self->_print("|\n");
            }
        } else {
            # This is a contig
            my $contigid = $objid;
            my $contigobj = $scaffoldobj->get_contig_by_id($contigid);

            # Skip contigs of 1 sequence (singlets) if needed
            next if ($contigobj->no_sequences == 1) && (!$singlets);
            
            # Get contig information
            my $contanno = (grep
                { $_->primary_tag eq "_main_contig_feature:$contigid" }
                $contigobj->get_features_collection->get_all_features
            )[0];
            my %contiginfo;
            $contiginfo{'sequence'}   = $self->_ungap(
                $contigobj->get_consensus_sequence->seq);
            $contiginfo{'lsequence'}  = $contigobj->get_consensus_sequence->seq;
            $contiginfo{'quality'}    = $self->_qual_dec2hex(
                join ' ', @{$contigobj->get_consensus_quality->qual});
            $contiginfo{'asmbl_id'}   = $contigid;
            $contiginfo{'seq_id'}     = ($contanno->get_tag_values('seq_id'))[0];
            $contiginfo{'com_name'}   = ($contanno->get_tag_values('com_name'))[0];
            $contiginfo{'type'}       = ($contanno->get_tag_values('type'))[0];
            $contiginfo{'method'}     = ($contanno->get_tag_values('method'))[0];
            $contiginfo{'ed_status'}  = ($contanno->get_tag_values('ed_status'))[0];
            $contiginfo{'redundancy'} = sprintf(
                $decimal_format, $self->_redundancy($contigobj));
            $contiginfo{'perc_N'}     = sprintf(
                $decimal_format, $self->_perc_N($contiginfo{'sequence'}));
            $contiginfo{'seqnum'}     = $contigobj->no_sequences;
            $contiginfo{'full_cds'}   = ($contanno->get_tag_values('full_cds'))[0];
            $contiginfo{'cds_start'}  = ($contanno->get_tag_values('cds_start'))[0];
            $contiginfo{'cds_end'}    = ($contanno->get_tag_values('cds_end'))[0];
            $contiginfo{'ed_pn'}      = ($contanno->get_tag_values('ed_pn'))[0];
            $contiginfo{'ed_date'}    = $self->_date_time;
            $contiginfo{'comment'}    = ($contanno->get_tag_values('comment'))[0];
            $contiginfo{'frameshift'} = ($contanno->get_tag_values('frameshift'))[0];
            
            # Check that no tag value is undef
            $contiginfo{'seq_id'}     = '' unless defined $contiginfo{'seq_id'};
            $contiginfo{'com_name'}   = '' unless defined $contiginfo{'com_name'};
            $contiginfo{'type'}       = '' unless defined $contiginfo{'type'};
            $contiginfo{'method'}     = '' unless defined $contiginfo{'method'};
            $contiginfo{'ed_status'}  = '' unless defined $contiginfo{'ed_status'};
            $contiginfo{'full_cds'}   = '' unless defined $contiginfo{'full_cds'};
            $contiginfo{'cds_start'}  = '' unless defined $contiginfo{'cds_start'};
            $contiginfo{'cds_end'}    = '' unless defined $contiginfo{'cds_end'};
            $contiginfo{'ed_pn'}      = '' unless defined $contiginfo{'ed_pn'};
            $contiginfo{'comment'}    = '' unless defined $contiginfo{'comment'};
            $contiginfo{'frameshift'} = '' unless defined $contiginfo{'frameshift'};
                       
            # Print contig information
            $self->_print(
                "sequence\t$contiginfo{'sequence'}\n".
                "lsequence\t$contiginfo{'lsequence'}\n".
                "quality\t$contiginfo{'quality'}\n".
                "asmbl_id\t$contiginfo{'asmbl_id'}\n".
                "seq_id\t$contiginfo{'seq_id'}\n".
                "com_name\t$contiginfo{'com_name'}\n".
                "type\t$contiginfo{'type'}\n".
                "method\t$contiginfo{'method'}\n".
                "ed_status\t$contiginfo{'ed_status'}\n".
                "redundancy\t$contiginfo{'redundancy'}\n".
                "perc_N\t$contiginfo{'perc_N'}\n".
                "seq#\t$contiginfo{'seqnum'}\n".
                "full_cds\t$contiginfo{'full_cds'}\n".
                "cds_start\t$contiginfo{'cds_start'}\n".
                "cds_end\t$contiginfo{'cds_end'}\n".
                "ed_pn\t$contiginfo{'ed_pn'}\n".
                "ed_date\t$contiginfo{'ed_date'}\n".
                "comment\t$contiginfo{'comment'}\n".
                "frameshift\t$contiginfo{'frameshift'}\n".
                "\n"
            );
            my $seqno = 0;
            for my $readobj ( $contigobj->each_seq() ) {
                $seqno++;
                
                # Get read information
                my ($seq_name, $db) = $self->_split_seq_name_and_db($readobj->id);
                my ($asm_lend, $asm_rend, $seq_lend, $seq_rend, $offset)
                    = $self->_coord($readobj, $contigobj);
                my $readanno = ( grep 
                    { $_->primary_tag eq '_main_read_feature:'.$readobj->primary_id }
                    $contigobj->get_seq_coord($readobj)->get_SeqFeatures
                )[0];
                my %readinfo;                
                $readinfo{'seq_name'}  = $seq_name;
                $readinfo{'asm_lend'}  = $asm_lend;
                $readinfo{'asm_rend'}  = $asm_rend;;
                $readinfo{'seq_lend'}  = $seq_lend;
                $readinfo{'seq_rend'}  = $seq_rend;                
                $readinfo{'best'}      = ($readanno->get_tag_values('best'))[0];
                $readinfo{'comment'}   = ($readanno->get_tag_values('comment'))[0];
                $readinfo{'db'}        = $db;
                $readinfo{'offset'}    = $offset;   
                $readinfo{'lsequence'} = $readobj->seq(); 
                         
                # Check that no tag value is undef
                $readinfo{'best'}    = '' unless defined $readinfo{'best'};
                $readinfo{'comment'} = '' unless defined $readinfo{'comment'};
    
                # Print read information
                $self->_print(
                    "seq_name\t$readinfo{'seq_name'}\n".
                    "asm_lend\t$readinfo{'asm_lend'}\n".
                    "asm_rend\t$readinfo{'asm_rend'}\n".
                    "seq_lend\t$readinfo{'seq_lend'}\n".
                    "seq_rend\t$readinfo{'seq_rend'}\n".
                    "best\t$readinfo{'best'}\n".
                    "comment\t$readinfo{'comment'}\n".
                    "db\t$readinfo{'db'}\n".
                    "offset\t$readinfo{'offset'}\n".
                    "lsequence\t$readinfo{'lsequence'}\n"
                );
                if ($seqno < $contiginfo{'seqnum'}) {
                    $self->_print("\n");
                } elsif (($seqno == $contiginfo{'seqnum'}) && ($i+1 < $numobj)) {
                    $self->_print("|\n");
                }
            }
        }
    }
    return 1;
}

=head2 _perc_N

    Title   : _perc_N
    Usage   : my $perc_N = $ass_io->_perc_N($sequence_string)
    Function: Calculate the percent of ambiguities in a sequence.
              M R W S Y K X N are regarded as ambiguites in an aligned read
              sequence by TIGR Assembler. In the case of a gapped contig
              consensus sequence, all lowercase symbols are ambiguities, i.e.:
              a c g t u m r w s y k x n.
    Returns : decimal number
    Args    : string

=cut

sub _perc_N {
    my ($self, $seq_string) = @_;
    $self->throw("Cannot accept an empty sequence") if length($seq_string) == 0;
    my $perc_N = 0;
    for my $base ( split //, $seq_string ) {
        # individual base matches an ambiguity?
        if (( $base =~ m/[x|n|m|r|w|s|y|k]/i ) || ( $base =~ m/[a|c|g|t|u]/ ) ) {
            $perc_N++;
        }
    }
    $perc_N = $perc_N * 100 / length $seq_string;
    return $perc_N;
}

=head2 _redundancy

    Title   : _redundancy
    Usage   : my $ref = $ass_io->_redundancy($contigobj)
    Function: Calculate the redundancy of a contig consensus (average
              number of read base pairs covering the consensus)
    Returns : decimal number
    Args    : Bio::Assembly::Contig

=cut

sub _redundancy {
    # redundancy = (sum of all aligned read lengths - ( number of gaps in gapped
    # consensus + number of gaps in aligned reads that are also in the consensus ) )
    # / length of ungapped consensus
    my ($self, $contigobj) = @_;
    my $redundancy = 0;
    
    # sum of all aligned read lengths
    my $read_tot = 0;
    for my $readobj ( $contigobj->each_seq ) {
        my $read_length = length($readobj->seq);
        $read_tot += $read_length;
    }
    $redundancy += $read_tot;
    
    # - respected gaps
    my $consensus_sequence = $contigobj->get_consensus_sequence->seq;
    my @consensus_gaps = ();
    $contigobj->_register_gaps($consensus_sequence, \@consensus_gaps);
    my $respected_gaps = scalar(@consensus_gaps);
    if ($respected_gaps > 0) {
        my @cons_arr = split //, $consensus_sequence;
        for my $gap_pos_cons ( @consensus_gaps ) {
            for my $readobj ( $contigobj->each_seq ) {
                my $readid = $readobj->id;
                my $read_start = $contigobj->change_coord(
                    "aligned $readid", 'gapped consensus', $readobj->start);
                my $read_end   = $contigobj->change_coord(
                    "aligned $readid", 'gapped consensus', $readobj->end  );
                # skip this if consensus gap position not within in the read boundaries
                next if ( ($gap_pos_cons < $read_start)
                    || ($gap_pos_cons > $read_end) );
                # does the read position have read have a gap?
                my @read_arr = split //, $readobj->seq;                
                my $gap_pos_read = $contigobj->change_coord(
                    'gapped consensus', "aligned $readid", $gap_pos_cons);
                if ($read_arr[$gap_pos_read-1] eq $cons_arr[$gap_pos_cons-1]) {
                    $respected_gaps++;
                }
            }
        }
    }
    $redundancy -= $respected_gaps;
    
    # / length of ungapped consensus
    my $contig_length = length($self->_ungap($contigobj->get_consensus_sequence->seq));
    $redundancy /= $contig_length;
    
    return $redundancy;
}

=head2 _ungap

    Title   : _ungap
    Usage   : my $ungapped = $ass_io->_ungap($gapped)
    Function: Remove the gaps from a sequence. Gaps are - in TIGR Assembler
    Returns : string
    Args    : string

=cut

sub _ungap {
    my ($self, $seq_string) = @_;
    $seq_string =~ s/-//g;
    return $seq_string;
}

=head2 _date_time

    Title   : _date_time
    Usage   : my $timepoint = $ass_io->date_time
    Function: Get date and time (MM//DD/YY HH:MM:SS)
    Returns : string
    Args    : none

=cut

sub _date_time {
    my ($self) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $formatted_date_time = 
        sprintf('%02d', $mon+1).'/'.
        sprintf('%02d', $mday).'/'.
        sprintf('%02d', $year % 100).
        ' '.
        sprintf('%02d', $hour).':'.
        sprintf('%02d', $min).':'.
        sprintf('%02d',$sec)
    ;
    return $formatted_date_time;
}

=head2 _split_seq_name_and_db

    Title   : _split_seq_name_and_db
    Usage   : my ($seqname, $db) = $ass_io->_split_seq_name_and_db($id)
    Function: Extract seq_name and db from sequence id
    Returns : seq_name, db
    Args    : id

=cut

sub _split_seq_name_and_db {
    my ($self, $id) = @_;
    my $seq_name = '';
    my $db       = '';
    if ($id =~ m/(\S+)\|(\S+)/) {
        $db       = $1;
        $seq_name = $2;
    } else {
        $seq_name = $id;
    }
    return ($seq_name, $db);
}

=head2 _merge_seq_name_and_db

    Title   : _merge_seq_name_and_db
    Usage   : my $id = $ass_io->_merge_seq_name_and_db($seq_name, $db)
    Function: Construct id from seq_name and db
    Returns : id
    Args    : seq_name, db

=cut

sub _merge_seq_name_and_db {
    my ($self, $seq_name, $db) = @_;
    my $id = '';
    if ($db) {
        $id = $db.'|'.$seq_name;
    } else {
        $id = $seq_name;
    }
    return $id;
}

=head2 _coord

    Title   : _coord
    Usage   : my $id = $ass_io->__coord($readobj, $contigobj)
    Function: Get different coordinates for the read
    Returns : number, number, number, number, number
    Args    : Bio::Assembly::Seq, Bio::Assembly::Contig

=cut

sub _coord {
    my ($self, $readobj, $contigobj) = @_;
    my ($asm_lend, $asm_rend, $seq_lend, $seq_rend, $offset) = (0, 0, 0, 0, 0);

    # Get read gapped consensus coordinates from contig and calculate
    # asm_lend and asm_rend in ungapped consensus
    my $aln_lend = $contigobj->get_seq_coord($readobj)->location->start;
    my $aln_rend = $contigobj->get_seq_coord($readobj)->location->end;
    $asm_lend = $contigobj->change_coord(
        'gapped consensus', 'ungapped consensus', $aln_lend);
    $asm_rend = $contigobj->change_coord(
        'gapped consensus', 'ungapped consensus', $aln_rend);
  
    # Get gapped consensus coordinates for quality-clipped reads from contig 
    # annotation and determine seq_lend and seq_rend in unaligned sequence coord
    my $readclip = (grep
        { $_->primary_tag eq '_quality_clipping:'.$readobj->primary_id }
        $contigobj->get_features_collection->get_all_features
    )[0];
    my $clip_lend = $readclip->location->start;
    my $clip_rend = $readclip->location->end;    
    $seq_lend = $contigobj->change_coord(
        'gapped consensus', 'aligned '.$readobj->id, $clip_lend);
    $seq_rend = $contigobj->change_coord(
        'gapped consensus', 'aligned '.$readobj->id, $clip_rend);    
    
    # Offset
    $offset = $aln_lend - 1;
    
    return ($asm_lend, $asm_rend, $seq_lend, $seq_rend, $offset);
}

1;

__END__
