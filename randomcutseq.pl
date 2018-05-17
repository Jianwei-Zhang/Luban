#!/usr/local/bin/perl -w
#
# This script random cut seq into spieces


print "Please input GenBank sequence file name:";
chop($gbfile=<STDIN>);
print "Please type out-file name:";
chop($outfile=<STDIN>);

$seqtitle="";
open (INPUT,"$gbfile") or die "can't open GenBank File: $!";
while(<INPUT>)
{
	chop;
	if(/>/)
	{
		/gb\|(.*)\.\d*\|/;
		$seqtitle=$1;
		next;
	}
	$sequence{$seqtitle} .= $_;
}
close (INPUT);
@lengthrange=(2000 .. 20000);
open (OUTPUT,">$outfile") or die "can't open OUT-FILE: $!";
foreach $seqtitlemember (sort keys %sequence)
{
	while (length($sequence{$seqtitlemember}) > 0)
	{
		$ramdomlength=$lengthrange[rand @lengthrange];
		print $ramdomlength."\n";
		if($ramdomlength < length($sequence{$seqtitlemember}))
		{
			push @$seqtitlemember, substr($sequence{$seqtitlemember},0,$ramdomlength);
			$sequence{$seqtitlemember}=substr($sequence{$seqtitlemember},$ramdomlength,length($sequence{$seqtitlemember})-$ramdomlength)
		}
		else
		{
			push @$seqtitlemember, $sequence{$seqtitlemember};
			$sequence{$seqtitlemember}="";
		}
	}
	$i=0;
	foreach $seqfragment (@$seqtitlemember)#sort 
	{
		$fragmentlength=length($seqfragment);
		print OUTPUT ">$seqtitlemember-$i $fragmentlength bp\n$seqfragment\n";
		$i++;
	}
}
close (OUTPUT);
