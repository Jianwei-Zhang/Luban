#!/usr/local/bin/perl -w
#
# This script count the repeat line if first column is the same as provious line

print "Please input file name:";
chop($blastfile=<STDIN>);
print "Please type out-file name:";
chop($outfile=<STDIN>);
%copynumber=();
open (INPUT,"$blastfile") or die "can't open BLAST result File: $!";
while(<INPUT>)
{
	@line=split(/\t/,$_);
	if (exists $copynumber{$line[0]})
	{
		$copynumber{$line[0]}++;
	}
	else
	{
		$copynumber{$line[0]}=1;
	}
}
close (INPUT);
open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
$unique=0;
foreach (sort keys %copynumber)
{
	if($copynumber{$_} == 1)
	{
		$unique++;
	}
	print OUTPUT "$_\t$copynumber{$_}\n";
}

close (OUTPUT);

print "$unique uniques.\n";