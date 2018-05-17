#!/usr/local/bin/perl -w
#
# This script separate the sequences from fasta file according to the keyword in title line

print "Please input fasta sequence file:";
chop($seqdb=<STDIN>);
print "Please type one keyword(eg, hypothetical):";
chop($keyword=<STDIN>);
print "*"x80,"\n";
print "Output files will be named as \n";
print "$seqdb.is.$keyword\n$seqdb.not.$keyword\n";
print "*"x80,"\n";

open (SEQDB,"$seqdb") or die "can't open fasta sequence FILE: $!";
while(<SEQDB>)
{
	chop;
	if(/>/)
	{
		$seqtitle=$';
		$sequence{$seqtitle} = "";
		next;
	}
	$sequence{$seqtitle} .= $_;
}
close (SEQDB);

open (OUTPUT1,">$seqdb.is.$keyword") or die "can't open OUT-FILE: $!";
open (OUTPUT2,">$seqdb.not.$keyword") or die "can't open OUT-FILE: $!";
foreach $seqid (keys %sequence)
{
	if ($seqid =~ /$keyword/)
	{
		print OUTPUT1 ">$seqid\n$sequence{$seqid}\n";
	}
	else
	{
		print OUTPUT2 ">$seqid\n$sequence{$seqid}\n";
	}
}
close (OUTPUT1);
close (OUTPUT2);
