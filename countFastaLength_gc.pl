#!/usr/local/bin/perl -w
#

print "Please input fasta sequence file:";
chop($seqdb=<STDIN>);
print "*"x80,"\n";
print "Output file will be named as $seqdb.length\n";
print "*"x80,"\n";

open (SEQDB,"$seqdb") or die "can't open fasta sequence FILE: $!";
while(<SEQDB>)
{
	$_ =~ s/\s*$//g;
	if(/>/)
	{
		$seqtitle=$';
		$seqlength{$seqtitle}=0;
		$baseg{$seqtitle}=0;
		$basec{$seqtitle}=0;
		$basea{$seqtitle}=0;
		$baset{$seqtitle}=0;
		next;
	}
  $seqlength{$seqtitle} += length($_);
  $baseg{$seqtitle} += ($_ =~ tr/Gg//);
  $basec{$seqtitle} += ($_ =~ tr/Cc//);
  $basea{$seqtitle} += ($_ =~ tr/Aa//);
  $baset{$seqtitle} += ($_ =~ tr/Tt//);
  $nonbase{$seqtitle} = $seqlength{$seqtitle} - $baseg{$seqtitle} - $basec{$seqtitle} - $basea{$seqtitle} - $baset{$seqtitle};
}
close (SEQDB);

open (OUTPUT,">$seqdb.length") or die "can't open OUT-FILE: $!";
print OUTPUT "#seqid\tseqlength\tG\tC\tA\tT\tnonbase\tGC content\n";
foreach $seqid (keys %seqlength)
{
	$gccontent=($baseg{$seqid}+$basec{$seqid})/$seqlength{$seqid};
	print OUTPUT "$seqid\t$seqlength{$seqid}\t$baseg{$seqid}\t$basec{$seqid}\t$basea{$seqid}\t$baset{$seqid}\t$nonbase{$seqid}\t$gccontent\n";
}
close (OUTPUT);
