#!/usr/bin/perl -w
use strict;

print "This scirpt is to restore the dumped data sets based on a given list of smrtcells.\n";
print "Please see 'sampleSmrtcell.list' for an example.\n";
print "Please input a list of Smrtcells to be restored (.list):";
chop(my $smrtcells=<STDIN>);
until ($smrtcells =~ /\.list$/ && -e $smrtcells)
{
	print "Please input a list of Smrtcells to be restored (.list):";
	chop($smrtcells=<STDIN>);
}

my $dumpDir=$smrtcells;
$dumpDir =~ s/\.list$//;
print "The target (dumped) directory does NOT exist. Check your archive directory now.\n" and exit unless (-d "/data/archive/$dumpDir"); 

print "Do you want to keep the dumped files?(Yes/No):";
chop(my $keep=<STDIN>);
until ($keep =~ /^NO$/i || $keep =~ /^YES$/i)
{
	print "Do you want to keep the dumped files?(Yes/No):";
	chop($keep=<STDIN>);
}

my $number = 1;
open FILE, "$smrtcells";
while (<FILE>)
{
	chomp;
	/^#/ and next;
	my @smrtcellLine = split /\s+/,$_;
	print "$number. $smrtcellLine[0]\n";
	if($keep =~ /^NO$/i)
	{
		my $originalDir = '';
		foreach (split /\//, $smrtcellLine[1])
		{
			$originalDir .= ($originalDir) ? "$_/" : "$_";
			`mkdir $originalDir` unless (-d $originalDir);
		}
		`mv /data/archive/$dumpDir/$smrtcellLine[0] $smrtcellLine[1]`;
	}
	else
	{
		my $originalDir = '';
		foreach (split /\//, $smrtcellLine[1])
		{
			$originalDir .= ($originalDir) ? "$_/" : "$_";
			`mkdir $originalDir` unless (-d $originalDir);
		}
		`rsync -r /data/archive/$dumpDir/$smrtcellLine[0]/* $smrtcellLine[1]`;
	}
	$number++;
}
close FILE;
