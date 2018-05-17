#!/usr/bin/perl
#ssr.pl
#Jianwei Zhang, 10/2017 modified based on S.Cartinhour. 5/2000
#ftp://ftp.gramene.org/pub/gramene/archives/software/scripts/ssr.pl

#Search for simple sequence repeats in 
#FASTA-formatted DNA sequences. Each FASTA record
#looks like this (the record delimiter is ">"):

use strict;
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;

my $params = join ' ', @ARGV;
my $man = '';
my $help = '';
my $input = '';
my $format = 'fasta';
my $output = '';
my $log = '';
my $progress = 0;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'format=s' => \$format,
			'output=s' => \$output,
			'log=s' => \$log,
			'progress=i' => \$progress,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output);

$log = "$output.log" if (!$log);
unlink ("$log"); # delete old log file
&writeLog("$0 $params");
&writeLog("Start job with process id: $$");

#motif-repeat parameters:
#specify motif length, minimum number of repeats.
#modify according to researcher's preferences
my @specs = ([2,9],  #dinucl. with >= 9 repeats
	     [3,6],  #trinucl. with >= 6 repeats
	     [4,5], #tetranucl. with >= 5 repeats
	     [5,4],
	     [6,3],
	     [7,3]);

my $seqcount = 0;
open (OUTPUT, ">$output");
print OUTPUT "#id\tssr_number\tmotiflength\tmotif\trepeats\tstart\tend\tseqlength\n";
my $in = Bio::SeqIO->new(-file => $input,
			-format => $format);
while ( my $seq = $in->next_seq() )
{
    $seqcount++;
    my $id = $seq->id();
    my $sequence = $seq->seq;
    my $seqlength = $seq->length();
    my $ssr_number = 1;   #track multiple ssrs within a single sequence
    my %locations;        #track location of SSRs as detected
	for(my $i=0; $i<scalar(@specs); $i++){ #test each spec against sequence
		my $motiflength = $specs[$i]->[0];
		my $minreps = $specs[$i]->[1] - 1;
		my $regexp = "(([gatc]{$motiflength})\\2{$minreps,})";
		while ($sequence =~ /$regexp/ig){
			my $motif = lc($2);
			my $ssr = $1;
			#reject "aaaaaaaaa", "ggggggggggg", etc.
			next if &homopolymer($motif,$motiflength); #comment out this line to report monomers
			my $ssrlength = length($ssr);          #overall SSR length
			my $repeats = $ssrlength/$motiflength; #number of rep units
			my $end = pos($sequence);              #where SSR ends
			pos($sequence) = $end - $motiflength;  #see docs
			my $start = $end - $ssrlength + 1;     #where SSR starts
			print OUTPUT join("\t", $id, $ssr_number++,
					  $motiflength, $motif, $repeats, 
					  $start, $end, $seqlength), "\n"
			if (&novel($start, \%locations));  #count SSR only once
		}
	}
	&writeLog("Search in $seqcount sequences") if ($seqcount % 100 == 0);
}
close OUTPUT;
&writeLog("Search in $seqcount sequences");
&writeLog("End job");

exit 0;
###sub processes
sub homopolymer {
    #return true if motif is repeat of single nucleotide
    my ($motif,$motiflength) = @_;
    my ($reps) = $motiflength - 1;
    return 1 if ($motif =~ /([gatc])\1{$reps}/);
    return 0;
}

sub novel {
    my($position, $locationsref) = @_;
    if(defined $locationsref->{$position}) {
       return undef;
   } else {
       $locationsref->{$position} = 1;
       return 1;
   }
}

# write messages to log file
sub writeLog
{
	my $message = shift;
	my $timeStamp = scalar localtime(time());
	print "$timeStamp: $message\n" if ($progress);
	open (FILE, ">>$log");
	print FILE "$timeStamp: $message\n";
	close FILE;
}
       

__END__

=head1 NAME

ssr.pl - SSR finder

=head1 SYNOPSIS

ssr.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -format          input sequence format
   -output          output file
   -log             log file
   -progress        show progress during run

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a fasta file.

=item B<-format> (optional)

Input sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=item B<-output>

Output data to a file.

=item B<-log> (optional)

Log file name. (default with output file name)

=item B<-progress> (optional)

Show progress during run. (0 for no, 1 for yes; default 0)

=back

=head1 DESCRIPTION

B<ssr.pl> will search for simple sequence repeats in FASTA-formatted DNA sequences.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 



=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
