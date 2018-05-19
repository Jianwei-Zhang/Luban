#!/usr/local/bin/perl -w
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $output = '';
my $windowsize = '';
my $overlapsize = 0;
my $popname = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'output=s' => \$output,
			'window=i' => \$windowsize,
			'overlap=i' => \$overlapsize,
			'popname=s' => \$popname,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output && $windowsize);

if($windowsize <= $overlapsize)
{
	print "Overlap size must be smaller than window size.\n";
	exit;
}

open (INPUT,"$input") or die "can't open input FILE: $!";
while(<INPUT>)
{
	chop;
	/^#/ and next;
	$_ =~ s/\s*$//g;
	@line = split (/\t/,$_);
	$chr=shift @line;
	$position=shift @line;
	$samplenumber=$#line+1;
	if($samplenumber < 2)
	{
		print "The amount of sample is less than 2, please check your data.\n";
		exit;
	}
	%genotype=();
	foreach (@line)
	{
		if(!exists $genotype{uc($_)})
		{
			$genotype{uc($_)}=1;
		}
		else
		{
			$genotype{uc($_)}++;
		}
	}
	next if ((keys %genotype >2) || (keys %genotype == 1));
	$minnumber=$samplenumber;
	foreach (keys %genotype)
	{
		$minnumber = $genotype{$_} if($genotype{$_} < $minnumber);
	}
	$potentialminbinnumber=int (($position-$overlapsize-1)/($windowsize-$overlapsize));
	$potentialminbinnumber=0 if $potentialminbinnumber < 0;
	$potentialmaxbinnumber=int (($position-1)/($windowsize-$overlapsize));
	for ($binnumber=$potentialminbinnumber;$binnumber<=$potentialmaxbinnumber;$binnumber++)
	{
		if (!exists $snp{$chr}{$binnumber}{$minnumber})
		{
			$snp{$chr}{$binnumber}{$minnumber}=1;
		}
		else
		{
			$snp{$chr}{$binnumber}{$minnumber}++;
		}
	}
	
}
close (INPUT);

$b1=($samplenumber+1)/(3*($samplenumber-1));
$b2=2*($samplenumber*$samplenumber+$samplenumber+3)/(9*$samplenumber*($samplenumber-1));

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
print OUTPUT "#seqid\tbin_start\tbin_end\tpi\tpop_name\tSe\n";
foreach $chr (sort keys %snp)
{
	foreach $bin (sort {$a <=> $b} keys %{$snp{$chr}})
	{
		$binstart=$bin*($windowsize-$overlapsize)+1;
		$binend=$bin*($windowsize-$overlapsize)+$windowsize;
		$sumx=0;
		foreach (keys %{$snp{$chr}{$bin}})
		{
			$sumx +=$_*($samplenumber-$_)*$snp{$chr}{$bin}{$_};
		}
		$pi=($sumx*2)/($samplenumber*($samplenumber-1)*$windowsize);
		$se=sqrt ($b1*$pi/$windowsize+$b2*$pi*$pi);
		if($popname)
		{
			print OUTPUT "$chr\t$binstart\t$binend\t$pi\t$popname\t$se\n";
		}
		else
		{
			print OUTPUT "$chr\t$binstart\t$binend\t$pi\t\t$se\n";
		}
	}
}
close (OUTPUT);
__END__

=head1 NAME

piBinMaker.pl - Creating pi value bins

=head1 SYNOPSIS

piBinMaker.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -output          output file
   -window          window size
   -overlap         overlap size
   -popname         population name

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a file in Tab delimited text format. For example,

 #chr	position 	sample1	sameple2	sameple3	...
 chr01	1354	G	A	G	...
 chr01	1547	T	T	C	...
 ...

=item B<-output>

Output data to a file.

=item B<-window>

Set the window size (int > 0) for each bin.

=item B<-overlap> (optional)

overlap size must be smaller than window size, default is 0 (no overlap).

=item B<-popname> (optional)

popname is for giving a name (such as spiece) for the population.

=back

=head1 DESCRIPTION

B<piBinMaker> will ...

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

binMaker.pl tdBinMaker.pl thetaBinMaker.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
