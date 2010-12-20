# $Id: ace.pm 16969 2010-05-09 15:26:53Z fangly $
#
## BioPerl module for Bio::Assembly::IO::ace
#
# Copyright by Robson F. de Souza (the reading part) and Florent Angly (the 
# writing and ACE variants part)
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Assembly::IO::ace - module to load ACE files from various assembly programs

=head1 SYNOPSIS

    # Building an input stream
    use Bio::Assembly::IO;

    # Load a reference ACE assembly
    my $in_io = Bio::Assembly::IO->new( -file   => 'results.ace',
                                        -format => 'ace'          );

    # Read the entire scaffold
    my $scaffold = $in_io->next_assembly;

    # Or read one contig at a time to save resources
    while ( my $contig = $in_io->next_contig ) {
      # Do something ...
    }

    # Assembly writing methods
    my $out_io = Bio::Assembly::IO->new( -file   => ">output.ace",
                                         -format => 'ace' );
    $out_io->write_assembly( -scaffold => $scaffold,
                             -singlets => 1 );

    # Read the '454' Newbler variant of ACE instead of the default 'consed'
    # reference ACE variant
    my $in_io = Bio::Assembly::IO->new( -file   => 'results.ace',
                                        -format => 'ace-454'      );
    # or ...
    my $in_io = Bio::Assembly::IO->new( -file    => 'results.ace',
                                        -format  => 'ace',
                                        -variant => '454'      );

=head1 DESCRIPTION

This package loads the standard ACE files generated by various assembly programs
(Phrap, CAP3, Newbler, Arachne, ...). It was written to be used as a driver
module for Bio::Assembly::IO input/output.

=head2 Implemention

Assemblies are loaded into Bio::Assembly::Scaffold objects composed by
Bio::Assembly::Contig and Bio::Assembly::Singlet objects. Only the ACE file is
used, so if you need singlets, make sure that they are present in the ACE file.

A brief description of the ACE format is available at
http://www.cbcb.umd.edu/research/contig_representation.shtml#ACE
Read the full format description from
http://bozeman.mbt.washington.edu/consed/distributions/README.14.0.txt

In addition to default "_aligned_coord:$seqID" feature class from
Bio::Assembly::Contig, contig objects loaded by this module will have the
following special feature classes in their feature collection:

"_align_clipping:$seqID" (AF)
    Location of subsequence in read $seqID which is aligned to the contig. The
    coordinates are relative to the contig. If no feature containing this tag is
    present the read is considered low quality by Consed.

"_quality_clipping:$seqID" (AF)
    The location of high quality subsequence in read $seqID (relative to contig)

"_base_segments" (BS)
    Location of read subsequences used to build the consensus

"_read_tags:$readID" (RT)
    Sequence features stored as sub_SeqFeatures of the sequence's coordinate
    feature (the corresponding "_aligned_coord:$seqID" feature, easily accessed
    through get_seq_coord() method).

"_read_desc:$readID" (DS)
    Sequence features stored as sub_SeqFeatures of the read's coordinate feature

"consensus tags" (CT)
    Equivalent to a bioperl sequence feature and, therefore, are added to the
    feature collection using their type field (see Consed's README.txt file) as
    primary tag.

"whole assembly tags" (WA)
    They have no start and end, as they are not associated to any particular
    sequence in the assembly, and are added to the assembly's annotation
    collection using "whole assembly" as tag.

=head2 Variants

The default ACE variant is called 'consed' and corresponds to the reference ACE
format.

The ACE files produced by the 454 GS Assembler (Newbler) do not conform to the
reference ACE format. In 454 ACE, the consensus sequence reported covers only
its clear range and the start of the clear range consensus is defined as position
1. Consequently, aligned reads in the contig can have negative positions. Be sure 
to use the '454' variant to have positive alignment positions. No attempt is made
to construct the missing part of the consensus sequence (beyond the clear range)
based on the underlying reads in the contig. Instead the ends of the consensus
are simply padded with the gap character '-'.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing lists  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Robson Francisco de Souza

Email rfsouza@citri.iq.usp.br

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

package Bio::Assembly::IO::ace;

use strict;

use Bio::Assembly::Scaffold;
use Bio::Assembly::Contig;
use Bio::Assembly::Singlet;
use Bio::LocatableSeq;
use Bio::Seq::PrimaryQual;
use Bio::Annotation::SimpleValue;
use Bio::SeqIO;
use Bio::SeqFeature::Generic;

use base qw(Bio::Assembly::IO);

our $line_width = 50;
our $qual_value = 20;
our %variant = ( 'consed' => undef, # default
                 '454'    => undef  );

=head1 Parser methods

=head2 next_assembly

 Title   : next_assembly
 Usage   : $scaffold = $stream->next_assembly()
 Function: returns the next assembly in the stream
 Returns : a Bio::Assembly::Scaffold object
 Args    : none

=cut

sub next_assembly {
    my $self = shift;

    my $assembly = Bio::Assembly::Scaffold->new();

    # Load contigs and singlets in the scaffold
    while ( my $obj = $self->next_contig() ) {
        # Add contig /singlet to assembly
        if ($obj->isa('Bio::Assembly::Singlet')) { # a singlet
            $assembly->add_singlet($obj);
        } else { # a contig
            $assembly->add_contig($obj);
        }
    }

    # Load annotations of assembly and contigs
    $self->scaffold_annotations($assembly);

    return $assembly;
}


=head2 next_contig

 Title   : next_contig
 Usage   : $scaffold = $stream->next_contig()
 Function: Returns the next contig or singlet in the ACE stream.
 Returns : a Bio::Assembly::Contig or Bio::Assembly::Single object
 Args    : none

=cut

sub next_contig {
    my ($self) = shift;
    local $/ = "\n";
    my $contigOBJ;
    my $read_name;
    my $min_start;
    my $read_data = {}; # Temporary holder for read data

    # Keep reading the ACE stream starting at where we stopped
    while ( $_ = $self->_readline) {
        chomp;

        # Loading contig sequence (COntig sequence field)
        if (/^CO\s(\S+)\s(\d+)\s(\d+)\s(\d+)\s(\w+)/xms) { # New contig starts!

            if (not $contigOBJ) {
                # Start a new contig object
                my $contigID = $1;      # Contig ID
                #my $nof_bases = $2;    # Contig length in base pairs
                my $nof_reads = $3;     # Number of reads in this contig
                #my $nof_segments = $4; # Number of read segments selected for consensus assembly
                my $ori = $5;           # 'C' if contig was complemented or U if not (default)
                $ori = $ori eq 'U' ? 1 : -1;

                # Create a singlet or contig
                if ($nof_reads == 1) { # This is a singlet
                    $contigOBJ = Bio::Assembly::Singlet->new( );
                } elsif ( $nof_reads > 1 ) { # This is a contig
                    $contigOBJ = Bio::Assembly::Contig->new( );
                }

                $contigOBJ->id($contigID);
                $contigOBJ->strand($ori);

                my $consensus_sequence;
                while ($_ = $self->_readline) { # Looping over contig lines
                    chomp;                      # Drop <ENTER> (\n) on current line
                    last if (/^$/);             # Stop if empty line (contig end) is found
                    s/\*/-/g;                   # Forcing '-' as gap symbol
                    $consensus_sequence .= $_;
                }
                $consensus_sequence = Bio::LocatableSeq->new(
                    -seq    => $consensus_sequence,
                    -start  => 1,
                    -strand => $ori,
                );
                $consensus_sequence->id($contigID);
                $contigOBJ->set_consensus_sequence($consensus_sequence);
            } else {
                # A second contig is about to start. Backtrack one line and go
                # to the return statement
                $self->_pushback($_);
                last;
            }
        }

        # Loading contig qualities... (Base Quality field)
        elsif (/^BQ/) {
            my $qual_string = '';
            while ($_ = $self->_readline) {
                chomp;
                last if (/^$/);
                $qual_string .= "$_ ";
            }
            my @qual_arr = $self->_input_qual($qual_string, $contigOBJ->get_consensus_sequence->seq);
            my $qual = Bio::Seq::PrimaryQual->new(-qual => join(" ", @qual_arr),
                                                  -id   => $contigOBJ->id()   );
            $contigOBJ->set_consensus_quality($qual);
        }

        # Loading read info... (Assembled From field)
        elsif (/^AF (\S+) (C|U) (-*\d+)/) {
            $read_name = $1; # read ID
            my $ori    = $2; # strand
            my $start  = $3; # aligned start

            $ori = $ori eq 'U' ? 1 : -1;
            $read_data->{$read_name}{'strand'}  = $ori; 
            $read_data->{$read_name}{'padded_start'} = $start;

            if ( $self->variant eq '454' ) {
                if ( (not defined $min_start) || ($start < $min_start) ) {
                    $min_start = $start;
                }
            }

        }

        # Base segments definitions (Base Segment field)
        # They indicate which read segments were used to calculate the consensus
        # Coordinates are relative to the contig
        elsif (/^BS (\d+) (\d+) (\S+)/) {
            my ($start, $end, $contig_id) = ($1, $2, $3);
            if ($self->variant eq '454') {
              $start += abs($min_start) + 1;
              $end   += abs($min_start) + 1;
            }
            my $bs_feat = Bio::SeqFeature::Generic->new(
                -start   => $start,
                -end     => $end,
                -strand  => 1,
                -primary => '_base_segments',
                -tag     => { 'contig_id' => $contig_id}
            );
            $contigOBJ->add_features([ $bs_feat ], 0);
        }

        # Loading reads... (ReaD sequence field)
        # They define the reads in each contig
        elsif (/^RD (\S+) (-*\d+) (\d+) (\d+)/) {
            $read_name = $1;
            $read_data->{$read_name}{'length'} = $2; # number_of_padded_bases
            $read_data->{$read_name}{'contig'} = $contigOBJ;
            # $read_data->{$read_name}{'number_of_read_info_items'} = $3;
            # $read_data->{$read_name}{'number_of_tags'}            = $4;

            # Add a read to a contig
            my $read_sequence;
            while ($_ = $self->_readline) {
                chomp;
                last if (/^$/);
                s/\*/-/g; # Forcing '-' as gap symbol
                $read_sequence .= $_; # aligned read sequence
            }
            my $read = Bio::LocatableSeq->new(
                -seq        => $read_sequence,
                -start      => 1,
                -strand     => $read_data->{$read_name}{'strand'},
                -id         => $read_name,
                -primary_id => $read_name,
                -alphabet   => 'dna'
            );
            # Adding read location and sequence to contig ("gapped consensus" coordinates)
            my $padded_start = $read_data->{$read_name}{'padded_start'};
            if ($self->variant eq '454') {
              $padded_start += abs($min_start) + 1;
            }
            my $padded_end   = $padded_start + $read_data->{$read_name}{'length'} - 1;
            my $coord = Bio::SeqFeature::Generic->new(
                -start  => $padded_start,
                -end    => $padded_end,
                -strand => $read_data->{$read_name}{'strand'},
                -tag    => { 'contig' => $contigOBJ->id }
            );
            if ($contigOBJ->isa('Bio::Assembly::Singlet')) {
                # Set the the sequence in the singlet
                $contigOBJ->seqref($read);
            } else { # a contig
                # this sets the "_aligned_coord:$seqID" feature
                $contigOBJ->set_seq_coord($coord,$read);
            }

        }

        # Loading read trimming and alignment ranges...
        elsif (/^QA (-?\d+) (-?\d+) (-?\d+) (-?\d+)/) {
            my ($qual_start, $qual_end, $aln_start, $aln_end) =
                ($1, $2, $3, $4);

            # Regions of the read that were aligned to the consensus (see BS)
            unless ($aln_start == -1 && $aln_end == -1) {
                $aln_start = $contigOBJ->change_coord("aligned $read_name",'gapped consensus',$aln_start);
                $aln_end   = $contigOBJ->change_coord("aligned $read_name",'gapped consensus',$aln_end);
                my $aln_feat = Bio::SeqFeature::Generic->new(
                    -start   => $aln_start,
                    -end     => $aln_end,
                    -strand  => $read_data->{$read_name}{'strand'},
                    -primary => "_align_clipping:$read_name"
                );
                $aln_feat->attach_seq( $contigOBJ->get_seq_by_name($read_name) );
                $contigOBJ->add_features([ $aln_feat ], 0);
            }

            # Regions of the read with high quality score
            unless ($qual_start == -1 && $qual_end == -1) {
                $qual_start = $contigOBJ->change_coord("aligned $read_name",'gapped consensus',$qual_start);
                $qual_end   = $contigOBJ->change_coord("aligned $read_name",'gapped consensus',$qual_end);
                my $qual_feat = Bio::SeqFeature::Generic->new(
                    -start   => $qual_start,
                    -end     => $qual_end,
                    -strand  => $read_data->{$read_name}{'strand'},
                    -primary => "_quality_clipping:$read_name"
                );
                $qual_feat->attach_seq( $contigOBJ->get_seq_by_name($read_name) );
                $contigOBJ->add_features([ $qual_feat ], 0);
            }

        }

        # Loading read DeScription (DS)
        elsif (/^DS\s+(.*)/) {
            my $desc = $1;

            # Expected tags are CHROMAT_FILE, PHD_FILE, TIME and to a lesser
            # extent DYE, TEMPLATE, CHEM and DIRECTION, but any other tag is
            # allowed
            my (undef, %tags) = split /\s?(\S+):\s+/, $desc;

            my $coord = $contigOBJ->get_seq_coord( $contigOBJ->get_seq_by_name($read_name) );
            my $start = $coord->start;
            my $end   = $coord->end;

            my $read_desc = Bio::SeqFeature::Generic->new(
                -start   => $start,
                -end     => $end,
                -primary => "_read_desc:$read_name",
                -tag     => \%tags
            );
            $coord->add_sub_SeqFeature($read_desc);
        
        }

        # Loading Read Tags
        elsif (/^RT\s*\{/) {
            my ($readID,$type,$source,$start,$end,$date) = split(' ',$self->_readline);
            my $extra_info = undef;
            while ($_ = $self->_readline) {
                last if (/\}/);
                $extra_info .= $_;
            }
            $start  = $contigOBJ->change_coord("aligned $readID",'gapped consensus',$start);
            $end    = $contigOBJ->change_coord("aligned $readID",'gapped consensus',$end);
            my $read_tag = Bio::SeqFeature::Generic->new(
                -start   => $start,
                -end     => $end,
                -primary => "_read_tags:$readID",
                -tag     => { 'type'          => $type,
                              'source'        => $source,
                              'creation_date' => $date,
                              'extra_info'    => $extra_info }
            );
            my $contig = $read_data->{$readID}{'contig'};
            my $coord  = $contig->get_seq_coord( $contig->get_seq_by_name($readID) );
            $coord->add_sub_SeqFeature($read_tag);
        }

    }

    # Adjust consensus sequence of 454 variant by padding its start and end
    if (($self->variant eq '454') && (defined $contigOBJ)) {
        my $pad_char = '-';
        my $pad_score = 0;
        # Find maximum coordinate
        my $max_end;
        for my $readid ($contigOBJ->get_seq_ids) {
            my $alncoord  = (grep
                { $_->primary_tag eq "_aligned_coord:$readid"}
                $contigOBJ->get_features_collection->get_all_features
                )[0];
            my $end = $alncoord->location->end;
            if ( (not defined $max_end) || ($end > $max_end) ) {
                $max_end = $end;
            }
        }

        # Pad consensus sequence
        my $cons_seq = $contigOBJ->get_consensus_sequence;
        my $cons_string = $cons_seq->seq;
        my $l_pad_len = abs($min_start) + 1;
        my $r_pad_len = $max_end - length($cons_string) - $l_pad_len;
        $cons_string = $pad_char x $l_pad_len . $cons_string . $pad_char x $r_pad_len;
        $cons_seq = Bio::LocatableSeq->new(
            -seq    => $cons_string,
            -id     => $cons_seq->id,
            -start  => $cons_seq->start,
            -strand => $cons_seq->strand,
        );
        $contigOBJ->set_consensus_sequence($cons_seq);
        
        # Pad consensus quality
        my $cons_qual = $contigOBJ->get_consensus_quality;
        if (defined $cons_qual) {
            my $cons_score = [ ($pad_score) x $l_pad_len,
                               @{$cons_qual->qual},
                               ($pad_score) x $r_pad_len ];
            $cons_qual = Bio::Seq::PrimaryQual->new(
                -qual => join(' ', @$cons_score),
                -id   => $cons_qual->id
            );
            $contigOBJ->set_consensus_quality($cons_qual);
        }
    }
    return $contigOBJ;
}


=head2 scaffold_annotations

 Title   : scaffold_annotations
 Usage   : $stream->scaffold_annotations($scaffold)
 Function: Add assembly and contig annotations to a scaffold. In the ACE format,
           annotations are the WA and CT tags.
 Returns : 1 for success
 Args    : a Bio::Assembly::Scaffold object to attach the annotations to

=cut

sub scaffold_annotations {
    my ($self, $assembly) = @_;
    local $/ = "\n";;
    # Read the ACE stream from the beginning again
    seek($self->_fh, 0, 0); 
    while ($_ = $self->_readline) {
        chomp;

        # Assembly information (ASsembly field)
        # Ignore it
        #(/^AS\s+(\d+)\s+(\d+)/) && do {
        #    my $nof_contigs = $1;
        #    my $nof_seq_in_contigs = $2;
        #};

        # Loading Whole Assembly tags
        /^WA\s*\{/ && do {
            my ($type,$source,$date) = split(' ',$self->_readline);
            my $extra_info = undef;
            while ($_ = $self->_readline) {
                last if (/\}/);
                $extra_info .= $_;

            }
            my $assembly_tags = join(" ","TYPE:",$type,"PROGRAM:",$source,
                "DATE:",$date,"DATA:",$extra_info);
            $assembly_tags = Bio::Annotation::SimpleValue->new(-value=>$assembly_tags);
            $assembly->annotation->add_Annotation('whole assembly',$assembly_tags);
        };

        # Loading Contig Tags (a.k.a. Bioperl features)
        /^CT\s*\{/ && do {
            my ($contigID,$type,$source,$start,$end,$date) = split(' ',$self->_readline);
            my %tags = ('source' => $source, 'creation_date' => $date);
            my $tag_type = 'extra_info';
            while ($_ = $self->_readline) {
                if (/COMMENT\s*\{/) {
                    $tag_type = 'comment';
                } elsif (/C\}/) {
                    $tag_type = 'extra_info';
                } elsif (/\}/) {
                    last;
                } else {
                    $tags{$tag_type} .= "$_";
                }
            }
            my $contig_tag = Bio::SeqFeature::Generic->new( -start   => $start,
                                                            -end     => $end,
                                                            -primary => $type,
                                                            -tag     => \%tags );
            my $contig = $assembly->get_contig_by_id($contigID) ||
                         $assembly->get_singlet_by_id($contigID);
            $self->throw("Cannot add feature to unknown contig '$contigID'")
              unless defined $contig;

            $contig->add_features([ $contig_tag ],1);
        };

    }
    return 1;
}


=head2 write_assembly

    Title   : write_assembly
    Usage   : $ass_io->write_assembly($assembly)
    Function: Write the assembly object in ACE compatible format. The contig IDs
              are sorted naturally if the Sort::Naturally module is present, or
              lexically otherwise. Internally, write_assembly use the
              write_contig, write_footer and write_header methods. Use these
              methods if you want more control on the writing proces.
    Returns : 1 on success, 0 for error
    Args    : A Bio::Assembly::Scaffold object

=cut


=head2 write_contig

    Title   : write_contig
    Usage   : $ass_io->write_contig($contig)
    Function: Write a contig or singlet object in ACE compatible format. Quality
              scores are automatically generated if the contig does not contain
              any
    Returns : 1 on success, 0 for error
    Args    : A Bio::Assembly::Contig or Singlet object

=cut

sub write_contig {
    my ($self, @args) = @_;
    my ($contig) = $self->_rearrange([qw(CONTIG)], @args);

    # Sanity check
    if ( !$contig || !$contig->isa('Bio::Assembly::Contig') ) {
        $self->throw("Must provide a Bio::Assembly::Contig or Singlet object when calling write_contig");
    }

    # Contig consensus sequence
    my $contig_id        =  $contig->id;
    my $cons             =  $contig->get_consensus_sequence;
    my $cons_seq         =  $cons->seq;
    my $cons_len         =  $cons->length;
    my $contig_num_reads =  $contig->num_sequences;
    my $cons_strand      = ($contig->strand == -1) ? 'C' : 'U';
    my @bs_feats = grep { $_->primary_tag eq '_base_segments' }
        $contig->get_features_collection->get_all_features;
    my $nof_segments     = scalar @bs_feats ;

    $self->_print(
        "CO $contig_id $cons_len $contig_num_reads $nof_segments $cons_strand\n".
        _formatted_seq($cons_seq, $line_width).
        "\n"
    );

    # Consensus quality scores
    $cons = $contig->get_consensus_quality;
    my $cons_qual = $cons->qual if defined $cons;
    $self->_print(
        "BQ\n".
        _formatted_qual($cons_qual, $cons_seq, $line_width, $qual_value).
        "\n"
    );
        
    # Read entries
    my @reads  = $contig->each_seq;
    for my $read (@reads) {
        my $read_id     =  $read->id;
        my $read_strand = ($read->strand == -1) ? 'C' : 'U';
        my $read_start  =  $contig->change_coord("aligned $read_id",'gapped consensus',1);
        $self->_print( "AF $read_id $read_strand $read_start\n" );
    }
    $self->_print( "\n" );

    # Deal with base segments (BS)
    if ( @bs_feats ) {
        # sort segments by increasing start position
        @bs_feats = sort { $a->start <=> $b->start } @bs_feats;
        # write segments
        for my $bs_feat ( @bs_feats ) {
            my $start =  $bs_feat->start;
            my $end   =  $bs_feat->end;
            my $id    = ($bs_feat->get_tag_values('contig_id'))[0];
            $self->_print( "BS $start $end $id\n" );
         }
        $self->_print( "\n" );
    }
    
    for my $read (@reads) {
        $self->_write_read($read, $contig);
    }

    return 1;
}


=head2 write_header

    Title   : write_header
    Usage   : $ass_io->write_header($scaffold)
                  or
              $ass_io->write_header(\@contigs);
                  or
              $ass_io->write_header();
    Function: Write ACE header (AS tags). You can call this function at any time,
              i.e. not necessarily at the start of the stream - this is useful
              if you have an undetermined number of contigs to write to ACE, e.g:
                for my $contig (@list_of_contigs) {
                  $ass_io->_write_contig($contig);
                }
                $ass_io->_write_header();
    Returns : 1 on success, 0 for error
    Args    : A Bio::Assembly::Scaffold
                  or
              an arrayref of Bio::Assembly::Contig
                  or
              nothing (the header is dynamically written based on the ACE file
              content)

=cut

sub write_header {
    my ($self, $input) = @_;

    # Input validation
    my @contigs;
    my $err_msg = "If an input is given to write_header, it must be a single ".
        "Bio::Assembly::Scaffold object or an arrayref of Bio::Assembly::Contig".
        " or Singlet objects";
    my $ref = ref $input;
    if ( $ref eq 'ARRAY' ) {
       for my $obj ( @$input ) {
           $self->throw($err_msg) if not $obj->isa('Bio::Assembly::Contig');
           push @contigs, $obj;
       }
    } elsif ( $ref =~ m/Bio::Assembly::Scaffold/ ) {
       @contigs = ($input->all_contigs, $input->all_singlets);
    }

    # Count number of contigs and reads
    my $num_contigs = 0;
    my $num_reads   = 0;
    if ( scalar @contigs > 0 ) {
        # the contigs were provided
        $num_contigs = scalar @contigs;
        for my $contig ( @contigs ) {
            $num_reads += $contig->num_sequences;
        }
    } else {
        # need to read the contigs from file
        $self->flush;
        my $file = $self->file(); # e.g. '+>output.ace'
        $file =~ s/^\+?[><]?//;   # e.g. 'output.ace'
        my $read_io = Bio::Assembly::IO->new( -file => $file, -format => 'ace' );
        while ( my $contig = $read_io->next_contig ) {
            $num_contigs++;
            $num_reads += $contig->num_sequences;
        }
        $read_io->close;
    }

    # Write ASsembly tag at the start of the file
    my $header = "AS $num_contigs $num_reads\n\n";
    $self->_insert($header, 1);

    return 1;
}


=head2 write_footer

    Title   : write_footer
    Usage   : $ass_io->write_footer($scaffold)
    Function: Write ACE footer (WA and CT tags).
    Returns : 1 on success, 0 for error
    Args    : A Bio::Assembly::Scaffold object (optional)

=cut

sub write_footer {
    my ($self, $scaf) = @_;
    # Nothing to write if scaffold was not provided
    return 1 if not defined $scaf;
    # Verify that provided object is a scaffold
    if ($scaf->isa('Bio::Assembly:ScaffoldI')) {
        $self->throw("Must provide a Bio::Assembly::Scaffold object when calling write_footer");
    }
    # Whole Assembly tags (WA)
    my $asm_anno = ($scaf->annotation->get_Annotations('whole assembly'))[0];
    if ($asm_anno) {
        my $asm_tags = $asm_anno->value;
        if ($asm_tags =~ m/^TYPE: (\S+) PROGRAM: (\S+) DATE: (\S+) DATA: (.*)$/ms) {
            my ($type, $program, $date, $data) = ($1, $2, $3, $4);
            $data ||= '';
            $self->_print(
                "WA{\n".
                "$type $program $date\n".
                $data.
                "}\n".
                "\n"
            );
        }
    }
    # Contig Tags (CT)
    for my $contig_id ( Bio::Assembly::IO::_sort( $scaf->get_contig_ids ) ) {
        my $contig = $scaf->get_contig_by_id($contig_id) ||
            $scaf->get_singlet_by_id($contig_id);
        my @feats = (grep 
            { not $_->primary_tag =~ m/^_/ }
             $contig->get_features_collection->get_all_features
            );
        for my $feat (@feats) {
            my $type   =  $feat->primary_tag;
            my $start  =  $feat->start;
            my $end    =  $feat->end;
            my $source = ($feat->get_tag_values('source')       )[0];
            my $date   = ($feat->get_tag_values('creation_date'))[0];
            my $extra  = '';
            if ($feat->has_tag('extra_info')) {
                $extra = ($feat->get_tag_values('extra_info')   )[0];
            }
            $self->_print(
                "CT{\n".
                "$contig_id $type $source $start $end $date\n".
                $extra.
                "}\n".
                "\n"
            );
        }
    }
    return 1;
}


=head2 variant

 Title   : variant
 Usage   : $format  = $obj->variant();
 Function: Get and set method for the assembly variant. This is important since
           not all assemblers respect the reference ACE format.
 Returns : string
 Args    : string: 'consed' (default) or '454'

=cut

sub variant {
    my ($self, $enc) = @_;
    if (defined $enc) {
        $enc = lc $enc;
        if (not exists $variant{$enc}) {
            $self->throw('Not a valid ACE variant format');
        }
        $self->{variant} = $enc;
    }
    return $self->{variant};
}


=head2 _write_read

    Title   : _write_read
    Usage   : $ass_io->_write_read($read, $contig)
    Function: Write a read object in ACE compatible format
    Returns : 1 on success, 0 for error
    Args    : a Bio::LocatableSeq read
              the Contig or Singlet object that this read belongs to

=cut

sub _write_read {
    my ($self, @args) = @_;
    my ($read, $contig) = $self->_rearrange([qw(READ CONTIG)], @args);

    # Sanity check
    if ( !$read || !$read->isa('Bio::LocatableSeq') ) {
        $self->throw("Must provide a Bio::LocatableSeq when calling write_read");
    }
    if ( !$contig || !$contig->isa('Bio::Assembly::Contig') ) {
        $self->throw("Must provide a Bio::Assembly::Contig or Singlet object when calling write_read");
    }

    # Read info
    my $read_id   = $read->id;
    my $read_len  = $read->length; # aligned length
    my $read_seq  = $read->seq;
    my $nof_info = 0; # fea: could not find exactly what this is?
    my @read_feats = $contig->get_seq_coord($read)->get_SeqFeatures;
    my @read_tags = (grep { $_->primary_tag eq "_read_tags:$read_id" } @read_feats);
    my $nof_tags  = scalar @read_tags;
    $self->_print(
        "RD $read_id $read_len $nof_info $nof_tags\n".
        _formatted_seq($read_seq, $line_width).
        "\n"
    );

    # Aligned "align clipping" and quality coordinates if read object has them
    my $qual_clip_start = 1;
    my $qual_clip_end   = length($read->seq);
    my $qual_clip = (grep 
        { $_->primary_tag eq '_quality_clipping:'.$read_id }
        $contig->get_features_collection->get_all_features
        )[0];
    if ( defined $qual_clip ) {
        $qual_clip_start = $qual_clip->location->start;
        $qual_clip_end   = $qual_clip->location->end;
        $qual_clip_start = $contig->change_coord('gapped consensus',"aligned $read_id",$qual_clip_start);
        $qual_clip_end   = $contig->change_coord('gapped consensus',"aligned $read_id",$qual_clip_end  );
    }

    my $aln_clip_start = 1;
    my $aln_clip_end   = length($read->seq);
    my $aln_clip = (grep 
        { $_->primary_tag eq '_align_clipping:'.$read_id }
        $contig->get_features_collection->get_all_features
        )[0];
    if ( defined $aln_clip ) {
        $aln_clip_start = $aln_clip->location->start;
        $aln_clip_end   = $aln_clip->location->end;
        $aln_clip_start  = $contig->change_coord('gapped consensus',"aligned $read_id",$aln_clip_start );
        $aln_clip_end    = $contig->change_coord('gapped consensus',"aligned $read_id",$aln_clip_end   );
    }

    $self->_print(
        "QA $qual_clip_start $qual_clip_end $aln_clip_start $aln_clip_end\n".
        "\n"
    );

    # Read description, if read object has them
    my $read_desc = (grep { $_->primary_tag eq "_read_desc:$read_id" } @read_feats)[0];
    if ($read_desc) {
        $self->_print("DS");
        for my $tag_name ( $read_desc->get_all_tags ) {
            my $tag_value = ($read_desc->get_tag_values($tag_name))[0];
            $self->_print(" $tag_name: $tag_value");
        }
        $self->_print("\n\n");
    }

    # Read tags, if read object has them
    for my $read_tag (@read_tags) {
        #my $type   =  $read_tag->primary_tag;
        my $start  =  $read_tag->start;
        my $end    =  $read_tag->end;
        my $type   = ($read_tag->get_tag_values('type')         )[0];
        my $source = ($read_tag->get_tag_values('source')       )[0];
        my $date   = ($read_tag->get_tag_values('creation_date'))[0];
        my $extra  = ($read_tag->get_tag_values('extra_info')   )[0] || '';
        $self->_print(
            "RT{\n".
            "$read_id $type $source $start $end $date\n".
            $extra.                
            "}\n".
            "\n"
        );
    }

    return 1;
}


=head2 _formatted_seq

    Title   : _formatted_seq
    Usage   : Bio::Assembly::IO::ace::_formatted_seq($sequence, $line_width)
    Function: Format a sequence for ACE output:
              i ) replace gaps in the sequence by the '*' char
              ii) split the sequence on multiple lines as needed
    Returns : new sequence string
    Args    : sequence string on one line
              maximum line width

=cut

sub _formatted_seq {
    my ($seq_str, $line_width) = @_;
    my $new_str = '';
    # In the ACE format, gaps are '*'
    $seq_str =~ s/-/*/g;
    # Split sequences on several lines
    while ( my $chunk = substr $seq_str, 0, $line_width, '' ) {
        $new_str .= "$chunk\n";
    }
    return $new_str;
}


=head2 _formatted_qual

    Title   : _formatted_qual
    Usage   : Bio::Assembly::IO::ace::_formatted_qual($qual_arr, $sequence, $line_width, $qual_default)
    Function: Format quality scores for ACE output:
              i  ) use the default quality values when they are missing
              ii ) remove gaps (they get no score in ACE)
              iii) split the quality scores on several lines as needed
    Returns : new quality score string
    Args    : quality score array reference
              corresponding sequence string
              maximum line width
              default quality score

=cut

sub _formatted_qual {
    my ($qual_arr, $seq, $line_width, $qual_default) = @_;
    my $qual_str = '';
    my @qual_arr;
    if (defined $qual_arr) {
      # Copy array
      @qual_arr = @$qual_arr;
    } else {
      # Default quality
      @qual_arr = map( $qual_default, (1 .. length $seq) );     
    }
    # Gaps get no quality score in ACE format
    my $gap_pos = -1;
    while ( 1 ) {
        $gap_pos = index($seq, '-', $gap_pos + 1);
        last if $gap_pos == -1;
        substr $seq, $gap_pos, 1, '';
        splice @qual_arr, $gap_pos, 1;
        $gap_pos--;
    }
    # Split quality scores on several lines
    while ( my @chunks = splice @qual_arr, 0, $line_width ) {
        $qual_str .= "@chunks\n";
    }
    return $qual_str;
}


=head2 _input_qual

    Title   : _input_qual
    Usage   : Bio::Assembly::IO::ace::_input_qual($qual_string, $sequence)
    Function: Reads input quality string and converts it to an array of quality
              scores. Gaps get a quality score equals to the average of the
              quality score of its neighbours.
    Returns : new quality score array
    Args    : quality score string
              corresponding sequence string

=cut

sub _input_qual {
    my ($self, $qual_string, $sequence) = @_;
    my @qual_arr = ();
    # Remove whitespaces in front of qual string and split quality values
    $qual_string =~ s/^\s+//;
    my @tmp = split(/\s+/, $qual_string);
    # Remove gaps
    my $i = 0; # position in quality 
    my $j = 0; # position in sequence
    my $prev = 0;
    my $next = 0;
    for $j (0 .. length($sequence)-1) {
        my $nt = substr($sequence, $j, 1);
        if ($nt eq '-') {
            if ($i > 0) {
                $prev = $tmp[$i-1];
            } else {
                $prev = 0;
            }
            if ($i < $#tmp) {
                $next = $tmp[$i];
            } else {
                $next = 0;
            }
            push @qual_arr, int(($prev+$next)/2);
        } else {
            push @qual_arr, $tmp[$i];
            $i++;
        }
    }
    return @qual_arr;
}


=head2 _initialize

    Title   : _initialize
    Usage   : $ass_io->_initialize(@args)
    Function: Initialize the Bio::Assembly::IO object with the proper ACE variant
    Returns : 
    Args    : 

=cut

sub _initialize {
    my($self, @args) = @_;
    $self->SUPER::_initialize(@args);
    my ($variant) = $self->_rearrange([qw(VARIANT)], @args);
    $variant ||= 'consed';
    $self->variant($variant);
}


1;

__END__
