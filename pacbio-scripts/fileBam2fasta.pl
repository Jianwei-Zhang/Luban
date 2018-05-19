#!/usr/bin/perl -w
use strict;
print "This script is to convert bam files into fasta based on a given list of smrtcells.\n";
print "Please see 'sampleSmrtcell.list' for an example.\n";
print "Please input a list of Smrtcells or a run directory to be checked:";
chop(my $input=<STDIN>);
print "Please type output directory name:";
chop(my $output=<STDIN>);
until (!-e $output)
{
	print "Output directory exists. Please type another name:";
	chop($output=<STDIN>);
}
`mkdir $output`;

my @cellDir;
if (-f $input) # if provide a list of smrtcells, can be used for collecting data from original directories
{
	open FILE, "$input";
	while (<FILE>)
	{
		chomp;
		/^#/ and next;
		my @smrtcellLine = split /\s+/,$_;	
		push @cellDir, $smrtcellLine[1];
	}
	close FILE;
}
elsif(-d $input) # if provide a run directory, can be used for a collection data directory.
{
	opendir(DIR, $input) or die "can't opendir $input: $!";
	my @cells = readdir(DIR);
	closedir DIR;
	foreach my $cell (sort @cells)
	{
		next if ($cell =~ /^\./);
		push @cellDir, "$input/$cell";
	}
}

my $number = 1;

for my $cell (sort @cellDir)
{
	print "$number. $cell\n";
	opendir(DIR, $cell) or die "can't opendir $cell: $!";
	my @fileAndDirs = readdir(DIR);
	closedir DIR;
	foreach my $fileAndDir (@fileAndDirs)
	{
		next if ($fileAndDir =~ /^\./);
		next if(-d "$cell/$fileAndDir");

		if ($fileAndDir =~ /(.*)subreads.bam$/)
		{
			my $outputPrefix = $1;
			$outputPrefix .= 'subreads';

			`bam2fasta $cell/$fileAndDir -o $outputPrefix`;
			`gunzip $outputPrefix.fasta.gz`;
			`mv $outputPrefix.fasta $output`;
		}
	}
	$number++;
}
