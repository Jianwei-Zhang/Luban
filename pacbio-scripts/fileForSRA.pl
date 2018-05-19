#!/usr/bin/perl -w
use strict;

print "This scirpt is to collect the data sets for a SRA submission based on a given list of smrtcells.\n";
print "All orginal data will be kept after running this script.\n";
print "Please see 'sampleSmrtcell.list' for an example.\n";
print "Please input a list of Smrtcells or a run directory to be collected:";
chop(my $smrtcells=<STDIN>);

print "Please provide a submission directory name:";
chop(my $submissionDir=<STDIN>);
print "The directory existed. Delete it or provide a new one.\n" and exit if (-d "$submissionDir"); # this is to avoid overwrite.
`mkdir $submissionDir`;

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
		`rsync $smrtcellLine[1]/*.metadata.xml $submissionDir`;
		`rsync $smrtcellLine[1]/Analysis_Results/*.h5 $submissionDir`;
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
		`rsync $smrtcells/$cell/*.metadata.xml $submissionDir`;		
		`rsync $smrtcells/$cell/Analysis_Results/*.h5 $submissionDir`;
		$number++;
	}
}
else
{
	`rm -fr $submissionDir`;
	print "No $smrtcells found.\n";
}
