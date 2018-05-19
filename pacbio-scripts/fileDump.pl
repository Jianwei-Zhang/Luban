#!/usr/bin/perl -w
use strict;

print "This scirpt is to dump the data sets based on a given list of smrtcells.\n";
print "Please see 'sampleSmrtcell.list' for an example.\n";

print "Please input a list of Smrtcells to be collected (.list):";
chop(my $smrtcells=<STDIN>);

until ($smrtcells =~ /\.list$/ && -e $smrtcells)
{
	print "Please input a list of Smrtcells to be collected (.list):";
	chop($smrtcells=<STDIN>);
}

my $targetDir=$smrtcells;
$targetDir =~ s/\.list$//;
print "The target directory existed. It seems that you've dumped the data already. Check your archive directory now.\n" and exit if (-d "/data/archive/$targetDir"); # this is to avoid overwrite.
`mkdir /data/archive/$targetDir`;

print "Do you want to delete the orginal files?(Yes/No):";
chop(my $delete=<STDIN>);
until ($delete =~ /^NO$/i || $delete =~ /^YES$/i)
{
	print "Do you want to delete the orginal ones?(Yes/No):";
	chop($delete=<STDIN>);
}

my $number = 1;
open FILE, "$smrtcells";
while (<FILE>)
{
	chomp;
	/^#/ and next;
	my @smrtcellLine = split /\s+/,$_;
	print "$number. $smrtcellLine[0]\n";
	if($delete =~ /^YES$/i)
	{
		`mv $smrtcellLine[1] /data/archive/$targetDir/$smrtcellLine[0]`;
	}
	else
	{
		`mkdir /data/archive/$targetDir/$smrtcellLine[0]`;
		`rsync -r $smrtcellLine[1]/* /data/archive/$targetDir/$smrtcellLine[0]`;
	}
	$number++;
}
close FILE;
