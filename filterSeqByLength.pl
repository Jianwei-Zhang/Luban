#!/usr/bin/perl -w
#!/usr/local/bin/perl -w
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $informat = 'fasta';
my $length = 1;
my $output = '';
my $removed = '';
my $outformat = 'fasta';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'informat=s' => \$informat,
			'length=i' => \$length,
			'output=s' => \$output,
			'removed=s' => \$removed,
			'outformat=s' => \$outformat,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output);


my $total=0;
my @lengthlist=();
my $longest = 0;
my $shortest = 9999999999;
my %countByLength = ('halfK'  => '0',
	'oneK'    => '0',
    'tenK'   => '0',
	'hundredK'  => '0',
	'oneM' => '0');
my $w = 60;# formatting width for output

my $in = Bio::SeqIO->new(-file => $input,
						-format => $informat);
my $out = Bio::SeqIO->new(-file => ">$output",
						-format => $outformat);
while ( my $seq = $in->next_seq() )
{
	if ($seq->length() >= $length)
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
		$out->write_seq($seq) ;
	}
	else
	{
		if ($removed)
		{
			my $rmout = Bio::SeqIO->new(-file => ">>$removed",
									-format => $outformat);
			$rmout->write_seq($seq) ;
		}
	}
}

print "<-- Stats for '$output' -->\n\n\n";
printf "%${w}s %10d\n", "Number of sequences",$#lengthlist+1;
printf "%${w}s %10d\n", "Total size of sequences",$total;
printf "%${w}s %10d\n", "Longest sequence",$longest;
printf "%${w}s %10d\n", "Shortest sequence",$shortest;
printf "%${w}s %10d\n", "Number of sequences > 500 nt",$countByLength{'halfK'};
printf "%${w}s %10d\n", "Number of sequences > 1k nt",$countByLength{'oneK'};
printf "%${w}s %10d\n", "Number of sequences > 10k nt",$countByLength{'tenK'};
printf "%${w}s %10d\n", "Number of sequences > 100k nt",$countByLength{'hundredK'};
printf "%${w}s %10d\n", "Number of sequences > 1M nt",$countByLength{'oneM'};
printf "%${w}s %10d\n", "Mean sequence size",int $total/($#lengthlist+1);
@lengthlist = sort {$b <=> $a} @lengthlist;
my $median = int ($#lengthlist/2);
printf "%${w}s %10d\n", "Median sequence size",$lengthlist[$median];
my $subtotal=0;
my $lFifty=0;
foreach (@lengthlist)
{
	$subtotal += $_;
	$lFifty++;
	if($subtotal >= $total/2)
	{
		printf "%${w}s %10d\n", "N50 sequence length",$_;
		printf "%${w}s %10d\n", "L50 sequence count",$lFifty;
		last;
	}
}

__END__

=head1 NAME

filterSeqByLength.pl - Reformating and filtering sequences

=head1 SYNOPSIS

filterSeqByLength.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -informat        input sequence format
   -length          minimum sequence length
   -output          output file
   -removed         save removed sequences to a file
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

=item B<-length> (optional)

Minimum sequence length, default is 1.

=item B<-output>

Output data to a file.

=item B<-removed>

Save removed sequences to a file.

=item B<-outformat> (optional)

Output sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=back

=head1 DESCRIPTION

B<filterSeqByLength> will ...

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

filterSeqByLength.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
