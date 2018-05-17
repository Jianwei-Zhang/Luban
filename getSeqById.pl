#!/usr/local/bin/perl -w
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $informat = 'fasta';
my $idfile = '';
my $output = '';
my $outformat = 'fasta';
my $logfile = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'informat=s' => \$informat,
			'id=s' => \$idfile,
			'output=s' => \$output,
			'outformat=s' => \$outformat,
			'log=s' => \$logfile,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output && $idfile);

my %seqid=();
open (SEQID,"$idfile") or die "can't open seqid FILE: $!";
while(<SEQID>)
{
	chop;
	/^#/ and next;
	$_ =~ s/\s*$//g;
	if(!exists $seqid{$_})
	{
		$seqid{$_}=0;
	}
}
close (SEQID);

my $in = Bio::SeqIO->new(-file => $input,
						-format => $informat);
my $out = Bio::SeqIO->new(-file => ">$output",
                       -format => $outformat);
while ( my $seq = $in->next_seq() )
{
	if(exists $seqid{$seq->id()})
	{
		$out->write_seq($seq);
		$seqid{$seq->id()}++;
	}
}

if($logfile)
{
	open (LOGFILE,">$logfile") or die "can't open log FILE: $!";
	print LOGFILE "#seqid\tnumber_of_sequence\n";
	foreach (keys %seqid)
	{
		print LOGFILE $_."\t".$seqid{$_}."\n";
	}
	close (LOGFILE);
}
__END__

=head1 NAME

getSeqById.pl - Getting sequence by Ids

=head1 SYNOPSIS

getSeqById.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           sequence database
   -informat        input sequence format
   -id              id list file
   -output          output file
   -outformat       output sequence format
   -log             log file

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Sequence database file.

=item B<-informat> (optional)

Input sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=item B<-id>

id list file.

=item B<-output>

Output data to a file.

=item B<-outformat> (optional)

Output sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=item B<-log> (optional)

Create a log file.

=back

=head1 DESCRIPTION

B<getSeqById> will ...

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

n50Finder.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
