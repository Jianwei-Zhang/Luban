#!/usr/local/bin/perl -w
#
# This script will screen blastresult according to some critirias.

print "Please input blast result file name:";
chop($blastfile=<STDIN>);

print "Identity percentage(eg. 98 means identity equals or is larger than 98%, 90 is default):";
chop($percentage=<STDIN>);
if ($percentage eq "")
{
	$percentage=90;
}

print "Overlapping length(eg. 100 means overlapping length equals or is larger than 100, 30 is default):";
chop($overlapping=<STDIN>);
if ($overlapping eq "")
{
	$overlapping=30;
}

print "Please type out-file name:";
chop($outfile=<STDIN>);
open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
open (INPUT,"$blastfile") or die "can't open BLAST result File: $!";
while(<INPUT>)
{

	@blastline=split(/\t/,$_);
	if (($blastline[0] eq $blastline[1]) || ($blastline[2] < $percentage) || ($blastline[3] < $overlapping))
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
