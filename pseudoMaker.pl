#!/usr/local/bin/perl -w
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $reference = '';
my $informat = 'fasta';
my $snpfile = '';
my $output = '';
my $outformat = 'fasta';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'reference=s' => \$reference,
			'informat=s' => \$informat,
			'snp=s' => \$snpfile,
			'output=s' => \$output,
			'outformat=s' => \$outformat,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($reference && $snpfile && $output);
my $snpLineNum=0;
open (IN,$snpfile) or die "$!";
while (<IN>)
{
	chop;
	$snpLineNum++;
	/^#/ and next;
	/^\s*$/ and next;
	my @snpline=split(/\t/,$_);
	$snpline[2] =~ s/\s*//g;
	if (length ($snpline[2]) > 1 || ($snpline[2] !~ /^[ACGT]+$/i))
	{
		print "Warning: There is a wrong SNP appearing on line $snpLineNum in your snp file. It will not be used to create new pseudo molecules.\n";
		next;
	}
	$snp{$snpline[0]}{$snpline[1]}=$snpline[2];
}
close (IN);


my $in = Bio::SeqIO->new(-file => $reference,
						-format => $informat);

my $out = Bio::SeqIO->new(-file => ">$output",
						-format => $outformat);
while ( my $seq = $in->next_seq() )
{
	$newseq=$seq->seq();
	if(exists $snp{$seq->id})
	{
		for $position (keys %{$snp{$seq->id}})
		{
			substr ($newseq,$position-1,1) = $snp{$seq->id}{$position};
		}
	}
	$outseq = Bio::PrimarySeq->new ( -seq => $newseq,
				   -id  => $seq->id(),
				   -accession_number => $seq->accession_number,
				   );
	$out->write_seq($outseq);
}

__END__

=head1 NAME

pseudoMaker.pl - Making pseudo reference by SNP data

=head1 SYNOPSIS

pseudoMaker.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -reference       reference sequnce file
   -informat        reference sequence format
   -snp             SNP data file
   -output          output file
   -outformat       output sequence format

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-reference>

Input sequence file.

=item B<-informat> (optional)

Input sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=item B<-snp>

SNP data file. For example,

 #reference_seq_name	position	genotype_in_new_pseudo
 chr01	1998	A
 chr02	2008	C
 ...

=item B<-output>

Output data to a file.

=item B<-outformat> (optional)

Output sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=back

=head1 DESCRIPTION

B<pseudoMaker> will ...

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
