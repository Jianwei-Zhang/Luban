#!/usr/local/bin/perl -w
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $format = 'fasta';
my $output = '';
my $source = 'AGI';
my $type = 'chromosome';
my $keep = 0;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'format=s' => \$format,
			'output=s' => \$output,
			'source=s' => \$source,
			'type=s' => \$type,
			'keep=i' => \$keep,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output);

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
print OUTPUT <<END;
##gff-version 3
##Index-subfeatures 1
END
my $in = Bio::SeqIO->new(-file => $input,
						-format => $format);
while ( my $seq = $in->next_seq() )
{
	print OUTPUT $seq->id()."\t$source\t$type\t1\t".$seq->length()."\t.\t.\t.\tID=".$seq->id().";Name=".$seq->id()."\n";
	print OUTPUT "##FASTA\n>" . $seq->id() . " " . $seq->desc . "\n" .$seq->seq() . "\n" if ($keep);
}
close (OUTPUT);
__END__

=head1 NAME

seqToGff3.pl - Convert sequences to GFF3 for genome browser

=head1 SYNOPSIS

seqToGff3.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -format          input sequence format
   -output          output file
   -source          source (optional)
   -type            type (optional)
   -keep            keep sequences in GFF (optional)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a fasta file.

=item B<-format> (optional)

Input sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=item B<-output>

Output data to a file.

=item B<-source> (optional)

The source is a free text qualifier intended to describe the algorithm or operating procedure that generated this feature. Typically this is the name of a piece of software, such as "Genescan" or a database name, such as "Genbank." In effect, the source is used to extend the feature ontology by adding a qualifier to the type creating a new composite type that is a subclass of the type in the type column.

=item B<-type> (optional)

The type of the feature (previously called the "method"). This is constrained to be either: (a)a term from the "lite" version of the Sequence Ontology - SOFA, a term from the full Sequence Ontology - it must be an is_a child of sequence_feature (SO:0000110) or (c) a SOFA or SO accession number. The latter alternative is distinguished using the syntax SO:000000.

=item B<-keep> (optional)

Keep sequences in GFF file. (Default is 0 for not keeping)

=back

=head1 DESCRIPTION

B<seqToGff3> will get the gff3 of sequences in a file for Gbrowse.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 



=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
