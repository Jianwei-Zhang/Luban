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
my $confidencelimit = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'output=s' => \$output,
			'window=i' => \$windowsize,
			'overlap=i' => \$overlapsize,
			'popname=s' => \$popname,
			'confidence=s' => \$confidencelimit,
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
		if (!exists $snp{$chr}{$binnumber})
		{
			$snp{$chr}{$binnumber}=1;
		}
		else
		{
			$snp{$chr}{$binnumber}++;
		}
		if (!exists $pisnp{$chr}{$binnumber}{$minnumber})
		{
			$pisnp{$chr}{$binnumber}{$minnumber}=1;
		}
		else
		{
			$pisnp{$chr}{$binnumber}{$minnumber}++;
		}
	}
	
}
close (INPUT);
$a1=0;
$a2=0;
for($i=1;$i<$samplenumber;$i++)
{
	$a1 += 1/$i;
	$a2 += 1/($i*$i);
}
$b1=($samplenumber+1)/(3*($samplenumber-1));
$b2=2*($samplenumber*$samplenumber+$samplenumber+3)/(9*$samplenumber*($samplenumber-1));
$c1=$b1-1/$a1;
$c2=$b2-($samplenumber+2)/($a1*$samplenumber)+$a2/($a1*$a1);
$e1=$c1/$a1;
$e2=$c2/($a1*$a1+$a2);

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
if($confidencelimit)
{
	print OUTPUT "#seqid\tbin_start\tbin_end\tTD($confidencelimit)\tpop_name\tPi\ttheta\n";
	foreach (split (/\,/,$confidencelimit))
	{
		@confidencelimit=split (/:/,$_);
		($confidencelimitmin{$confidencelimit[0]},$confidencelimitmax{$confidencelimit[0]})=split (/~/,$confidencelimit[1]);
	}
}
else
{
	print OUTPUT "#seqid\tbin_start\tbin_end\tTD\tpop_name\tPi\ttheta\n";
}
foreach $chr (sort keys %snp)
{
	foreach $bin (sort {$a <=> $b} keys %{$snp{$chr}})
	{
		$binstart=$bin*($windowsize-$overlapsize)+1;
		$binend=$bin*($windowsize-$overlapsize)+$windowsize;
		$s=$snp{$chr}{$bin};
		$theta=$s/($a1*$windowsize);
		$sumx=0;
		foreach (keys %{$pisnp{$chr}{$bin}})
		{
			$sumx +=$_*($samplenumber-$_)*$pisnp{$chr}{$bin}{$_};
		}
		$pi=$sumx*2/($samplenumber*($samplenumber-1)*$windowsize);
		$td= ($sumx*2/($samplenumber*($samplenumber-1))-$s/$a1)/sqrt($e1*$s+$e2*$s*($s-1));
		#mark confidence
		$tdconfidence="";
		if($confidencelimit)
		{
			foreach (keys %confidencelimitmin)
			{
				$tdconfidence .= "*" if (($td <= $confidencelimitmin{$_}) || ($td >= $confidencelimitmax{$_}));
			}
		}
		if($popname)
		{
			print OUTPUT "$chr\t$binstart\t$binend\t$td$tdconfidence\t$popname\t$pi\t$theta\n";
		}
		else
		{
			print OUTPUT "$chr\t$binstart\t$binend\t$td$tdconfidence\t\t$pi\t$theta\n";
		}
	}
}
close (OUTPUT);
__END__

=head1 NAME

tdBinMaker.pl - Creating Tajima's D value bins

=head1 SYNOPSIS

tdBinMaker.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -output          output file
   -window          window size
   -overlap         overlap size
   -popname         population name
   -confidence      confidence limit list

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

=item B<-confidence> (optional)

confidence limit will mark the confidence by the given value, for example:

B<-confidence 95:-1.663~1.975,99:-1.830~2.313>

=back

=head1 DESCRIPTION

B<tdBinMaker> will calculate Tajima's D value.

=head1 REFERENCE

http://en.wikipedia.org/wiki/Tajima's_D

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

binMaker.pl piBinMaker.pl thetaBinMaker.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
