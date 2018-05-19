#!/usr/bin/perl -w
use strict;

print "This scirpt is to collect the fasta files based on a given list of smrtcells.\n";
print "All orginal data will be kept after running this script.\n";
print "Please see 'sampleSmrtcell.list' for an example.\n";
print "Please input a list of Smrtcells or a run directory to be collected:";
chop(my $smrtcells=<STDIN>);

print "Please provide a target directory name:";
chop(my $targetDir=<STDIN>);
print "The directory existed. Delete it or provide a new one.\n" and exit if (-d "$targetDir"); # this is to avoid overwrite.
`mkdir $targetDir`;

my $number = 1;
if (-f $smrtcells) # if provide a list of smrtcells, can be used for collecting data from original directories
{
	open FILE, "$smrtcells";
	while (<FILE>)
	{
		chomp;
		/^#/ and next;
		my @smrtcellLine = split /\s+/,$_;
		print "$number. $smrtcellLine[0]\n";
		`mkdir $targetDir/$smrtcellLine[0]`;
		`mkdir $targetDir/$smrtcellLine[0]/Analysis_Results`;
		`rsync $smrtcellLine[1]/*.metadata.xml $targetDir/$smrtcellLine[0]`;
		`rsync $smrtcellLine[1]/Analysis_Results/*.fasta $targetDir/$smrtcellLine[0]/Analysis_Results`;
		$number++;
	}
	close FILE;
}
elsif(-d $smrtcells) # if provide a run directory, can be used for a collection data directory.
{
	opendir(DIR, $smrtcells) or die "can't opendir $smrtcells: $!";
	my @cells = readdir(DIR);
	closedir DIR;
	foreach my $cell (sort @cells)
	{
		next if ($cell =~ /^\./);
		print "$number. $cell\n";
		`mkdir $targetDir/$cell`;
		`mkdir $targetDir/$cell/Analysis_Results`;
		`rsync $smrtcells/$cell/*.metadata.xml $targetDir/$cell`;		
		`rsync $smrtcells/$cell/Analysis_Results/*.fasta $targetDir/$cell/Analysis_Results`;
		$number++;
	}
}
else
{
	`rm -fr $targetDir`;
	print "No $smrtcells found.\n";
}