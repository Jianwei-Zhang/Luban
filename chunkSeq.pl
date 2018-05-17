#!/usr/local/bin/perl -w
use Bio::SeqIO;
use Bio::Seq;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $informat = 'fasta';
my $output = '';
my $outformat = 'fasta';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'informat=s' => \$informat,
			'chunksize=i' => \$chunksize,
			'output=s' => \$output,
			'outformat=s' => \$outformat,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output);

my $in = Bio::SeqIO->new(-file => $input,
						-format => $informat);
my $out = Bio::SeqIO->new(-file => ">$output",
						-format => $outformat);
while ( my $seq = $in->next_seq() )
{
	my $seqlength= $seq->length();
	for(my $position = 1;$position < $seqlength; $position += $chunksize)
	{
		my $endposition = $position + $chunksize - 1;
		if ($endposition > $seqlength)
		{
			my $outseq = Bio::Seq->new(-display_id => $seq->primary_id . "-$position:$seqlength",
									-seq => $seq->subseq($position,$seqlength),
									-desc => $seq->desc());
			$out->write_seq($outseq);
		}
		else
		{
			my $outseq = Bio::Seq->new(-display_id => $seq->primary_id . "-$position:$endposition",
									-seq => $seq->subseq($position,$endposition),
									-desc => $seq->desc());
			$out->write_seq($outseq);
		}
	}
}
__END__

=head1 NAME

chunkSeq.pl - chunk sequence into pecies

=head1 SYNOPSIS

chunkSeq.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -informat        input sequence format
   -chunksize       chunk size
   -output          output file
   -outformat       output sequence format

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a fasta file.

=item B<-informat> (optional)

Input sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=item B<-chunksize>

Chunk size.

=item B<-output>

Output data to a file.

=item B<-outformat> (optional)

Output sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=back

=head1 DESCRIPTION

B<chunkSeq> will ...

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

getSeqById.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
