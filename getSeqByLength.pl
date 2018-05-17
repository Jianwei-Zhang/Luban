#!/usr/local/bin/perl -w
#
# This script separate the sequences from fasta file according to their length

print "Please input fasta sequence file:";
chop($seqdb=<STDIN>);
print "Please type length(eg, 80, means separate the sequence less than 80 into a file):";
chop($seqlengthlimit=<STDIN>);
print "*"x80,"\n";
print "Output files will be named as \n";
print "$seqdb.lt.$seqlengthlimit\n$seqdb.ge.$seqlengthlimit\n";
print "*"x80,"\n";

open (SEQDB,"$seqdb") or die "can't open fasta sequence FILE: $!";
while(<SEQDB>)
{
	chop;
	if(/>/)
	{
		$seqtitle=$';
		$seqlength{$seqtitle}=0;
		$sequence{$seqtitle} = "";
		next;
	}
	$sequence{$seqtitle} .= $_;
  $seqlength{$seqtitle} += length($_);
}
close (SEQDB);

open (OUTPUT1,">$seqdb.lt.$seqlengthlimit") or die "can't open OUT-FILE: $!";
open (OUTPUT2,">$seqdb.ge.$seqlengthlimit") or die "can't open OUT-FILE: $!";
foreach $seqid (keys %seqlength)
{
	if ($seqlength{$seqid} < $seqlengthlimit)
	{
		print OUTPUT1 ">$seqid\tlength:$seqlength{$seqid}\n$sequence{$seqid}\n";
	}
	else
	{
		print OUTPUT2 ">$seqid\tlength:$seqlength{$seqid}\n$sequence{$seqid}\n";
	}
}
close (OUTPUT1);
close (OUTPUT2);
