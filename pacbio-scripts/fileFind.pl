#!/usr/bin/perl -w
use strict;
my $currentDir = '.';
my %sampleNameList;
opendir(DIR, $currentDir) or die "can't opendir $currentDir: $!";
my @runs = readdir(DIR);
closedir DIR;
foreach my $run (sort @runs)
{
	next if ($run =~ /^\./);
	next if (-f "$run"); #skip files
	next if ($run eq 'tmp'); #skip reserved dirs
	next if ($run eq 'ascpTestDir'); #skip reserved dirs
	next if ($run eq 'usedScripts'); #skip reserved dirs
	opendir(DIR, "$run") or die "can't opendir $run: $!";
	my @smrtcells = readdir(DIR);
	closedir DIR;
	my $numberOfSmrtcells = 0;
	foreach my $smrtcell (sort @smrtcells)
	{
		next if ($smrtcell =~ /^\./);
		if (-f "$run/$smrtcell")
		{
			print "#File found: $run/$smrtcell\n";
			print "rmf -fr $run/$smrtcell\n";
			next;
		}
		$numberOfSmrtcells++;
		opendir(DIR, "$run/$smrtcell") or die "can't opendir $run/$smrtcell: $!";
		my @files = readdir(DIR);
		closedir DIR;
		foreach my $file (sort @files)
		{
			next if ($file =~ /^\./);
			next if (-d "$run/$smrtcell/$file");
			if ($file =~ /metadata.xml$/)
			{
				open FILE, "$run/$smrtcell/$file";
				while (<FILE>)
				{
					if (/<Sample><Name>(.*)<\/Name><PlateId>/)
					{
						my $sampleName = $1 ? $1 : 'noName';
						$sampleName =~ s/[^A-Za-z0-9\-\.\~\_]/-/g; #replace invalid characters with '-' for filename.
						$sampleName =~ s/^\W+//g;# replace the first non-word characters
						$sampleName =~ s/\W+$//g;# replace the last non-word characters
						$sampleName =~ s/\-\-/-/g;
						if (exists $sampleNameList{$sampleName})
						{
							$sampleNameList{$sampleName}++;
							print "$sampleName.$sampleNameList{$sampleName}\t$run/$smrtcell\t$file\tSMRTcellXML\tDuplicated sample name, postfix added.\n";
							print "tar -czf $sampleName.$sampleNameList{$sampleName}.tgz $run/$smrtcell\n";
							print "tar cf - $run/$smrtcell | pigz -p 8 > $sampleName.$sampleNameList{$sampleName}.tgz\n";
						}
						else
						{
							print "$sampleName\t$run/$smrtcell\t$file\tSMRTcellXML\n";
							$sampleNameList{$sampleName} = 0;				
							print "tar -czf $sampleName.tgz $run/$smrtcell\n";
							print "tar cf - $run/$smrtcell | pigz -p 8 > $sampleName.tgz\n";
						}
					}
				}
			}
		}
	}
	print "#No smrtcell found: $run\n" unless ($numberOfSmrtcells);
	print "rmd -fr $run\n" unless ($numberOfSmrtcells);
}