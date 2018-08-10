#!/usr/bin/perl -w
#this script will change all acgt to N in sequence file.

print "Please input Sequence File name:";
chop($seqfile=<STDIN>);
print "Please type out-file name:";
chop($outfile=<STDIN>);


open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";

open (INPUT,"$seqfile") or die "can't open Sequence File: $!";
while(<INPUT>)
{
	if(/>/)
  {
    print OUTPUT $_;
    next;
  }
  else
  {
    tr/[acgt]/N/;
    print OUTPUT $_;
  }
}
close (INPUT);
close (OUTPUT);

