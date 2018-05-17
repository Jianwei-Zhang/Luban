#!/usr/local/bin/perl -w
#
# This script retrieve the sequences length from fasta file


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
		next;
	}
  $seqlength{$seqtitle} += length($_);
}
close (SEQDB);

open (OUTPUT,">$seqdb.length") or die "can't open OUT-FILE: $!";
print OUTPUT "#seqid\tseqlength\n";
foreach $seqid (keys %seqlength)
{
	print OUTPUT "$seqid\t$seqlength{$seqid}\n";
}
close (OUTPUT);
