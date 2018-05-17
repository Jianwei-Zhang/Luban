#!/usr/bin/perl -w
use strict;
#this is to get sequences from fasta based on GFF
print "Please type input gff name:";
chop(my $inputGff=<STDIN>);
print "Please type input transcript fasta name:";
chop(my $inputFastaTranscript=<STDIN>);
print "Please type input protein fasta name:";
chop(my $inputFastaProtein=<STDIN>);
print "Please type output transcript file name:";
chop(my $outfileTranscript=<STDIN>);
print "Please type output protein file name:";
chop(my $outfileProtein=<STDIN>);

my %seqid;
my %transcripts;
my %transcriptsDesc;
my %proteins;
my %proteinsDesc;

open (FL,$inputGff) or die("Can't open '$inputGff': $!");
while (<FL>)
{
	my @line = split/\t/;
	if ($line[2] eq 'mRNA')
	{
		my $id;
		my $alias;
		if ($line[8] =~ /ID=([^;]+)/)
		{
			$id = $1;
		}
		if ($line[8] =~ /Alias=([^;]+)/)
		{
			$alias = $1;
		}
		$seqid{$alias} = $id;
	}
}
close (FL);

my $seqtitle;
open (SEQDB,$inputFastaTranscript) or die("can't open '$inputFastaTranscript': $!");
while(<SEQDB>)
{
	s/\s*$//g;
#	s/maker-//g;
	if(/>(\S*) (.*)/)
	{
		$seqtitle = $1;
		$transcripts{$seqtitle} = '';
		$transcriptsDesc{$seqtitle} = $2;
		next;
	}
	$transcripts{$seqtitle} .= $_;
}
close (SEQDB);
open (SEQDB,$inputFastaProtein) or die("can't open '$inputFastaProtein': $!");
while(<SEQDB>)
{
	s/\s*$//g;
#	s/maker-//g;
	if(/>(\S*) (.*)/)
	{
		$seqtitle = $1;
		$proteins{$seqtitle} = '';
		$proteinsDesc{$seqtitle} = $2;
		next;
	}
	$proteins{$seqtitle} .= $_;
}
close (SEQDB);

open (FLS,">$outfileTranscript") or die("can't open '$outfileTranscript': $!");
open (FLSLOG,">$outfileTranscript.log") or die("can't open '$outfileTranscript.log': $!");
for (sort {$seqid{$a} cmp $seqid{$b}} keys %seqid)
{
	if (exists $transcripts{$_})
	{
		print FLS ">$seqid{$_} $_ $transcriptsDesc{$_}\n";
		print FLS &multiLineSeq($transcripts{$_},60);
	}
	else
	{
		print FLSLOG "notFound\t$_\t$seqid{$_}\n";
		print "notFound\t$_\t$seqid{$_}\n";
	}
}
close (FLS);
close (FLSLOG);
open (FLS,">$outfileProtein") or die("can't open '$outfileProtein': $!");
open (FLSLOG,">$outfileProtein.log") or die("can't open '$outfileProtein.log': $!");
for (sort {$seqid{$a} cmp $seqid{$b}} keys %seqid)
{
	if (exists $proteins{$_})
	{
		print FLS ">$seqid{$_} $_ $proteinsDesc{$_}\n";
		print FLS &multiLineSeq($proteins{$_},60);
	}
	else
	{
		print FLSLOG "notFound\t$_\t$seqid{$_}\n";
		print "notFound\t$_\t$seqid{$_}\n";
	}
}
close (FLS);
close (FLSLOG);

sub multiLineSeq
{ #split a long sequence to multi-line
	my ($readSequence, $lineLength) = @_;
	my $multiLineSeq;
	$readSequence =~ s/\s//g;
	for (my $position=0;$position < length($readSequence); $position +=$lineLength)
	{
		$multiLineSeq .= substr($readSequence,$position,$lineLength)."\n";
	}
	return $multiLineSeq;
}
#usage of multiLineSeq
#
#	  &multiLineSeq($sequence,80);
