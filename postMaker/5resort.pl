#!/usr/bin/perl -w
use strict;
use POSIX ":sys_wait_h";
#this is to reformat GFF content.
#features: gene, mRNA, exon, five_prime_UTR, CDS, three_prime_UTR
print "Please type input gff file name:";
chop(my $input=<STDIN>);
print "Please type input sort_order file name:\nA tab delimited file containing two columns: contig_id and sort_order.\n(Optional)";
chop(my $sortFile=<STDIN>);
print "Please type output gff file name:";
chop(my $outfile=<STDIN>);
my $threads = 20;

my %sortOrder;
if ($sortFile)
{
	open (SORTFILE,$sortFile) or die("Can't open '$sortFile': $!");
	while (<SORTFILE>)
	{
		/^#/ and next;
		my @line = split/\t/;
		$sortOrder{$line[0]} = $line[1];
	}
	close (SORTFILE);
}

my %seqid;
open INPUT,$input;
while (<INPUT>)
{
	/^#/ and next;
	my @line = split/\t/;
	if (-e "$outfile.$line[0].tmp")
	{
		open (TMP,">>$outfile.$line[0].tmp") or die("Can't open '$outfile.$line[0].tmp': $!");
		print TMP $_;
		close (TMP);
	}
	else
	{
		open (TMP,">$outfile.$line[0].tmp") or die("Can't open '$outfile.$line[0].tmp': $!");
		print TMP $_;
		close (TMP);
	}
	$seqid{$line[0]}++;
}
close INPUT;

my @seqid;
if ($sortFile)
{
	@seqid = sort {$sortOrder{$a} <=> $sortOrder{$b}} keys %seqid;
}
else
{
	@seqid = sort {$a cmp $b} keys %seqid;
}

my @allPid;
my $runningPid;
foreach (@seqid)
{
	my $seqid = $_;
	my $pid = fork();
	# Check if parent/child process
	if ($pid)
	{ # Parent
		push @allPid, $pid;
	}
	elsif ($pid == 0)
	{ # Child
		my %gene;
		my %mRNA;
		my %exon;
		my %fivePrimeUTR;
		my %CDS;
		my %threePrimeUTR;
		my %other;
		my $lineNumber = 0;
		my %sort;
		open (TMP,"$outfile.$seqid.tmp") or die("Can't open '$outfile.$seqid.tmp': $!");
		while (<TMP>)
		{
			chomp;
			$lineNumber++;
	
			my @line = split/\t/;
			my $id;
			if ($line[8] =~ /ID=([^;]+);/)
			{
				$id = $1;
			}
			if ($line[2] eq 'gene')
			{
				$gene{$lineNumber} = $_;
				$sort{$lineNumber} = $id;
			}
			elsif($line[2] eq 'mRNA')
			{
				$mRNA{$lineNumber} = $_;
				$sort{$lineNumber} = $id;
			}
			elsif($line[2] eq 'exon')
			{
				$exon{$lineNumber} = $_;
				$sort{$lineNumber} = $line[3];
			}
			elsif($line[2] eq 'five_prime_UTR')
			{
				$fivePrimeUTR{$lineNumber} = $_;
				$sort{$lineNumber} = $line[3];
			}
			elsif($line[2] eq 'CDS')
			{
				$CDS{$lineNumber} = $_;
				$sort{$lineNumber} = $line[3];
			}
			elsif($line[2] eq 'three_prime_UTR')
			{
				$threePrimeUTR{$lineNumber} = $_;
				$sort{$lineNumber} = $line[3];
			}
			else
			{
				$other{$lineNumber} = $_;
				$sort{$lineNumber} = $line[3];
				print "notSorted\t$_\n";
			}
		}
		close (TMP);
		unlink ("$outfile.$seqid.tmp");

		my %printedmRNALine;
		my %printedExonLine;
		my %printedFivePrimeUTRLine;
		my %printedCDSLine;
		my %printedThreePrimeUTRLine;

		open (SORTED,">$outfile.$seqid.sorted") or die("Can't open '$outfile.$seqid.sorted': $!");
		foreach (sort {$sort{$a} cmp $sort{$b}} keys %gene)
		{
			my $geneLine = $gene{$_};
			my @geneLine = split /\t/, $geneLine;
			my $geneId;
			if ($geneLine[8] =~ /ID=([^;]+);/)
			{
				$geneId = $1;
			}
			print SORTED "$geneLine\n";

			my @mrnaId;
			my %mrnaStrain;
			my $mrnaLineNumber = 0;
			foreach (sort {$sort{$a} cmp $sort{$b}} keys %mRNA)
			{
				$mrnaLineNumber++;
				my $mrnaLine = $mRNA{$_};
				next if (exists $printedmRNALine{$mrnaLineNumber});
				next if ($mrnaLine !~ /$geneId/);
				my @mrnaLine = split /\t/, $mrnaLine;
				if ($mrnaLine[8] =~ /ID=([^;]+);/)
				{
					my $mrnaId = $1;
					if ($mrnaLine[8] =~ /\S+;Parent=([^;]+)/)
					{
						my @parents = split /,/,$1;
						for my $parent (@parents)
						{
							if ($parent eq $geneId)
							{
								push @mrnaId,$mrnaId;
								$mrnaStrain{$mrnaId} = $mrnaLine[6];
								print SORTED "$mrnaLine\n";
								$printedmRNALine{$mrnaLineNumber} = 1;
							}
						}
					}
				}
			}

			foreach (@mrnaId)
			{
				my $mrnaId = $_;
				my $exonLineNumber = 0;
				foreach (sort {$sort{$a} <=> $sort{$b}} keys %exon) #find exons
				{
					$exonLineNumber++;
					my $exonLine = $exon{$_};
					next if (exists $printedExonLine{$exonLineNumber});
					next if ($exonLine !~ /$mrnaId/);
					my @exonLine = split /\t/, $exonLine;

					if ($exonLine[8] =~ /\S+;Parent=([^;]+)/)
					{
						my @parents = split /,/,$1;
						for my $parent (@parents)
						{
							if ($parent eq $mrnaId)
							{
								print SORTED "$exonLine\n";
								$printedExonLine{$exonLineNumber} = 1;
							}
						}
					}
				}
			}
			foreach (@mrnaId) 
			{
				my $mrnaId = $_;
				if($mrnaStrain{$mrnaId} eq "+")
				{
					my $fivePrimeUTRLineNumber = 0;
					foreach (sort {$sort{$a} <=> $sort{$b}} keys %fivePrimeUTR) #find fivePrimeUTRs
					{
						$fivePrimeUTRLineNumber++;
						my $fivePrimeUTRLine = $fivePrimeUTR{$_};
						next if (exists $printedFivePrimeUTRLine{$fivePrimeUTRLineNumber});
						next if ($fivePrimeUTRLine !~ /$mrnaId/);
						my @fivePrimeUTRLine = split /\t/, $fivePrimeUTRLine;

						if ($fivePrimeUTRLine[8] =~ /\S+;Parent=([^;]+)/)
						{
							my @parents = split /,/,$1;
							for my $parent (@parents)
							{
								if ($parent eq $mrnaId)
								{
									print SORTED "$fivePrimeUTRLine\n";
									$printedFivePrimeUTRLine{$fivePrimeUTRLineNumber} = 1;
								}
							}
						}
					}
					my $CDSLineNumber = 0;
					foreach (sort {$sort{$a} <=> $sort{$b}} keys %CDS) #find CDSs
					{
						$CDSLineNumber++;
						my $CDSLine = $CDS{$_};
						next if (exists $printedCDSLine{$CDSLineNumber});
						next if ($CDSLine !~ /$mrnaId/);
						my @CDSLine = split /\t/, $CDSLine;

						if ($CDSLine[8] =~ /\S+;Parent=([^;]+)/)
						{
							my @parents = split /,/,$1;
							for my $parent (@parents)
							{
								if ($parent eq $mrnaId)
								{
									print SORTED "$CDSLine\n";
									$printedCDSLine{$CDSLineNumber} = 1;
								}
							}
						}
					}
					my $threePrimeUTRLineNumber = 0;
					foreach (sort {$sort{$a} <=> $sort{$b}} keys %threePrimeUTR) #find threePrimeUTRs
					{
						$threePrimeUTRLineNumber++;
						my $threePrimeUTRLine = $threePrimeUTR{$_};
						next if (exists $printedThreePrimeUTRLine{$threePrimeUTRLineNumber});
						next if ($threePrimeUTRLine !~ /$mrnaId/);
						my @threePrimeUTRLine = split /\t/, $threePrimeUTRLine;

						if ($threePrimeUTRLine[8] =~ /\S+;Parent=([^;]+)/)
						{
							my @parents = split /,/,$1;
							for my $parent (@parents)
							{
								if ($parent eq $mrnaId)
								{
									print SORTED "$threePrimeUTRLine\n";
									$printedThreePrimeUTRLine{$threePrimeUTRLineNumber} = 1;
								}
							}
						}
					}
				}
				else
				{
					my $threePrimeUTRLineNumber = 0;
					foreach (sort {$sort{$a} <=> $sort{$b}} keys %threePrimeUTR) #find threePrimeUTRs
					{
						$threePrimeUTRLineNumber++;
						my $threePrimeUTRLine = $threePrimeUTR{$_};
						next if (exists $printedThreePrimeUTRLine{$threePrimeUTRLineNumber});
						next if ($threePrimeUTRLine !~ /$mrnaId/);
						my @threePrimeUTRLine = split /\t/, $threePrimeUTRLine;

						if ($threePrimeUTRLine[8] =~ /\S+;Parent=([^;]+)/)
						{
							my @parents = split /,/,$1;
							for my $parent (@parents)
							{
								if ($parent eq $mrnaId)
								{
									print SORTED "$threePrimeUTRLine\n";
									$printedThreePrimeUTRLine{$threePrimeUTRLineNumber} = 1;
								}
							}
						}
					}
					my $CDSLineNumber = 0;
					foreach (sort {$sort{$a} <=> $sort{$b}} keys %CDS) #find CDSs
					{
						$CDSLineNumber++;
						my $CDSLine = $CDS{$_};
						next if (exists $printedCDSLine{$CDSLineNumber});
						next if ($CDSLine !~ /$mrnaId/);
						my @CDSLine = split /\t/, $CDSLine;

						if ($CDSLine[8] =~ /\S+;Parent=([^;]+)/)
						{
							my @parents = split /,/,$1;
							for my $parent (@parents)
							{
								if ($parent eq $mrnaId)
								{
									print SORTED "$CDSLine\n";
									$printedCDSLine{$CDSLineNumber} = 1;
								}
							}
						}
					}
					my $fivePrimeUTRLineNumber = 0;
					foreach (sort {$sort{$a} <=> $sort{$b}} keys %fivePrimeUTR) #find fivePrimeUTRs
					{
						$fivePrimeUTRLineNumber++;
						my $fivePrimeUTRLine = $fivePrimeUTR{$_};
						next if (exists $printedFivePrimeUTRLine{$fivePrimeUTRLineNumber});
						next if ($fivePrimeUTRLine !~ /$mrnaId/);
						my @fivePrimeUTRLine = split /\t/, $fivePrimeUTRLine;

						if ($fivePrimeUTRLine[8] =~ /\S+;Parent=([^;]+)/)
						{
							my @parents = split /,/,$1;
							for my $parent (@parents)
							{
								if ($parent eq $mrnaId)
								{
									print SORTED "$fivePrimeUTRLine\n";
									$printedFivePrimeUTRLine{$fivePrimeUTRLineNumber} = 1;
								}
							}
						}
					}
				}
			}
		}
		close (SORTED);
		exit 0;  # It is STRONGLY recommended to exit your child process
	}
	else
	{ # Unable to fork
		die "ERROR: Could not fork new process: $!\n\n";
	}
	$runningPid = @allPid; #wait until less threads
	do {
		$runningPid = 0;
		foreach my $pidMember (@allPid)
		{
			my $kid = waitpid($pidMember, WNOHANG);
			$runningPid++ if $kid == 0;
		}
	} while $runningPid > $threads;
}

$runningPid = @allPid; #wait until all threads finished
do {
	$runningPid = 0;
	foreach my $pidMember (@allPid)
	{
		my $kid = waitpid($pidMember, WNOHANG);
		$runningPid++ if $kid == 0;
	}
} while $runningPid > 0;

#create blank file
open (OUTPUT,">$outfile") or die("Can't open '$outfile': $!");
print OUTPUT "##gff-version 3\n";
foreach (@seqid)
{
	my $seqid = $_;
	open (SORTED,"$outfile.$seqid.sorted") or die("Can't open '$outfile.$seqid.sorted': $!");
	while (<SORTED>)
	{
		print OUTPUT $_;
	}
	close (SORTED);
	unlink ("$outfile.$seqid.sorted");	
}
close (OUTPUT);
