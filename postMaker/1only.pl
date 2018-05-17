#!/usr/bin/perl -w
use strict;
#This is to selet on annotations where the second column == maker
print "Please type input gff file name from gff3_merge:";
chop(my $input=<STDIN>);
print "Please type output file name:";
chop(my $outfile=<STDIN>);

open (FL,$input) or die("Can't open '$input': $!");
open (FLS,">$outfile") or die("Can't open '$outfile': $!");
while (<FL>){
	chomp;
	if(/#/)
	{
		print FLS "$_\n";
		next;
	} 
	my @line = split/\t/;
	if ($line[1] eq 'maker'){
#		$line[8] =~ s/maker-//g;
		print FLS "$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\n";
	}
}
close (FLS);
close (FL);
