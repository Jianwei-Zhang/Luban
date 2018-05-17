#!/usr/local/bin/perl -w
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $format = 'fasta';
my $output = '';
my $refname = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'format=s' => \$format,
			'output=s' => \$output,
			'refname=s' => \$refname,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output);

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
print OUTPUT "#seqid\tlength\n";
my $in = Bio::SeqIO->new(-file => $input,
						-format => $format);
while ( my $seq = $in->next_seq() )
{
	if($refname)
	{
		print OUTPUT $refname.":".$seq->id()."\t".$seq->length()."\n";
	}
	else
	{
		print OUTPUT $seq->id()."\t".$seq->length()."\n";
	}
}
close (OUTPUT);
__END__

=head1 NAME

seqLength.pl - Getting length of sequences

=head1 SYNOPSIS

seqLength.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -format          input sequence format
   -output          output file
   -refname         refname (optional)

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

=item B<-refname> (optional)

refname is for giving a name (such as spiece) for reference sequence.

=back

=head1 DESCRIPTION

B<seqLength> will get the length of sequences in a file.

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
