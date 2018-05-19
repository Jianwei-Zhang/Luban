#!/usr/local/bin/perl -w
#
# This script count the the length of class from repeatmasker result 

print "Please input RepeatMasker out file name:";
chop($rmfile=<STDIN>);
print "Please type out-file name:";
chop($outfile=<STDIN>);
open (INPUT,"$rmfile") or die "can't open RepeatMasker .out File: $!";
while(<INPUT>)
{
	1 .. /score/ and next;
	/^\s*$/ and next;
	s/^\s*//g;
	@line=split(/\s+/,$_);
	$repeatclass{$line[9]} += $line[6] - $line[5] + 1;
}
close (INPUT);
open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
foreach (keys %repeatclass)
{
	print OUTPUT $_,"\t",$repeatclass{$_},"\n";
}
close (OUTPUT);
