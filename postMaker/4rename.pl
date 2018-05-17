#!/usr/bin/perl -w
use strict;
#and replace maker tag with locus_tag_prefixes
print "Please type input gff file name:";
chop(my $input=<STDIN>);
print "Please type seqId Prefix: (e.g. Chr)";
chop(my $seqIdPrefixes=<STDIN>);
print "Please type locus Tag Prefix: (e.g. A2J10)";
chop(my $locusTagPrefixes=<STDIN>);
print "Please type output gff file name:";
chop(my $outfile=<STDIN>);

my %alias;
my %aliasTranscript;
my %seqid;
my %position;

open (FL,$input) or die("Can't open '$input': $!");
open (FLS,">$outfile") or die("Can't open '$outfile': $!");
while (<FL>){
	chomp;
	/^#/ and next;
	my @line = split/\t/;
	if ($line[2] eq 'gene'){
		if ($line[8] =~ /ID=([^;]+);/)
		{
			my $id = $1;
			$seqid{$id} = $line[0];
			$position{$id} = $line[3];
		}
		else
		{
			print "err\t$_\n";
		}
	}
}
close (FL);

my %count;
foreach (sort {$position{$a} <=> $position{$b}} keys %position)
{
	$count{$seqid{$_}}++;
	my $geneNumber =  sprintf "%0*d", 7, $count{$seqid{$_}} * 100;
	$seqid{$_} =~ s/$seqIdPrefixes//g;
	$alias{$_} = "$locusTagPrefixes\_$seqid{$_}G$geneNumber";
	$aliasTranscript{$_} = "$locusTagPrefixes\_$seqid{$_}T$geneNumber";
}

open (FL,$input) or die("Can't open '$input': $!");
while (<FL>){
	chomp;
	if(/#/)
	{
		print FLS "$_\n";
		next;
	}
	if(/\S+;Name=([^;]+)/)
	{
		my $name = $1;
		s/Name=/Name=$name;Alias=/g;
	}

	my @line = split/\t/;
	if ($line[2] eq 'gene'){
		if ($line[8] =~ /ID=([^;]+);/)
		{
			my $id = $1;
			$line[8] =~ s/ID=$id/ID=$alias{$id}/g;
			$line[8] =~ s/Name=$id/Name=$alias{$id}/g;
		}
		else
		{
			next;
		}
	}
	elsif ($line[2] eq 'mRNA')
	{
		if ($line[8] =~ /ID=([^;]+)-mRNA/)
		{
			my $id = $1;
			$line[8] =~ s/ID=$id-mRNA-/ID=$aliasTranscript{$id}\./g;
			$line[8] =~ s/Name=$id-mRNA-/Name=$aliasTranscript{$id}\./g;
			$line[8] =~ s/Parent=$id/Parent=$alias{$id}/g;
		}
		else
		{
			next;
		}
	}
	else
	{
		if ($line[8] =~ /ID=([^;]+)-mRNA/)
		{
			my $id = $1;
			$line[8] =~ s/$id-mRNA-/$aliasTranscript{$id}\./g;
		}
		else
		{
			next;
		}
	}
	print FLS "$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\n";
}
close (FL);
close (FLS);

open (FLS,">$outfile.id.map") or die("Can't open '$outfile.id.map': $!");
open (FL,$outfile) or die("Can't open '$outfile': $!");
while (<FL>)
{
	chomp;
	/^#/ and next;
	my @line = split/\t/;
	if ($line[8] =~ /ID=([^;]+);.*;Alias=([^;]+)/)
	{
		print FLS "$2\t$1\n";
	}
}
close (FL);

