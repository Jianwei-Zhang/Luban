#!/usr/bin/perl -w
#
use strict;
use Bio::Tools::GFF;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';

my $refspiece="";
my $qryspiece="";
my $reference="";
my $query="";
my $output="";
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'refspiece=s' => \$refspiece,
			'qryspiece=s' => \$qryspiece,
			'reference=s' => \$reference,
			'query=s' => \$query,
			'output=s' => \$output,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($reference && $query && $output);
$refspiece = $reference if $refspiece eq "";
$qryspiece = $query if $qryspiece eq "";

## nucmer
system ("nucmer -p $output $reference $query");
system ("delta-filter -g -q -r $output.delta > $output.delfil");
system ("show-coords -c -H -I 80 -l -r -T $output.delfil > $output.delfil.coords");

open (MSAFILE, ">$output") or die "can't open $output: $!";
open (NUCFILE,"$output.delfil.coords") or die "can't open $output.delfil.coords: $!";
while(<NUCFILE>)
{
	chop;
	my @nucline=split(/\t/,$_);
	if($nucline[0] < $nucline[1])
	{
		print MSAFILE "$refspiece\t$nucline[11]\t$nucline[0]\t$nucline[1]\t+\t.\t";
	}
	else
	{
		print MSAFILE "$refspiece\t$nucline[11]\t$nucline[1]\t$nucline[0]\t-\t.\t";
	}
	if($nucline[2] < $nucline[3])
	{
		print MSAFILE "$qryspiece\t$nucline[12]\t$nucline[2]\t$nucline[3]\t+\t.\n";
	}
	else
	{
		print MSAFILE "$qryspiece\t$nucline[12]\t$nucline[3]\t$nucline[2]\t-\t.\n";
	}
}
close (NUCFILE);
close (MSAFILE);
system ("rm $output.delta");
system ("rm $output.delfil");
system ("rm $output.delfil.coords");
exit; 

__END__

=head1 NAME

nucmer2gbsyn.pl - run nucmer to get alignment for gbrowse_syn

=head1 SYNOPSIS

nucmer2gbsyn.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -refspiece       name of refrence spiece(optional)
   -qryspiece       name of query spiece(optional)
   -reference       reference sequence (fasta)
   -query           query sequence (fasta)
   -output          output file

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-refspiece>

name of refrence spiece(optional)

=item B<-qryspiece>

name of query spiece(optional)

=item B<-reference>

Name of reference sequence (fasta)

=item B<-query>

Name of query sequence (fasta)

=item B<-output>

Name of output file.

=back

=head1 DESCRIPTION

B<nucmer2gbsyn> will run nucmer to get alignment for gbrowse_syn

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
