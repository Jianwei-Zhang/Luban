#!/usr/local/bin/perl -w
#
# gffBinMaker.pl
#
# This script sum element length in a bin

print "Please input gff file:";
chop($gfffile=<STDIN>);

print "Please input bin size (100,000 default):";
chop($binsize=<STDIN>);
if($binsize eq "")
{
	$binsize=100000;
}
print "Please type output file:";
chop($outfile=<STDIN>);
%leng=();
open (GFFFILE,"$gfffile") or die "can't open GFF-FILE: $!";
while(<GFFFILE>)
{
	/^#/ and next;
	chop;
	@gffline=split(/\t/,$_);
	$leftwin=int 1+$gffline[3]/$binsize;
	$rightwin=int 1+$gffline[4]/$binsize;
	if($leftwin == $rightwin)
	{
		$leng{$gffline[0]}{$gffline[2]}{$leftwin} += $gffline[4]-$gffline[3]+1;
	}
	else
	{
		$leng{$gffline[0]}{$gffline[2]}{$leftwin} += ($rightwin-1)*$binsize-$gffline[3]+1;
		$leng{$gffline[0]}{$gffline[2]}{$rightwin} += $gffline[4]-($rightwin-1)*$binsize;		
	}
}
close (GFFFILE);
open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
for $seqid (sort {$a cmp $a} keys %leng)
{
	for $type (sort {$a cmp $a} keys %{$leng{$seqid}})
	{
		for $bin (sort {$a <=> $a} keys %{$leng{$seqid}{$type}})
		{
			$binstart=$bin*$binsize+1;
			$binend=($bin+1)*$binsize;
			print OUTPUT "$seqid\t$binstart\t$binend\t$leng{$seqid}{$type}{$bin}\t$type\n";
		}
	}
}
close (OUTPUT);
