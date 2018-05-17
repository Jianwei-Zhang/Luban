#!/usr/local/bin/perl -w
#
# This script remove the line where query id equals subject id.
print "Please input blast result file name:";
chop($blastfile=<STDIN>);
print "Please type out-file name:";
chop($outfile=<STDIN>);
open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
open (INPUT,"$blastfile") or die "can't open BLAST result File: $!";
while(<INPUT>)
{
	@blastline=split(/\t/,$_);
	if ($blastline[1] eq $blastline[0])
	{
		next;
	}
	else
	{
		print OUTPUT $_;
	}
}
close (INPUT);
close (OUTPUT);
