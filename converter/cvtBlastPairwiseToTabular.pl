#!/usr/local/bin/perl -w
use strict;
use Getopt::Long;
use Pod::Usage;
use Bio::SearchIO; 

my $man = '';
my $help = '';
my $input = '';
my $output = '';
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'output=s' => \$output,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output);
open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
print OUTPUT "#result->query_name",
			"\t",
      		"result->query_accession",
      		"\t",
      		"result->query_length",
      		"\t",
      		"result->query_description",
     		"\t",
     		"hit->name",
     		"\t",
     		"hit->length",
     		"\t",
     		"hit->accession",
     		"\t",
     		"hit->description",
     		"\t",
     		"hit->raw_score",
     		"\t",
     		"hit->significance",
     		"\t",
     		"hit->bits",
     		"\t",
     		"hsp->length('hit')",
     		"\t",
     		"hsp->length('total')",
     		"\t",
     		"hsp->frac_identical",
     		"\t",
     		"hsp->frac_conserved",
     		"\t",
     		"hsp->score",
     		"\t",
     		"hsp->start('query')",
     		"\t",
     		"hsp->end('query')",
     		"\t",
     		"hsp->start('hit')",
     		"\t",
     		"hsp->end('hit')",
     		"\t",
     		"hsp->percent_identity",
     		"\t",
     		"hsp->evalue",
     		"\n";

my $in = new Bio::SearchIO(-format => 'blast', 
                           -file   => $input);
while( my $result = $in->next_result ) {
  ## $result is a Bio::Search::Result::ResultI compliant object
  while( my $hit = $result->next_hit ) {
    ## $hit is a Bio::Search::Hit::HitI compliant object
    while( my $hsp = $hit->next_hsp ) {
      ## $hsp is a Bio::Search::HSP::HSPI compliant object
      print OUTPUT $result->query_name,
      				"\t",
      				$result->query_accession,
      				"\t",
      				$result->query_length,
      				"\t",
      				$result->query_description,
      				"\t",
      				$hit->name,
      				"\t",
      				$hit->length,
      				"\t",
      				$hit->accession,
      				"\t",
      				$hit->description,
      				"\t",
      				$hit->raw_score,
      				"\t",
      				$hit->significance,
      				"\t",
      				$hit->bits,
      				"\t",
      				$hsp->length('hit'),
      				"\t",
      				$hsp->length('total'),
      				"\t",
      				$hsp->frac_identical,
      				"\t",
      				$hsp->frac_conserved,
      				"\t",
      				$hsp->score,
      				"\t",
      				$hsp->start('query'),
      				"\t",
      				$hsp->end('query'),
      				"\t",
      				$hsp->start('hit'),
      				"\t",
      				$hsp->end('hit'),
      				"\t",
      				$hsp->percent_identity,
      				"\t",
      				$hsp->evalue,
      				"\n";
    }  
  }
}
close (OUTPUT);
exit; 

__END__

=head1 NAME

cvtBlastPairwiseToTabular.pl - Conver BLAST pairwise format  to tabular format

=head1 SYNOPSIS

cvtBlastPairwiseToTabular.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file (pairwise)
   -output          output file (tabular)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Name of input file in blast pairwise format.

=item B<-output>

Name of output file in tabular format.

=back

=head1 DESCRIPTION

B<cvtBlastPairwiseToTabular> will convert data in pairwise format to tabular.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

none.

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
