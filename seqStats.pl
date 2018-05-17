#!/usr/bin/perl -w
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $list = '';
my $format = 'fasta';
my $output = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'list=s' => \$list,
			'format=s' => \$format,
			'output=s' => \$output,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless (($input || $list) && $output);

my @seqList;
if ($input)
{
	push @seqList, $input;
}
if ($list)
{
    open LIST, $list;
    while (<LIST>)
    {
		/^\#/ and next;
		s/\s+$//;
		push @seqList, $_;
	}
	close (LIST);
}

my $total=0;
my @lengthlist=();
my $longest = 0;
my $shortest = 9999999999;
my %countByLength = ('halfK'  => '0',
	'oneK'    => '0',
    'tenK'   => '0',
	'hundredK'  => '0',
	'oneM' => '0');
my %sumLength = ('halfK'  => '0',
	'oneK'    => '0',
    'tenK'   => '0',
	'hundredK'  => '0',
	'oneM' => '0');

foreach (@seqList)
{
	my $in = Bio::SeqIO->new(-file => $_,
							-format => $format);
	while ( my $seq = $in->next_seq() )
	{
		$total += $seq->length();
		push @lengthlist, $seq->length();
		$longest = $seq->length() if ($longest < $seq->length());
		$shortest = $seq->length() if ($shortest > $seq->length());
		$countByLength{'halfK'}++ if ($seq->length() > 500);
		$countByLength{'oneK'}++ if ($seq->length() > 1000);
		$countByLength{'tenK'}++ if ($seq->length() > 10000);
		$countByLength{'hundredK'}++ if ($seq->length() > 100000);
		$countByLength{'oneM'}++ if ($seq->length() > 1000000);
		$sumLength{'halfK'} += $seq->length() if ($seq->length() > 500);
		$sumLength{'oneK'} += $seq->length() if ($seq->length() > 1000);
		$sumLength{'tenK'} += $seq->length() if ($seq->length() > 10000);
		$sumLength{'hundredK'} += $seq->length() if ($seq->length() > 100000);
		$sumLength{'oneM'} += $seq->length() if ($seq->length() > 1000000);
	}
}

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
print OUTPUT "--in $input$list--\n";
print OUTPUT "Number of sequences: ",$#lengthlist+1,".\n";
print OUTPUT "Total size of sequences: $total.\n";
print OUTPUT "Longest sequence: $longest.\n";
print OUTPUT "Shortest sequence: $shortest.\n";
print OUTPUT "Number of sequences > 500 nt: $countByLength{'halfK'} ($sumLength{'halfK'} bp).\n";
print OUTPUT "Number of sequences > 1k nt: $countByLength{'oneK'} ($sumLength{'oneK'} bp).\n";
print OUTPUT "Number of sequences > 10k nt: $countByLength{'tenK'} ($sumLength{'tenK'} bp).\n";
print OUTPUT "Number of sequences > 100k nt: $countByLength{'hundredK'} ($sumLength{'hundredK'} bp).\n";
print OUTPUT "Number of sequences > 1M nt: $countByLength{'oneM'} ($sumLength{'oneM'} bp).\n";
print OUTPUT "Mean sequence length: ",int $total/($#lengthlist+1),".\n";
@lengthlist = sort {$b <=> $a} @lengthlist;
if($#lengthlist % 2 == 1)
{
	my $median = int ($#lengthlist/2);
	my $medianLength = ($lengthlist[$median]+$lengthlist[$median+1])/2;
	print OUTPUT "Median sequence length: ",$medianLength,".\n";
}
else
{
	my $median = $#lengthlist/2;
	print OUTPUT "Median sequence length: ",$lengthlist[$median],".\n";
}

my $subtotal=0;
my $lFifty=0;
foreach (@lengthlist)
{
	$subtotal += $_;
	$lFifty++;
	if($subtotal >= $total/2)
	{
		print OUTPUT "N50 sequence length: ", $_, ".\n";
		print OUTPUT "L50 sequence count: ", $lFifty, ".\n";
		last;
	}
}
close (OUTPUT);

__END__

=head1 NAME

seqStats - Sequence length stats

=head1 SYNOPSIS

seqStats.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -list            list of fasta files
   -format          input sequence format
   -output          output file

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a fasta file.

=item B<-list>

Input data from a list of fasta files.

=item B<-format> (optional)

Input sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=item B<-output>

Output data to a file.

=back

=head1 DESCRIPTION

B<seqStats> will ...

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
