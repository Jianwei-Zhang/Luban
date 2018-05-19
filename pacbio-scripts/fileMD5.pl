#!/usr/bin/perl -w
use strict;
print "This script is specificly used to generate MD5 checksum list for SRA submission files prepared with fileForSRA.pl\n";
print "Please input a run directory name:";
chop(my $runDir=<STDIN>);
opendir(DIR, "$runDir") or die "can't opendir $runDir: $!";
my @smrtcells = readdir(DIR);
closedir DIR;

my $numberOfSmrtcells = @smrtcells;
my $order = 1;
open OUTPUT, ">$runDir.md5";
foreach my $smrtcell (sort @smrtcells)
{
	print "$order/$numberOfSmrtcells: $runDir/$smrtcell\n";
	$order++;
	next if ($smrtcell =~ /^\./);
	if (-f "$runDir/$smrtcell")
	{
		print OUTPUT "File found: $runDir/$smrtcell\n";
		next;
	}
	print OUTPUT "$smrtcell\t";

	opendir(DIR, "$runDir/$smrtcell") or die "can't opendir $runDir/$smrtcell: $!";
	my @files = readdir(DIR);
	closedir DIR;
	foreach my $file (sort @files)
	{
		next if ($file =~ /^\./);
		if (-d "$runDir/$smrtcell/$file")
		{
			opendir(DIR, "$runDir/$smrtcell/$file") or die "can't opendir $runDir/$smrtcell/$file: $!";
			my @analysisResults = readdir(DIR);
			closedir DIR;
			foreach my $analysisResult (sort @analysisResults)
			{
				next if ($analysisResult !~ /\.h5$/);
				my $mdFive = '';
				open (CMD,"md5sum $runDir/$smrtcell/$file/$analysisResult |") or die "can't open CMD: $!";
				while(<CMD>)
				{
					my @mdLine = split(" ",$_);
					$mdFive = $mdLine[0];
				}
				close(CMD);
				print OUTPUT "PacBio_HDF5\t$analysisResult\t$mdFive\t";
			}
			next;
		}
		if ($file =~ /metadata.xml/)
		{
			my $mdFive = '';
			open (CMD,"md5sum $runDir/$smrtcell/$file |") or die "can't open CMD: $!";
			while(<CMD>)
			{
				my @mdLine = split(" ",$_);
				$mdFive = $mdLine[0];
			}
			close(CMD);
			print OUTPUT "XML\t$file\t$mdFive\t";

			open FILE, "$runDir/$smrtcell/$file";
			while (<FILE>)
			{
				if (/<Sample><Name>(.*)<\/Name><PlateId>/)
				{
					print OUTPUT "$1\n";
				}
			}
			close FILE;
		}
	}
}
close OUTPUT;

print "Please check $runDir.md5 for the output.\n";

