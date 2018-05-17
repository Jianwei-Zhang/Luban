#!/usr/local/bin/perl -w
#
# This script will pull out columns from tab determined file.

print "Please input tab file name:";
chop($tabfile=<STDIN>);

print "Column number (saperated by space):";
chop($colnumber=<STDIN>);
#$colnumber =~ s/\D/ /g;
@colnumberlist = split (/\D+/,$colnumber);
print "Column(s) [";
print join ", ",@colnumberlist;
print "] will be exported.\n";

print "Please type out-file name:";
chop($outfile=<STDIN>);
open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
open (INPUT,"$tabfile") or die "can't open TAB File: $!";
while(<INPUT>)
{
	@blastline=split(/\t/,$_);
	foreach (@colnumberlist)
	{
		print OUTPUT $blastline[$_ - 1]."\t";
	}
	print OUTPUT "\n";
}
close (INPUT);
close (OUTPUT);
