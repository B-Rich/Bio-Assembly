# $Id$
#
# BioPerl module for Bio::Assembly::Singlet
# 
# Cared for by Chad Matsalla <bioinformatics1 at dieselwurks.com>
#
# Copyright Chad Matsalla
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Assembly::Singlet - Perl module to hold and manipulate
                     singlets from sequence assembly contigs.

=head1 SYNOPSYS

    # Module loading
    use Bio::Assembly::IO;

    # Assembly loading methods
    $aio = new Bio::Assembly::IO(-file=>"test.ace.1",
                               -format=>'phrap');

    $assembly = $aio->next_assembly;
    foreach $singlet ($assembly->all_singlets) {
      # do something
    }

=head1 DESCRIPTION

A singlet is a sequence that phrap was unable to align to any other sequences.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing lists  Your participation is much appreciated.

  bioperl-l@bioperl.org                 - General discussion
  http://bio.perl.org/MailList.html     - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via email
or the web:

  bioperl-bugs@bio.perl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Chad S. Matsalla

bioinformatics1 at dieselwurks.com

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

#'
package Bio::Assembly::Singlet;

use strict;
use vars qw(@ISA);

use Bio::Root::Root;
use Bio::Align::AlignI;
use Bio::SeqFeature::Collection;
use Bio::Seq::PrimaryQual;

@ISA = qw(Bio::Root::Root Bio::Align::AlignI Bio::Assembly::Contig);

1;
