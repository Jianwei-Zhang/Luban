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
my @allLengthList=();
foreach (@seqList)
{
	my $in = Bio::SeqIO->new(-file => $_,
							-format => $format);
	while ( my $seq = $in->next_seq() )
	{
		push @allLengthList, $seq->length();
	}
}

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
print OUTPUT "--in $input$list--\n";
print OUTPUT &seqStats(@allLengthList); #all sequence stats
close (OUTPUT);
## subroutines 
sub seqStats
{
	my @lengthList = @_;
	my $stats = '';
	my $total = 0;
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

	foreach (@lengthList)
	{
		$total += $_;
		$longest = $_ if ($longest < $_);
		$shortest = $_ if ($shortest > $_);
		$countByLength{'halfK'}++ if ($_ > 500);
		$countByLength{'oneK'}++ if ($_ > 1000);
		$countByLength{'tenK'}++ if ($_ > 10000);
		$countByLength{'hundredK'}++ if ($_ > 100000);
		$countByLength{'oneM'}++ if ($_ > 1000000);
		$sumLength{'halfK'} += $_ if ($_ > 500);
		$sumLength{'oneK'} += $_ if ($_ > 1000);
		$sumLength{'tenK'} += $_ if ($_ > 10000);
		$sumLength{'hundredK'} += $_ if ($_ > 100000);
		$sumLength{'oneM'} += $_ if ($_ > 1000000);
	}
	my $numberOfSequences = $#lengthList+1;
	my $meanSequenceLength = int $total/($#lengthList+1);
	$sumLength{'halfK'} = &commify($sumLength{'halfK'});
	$sumLength{'oneK'} = &commify($sumLength{'oneK'});
	$sumLength{'tenK'} = &commify($sumLength{'tenK'});
	$sumLength{'hundredK'} = &commify($sumLength{'hundredK'});
	$sumLength{'oneM'} = &commify($sumLength{'oneM'});

	$stats .= "Number of sequences: $numberOfSequences.\n";
	$stats .= "Total size of sequences: $total.\n";
	$stats .= "Longest sequence: $longest.\n";
	$stats .= "Shortest sequence: $shortest.\n";
	$stats .= "Number of sequences > 500 nt: $countByLength{'halfK'} ($sumLength{'halfK'} bp).\n";
	$stats .= "Number of sequences > 1k nt: $countByLength{'oneK'} ($sumLength{'oneK'} bp).\n";
	$stats .= "Number of sequences > 10k nt: $countByLength{'tenK'} ($sumLength{'tenK'} bp).\n";
	$stats .= "Number of sequences > 100k nt: $countByLength{'hundredK'} ($sumLength{'hundredK'} bp).\n";
	$stats .= "Number of sequences > 1M nt: $countByLength{'oneM'} ($sumLength{'oneM'} bp).\n";
	$stats .= "Mean sequence length: $meanSequenceLength.\n";
	@lengthList = sort {$b <=> $a} @lengthList;
	if($#lengthList % 2 == 1)
	{
		my $median = int ($#lengthList/2);
		my $medianLength = ($lengthList[$median]+$lengthList[$median+1])/2;
		$stats .= "Median sequence length: $medianLength.\n";
	}
	else
	{
		my $median = $#lengthList/2;
		$stats .= "Median sequence length: $lengthList[$median].\n";
	}

	my $subtotal=0;
	my $lFifty=0;
	foreach (@lengthList)
	{
		$subtotal += $_;
		$lFifty++;
		if($subtotal >= $total/2)
		{
			$stats .= "N50 sequence length:  $_.\n";
			$stats .= "L50 sequence count: $lFifty.\n";
			last;
		}
	}
	return $stats;
}

sub commify {
	local $_  = shift;
	1 while s/^(-?\d+)(\d{3})/$1,$2/;
	return $_;
}

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
