#!/usr/local/bin/perl -w
#
# This script remove the duplicated sequences (name) in GenBank fasta file

print "Please input fasta sequence file name:";
chop($gbfile=<STDIN>);
print "Please type out-file name:";
chop($outfile=<STDIN>);
$flag=0;
%sequencetitle=();
open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
open (INPUT,"$gbfile") or die "can't open GenBank File: $!";
while(<INPUT>)
{
	if(/>/)
	{
		if(exists $sequencetitle{$_})
		{
			$flag=0;
		}
		else
		{
			$flag=1;
			$sequencetitle{$_}=1;
  			print OUTPUT $_;
		}
		next;
	}
	else
	{
		if ($flag == 1)
		{
			print OUTPUT $_;
		}
		else
		{
			next;
		}
  }
}
close (INPUT);
close (OUTPUT);
