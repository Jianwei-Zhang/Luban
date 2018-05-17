#!/usr/local/bin/perl -w
#
#Author: Jianwei Zhang
#
#purpose: add a prefix to seq title according to given file
print "Please type seqid order file:";
chop($infile = <STDIN>);

print "Please type seq file:";
chop($seqfile = <STDIN>);

print "Please type output seq file:";
chop($outseqfile = <STDIN>);


open (IFILE,"$infile") or die "can't open $infile: $!";
while(<IFILE>)
{
	chop;
	@seqprefixline=split("\t",$_);
  $seqprefix{$seqprefixline[0]}=$seqprefixline[1];
}
close (IFILE);

open (OUTPUT,">$outseqfile") or die "can't open $outseqfile: $!";

open (SEQFILE,"$seqfile") or die "can't open $seqfile: $!";
while(<SEQFILE>)
{
	chop;
	if(/>(.*)/)
	{
    print OUTPUT ">";
    @seqtitle=split(" ",$1);
    if(exists $seqprefix{$seqtitle[0]})
    {
     print OUTPUT $seqprefix{$seqtitle[0]};
    }
    else
    {
     print "no $seqtitle[0] ($1) prefix info was added.";
    }
    print OUTPUT $1;
    print OUTPUT "\n";
  }
  else
  {
    print OUTPUT $_;
    print OUTPUT "\n";
  }
}
close (SEQFILE);
close (OUTPUT);
