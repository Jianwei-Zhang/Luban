#!/usr/local/bin/perl -w
#
# This script separate the sequences from fasta file according to their title

print "Please input fasta sequence file:";
chop($seqdb=<STDIN>);
print "Please sequence id file:";
chop($seqidfile=<STDIN>);
print "Please type output file:";
chop($outfile=<STDIN>);

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

open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
open (SEQID,"$seqidfile") or die "can't open seqid FILE: $!";
while(<SEQID>)
{
	chop;
	if(defined $sequence{$_})
	{
    print OUTPUT ">";
    print OUTPUT $_;
    print OUTPUT "\n";
  	print OUTPUT $sequence{$_};
    print OUTPUT "\n";
  }
  else
  {
    print $_;
    print " couldn't be found.\n"
  }
}
close (SEQID);

close (OUTPUT);
