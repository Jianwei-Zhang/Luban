#!/usr/local/bin/perl -w
#
# randomFeatureInGff.pl
#
# This script draw a PNG figure from a gff file.
use strict;
use Bio::Tools::GFF;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $feature = 'gene';
my $sample = '';
my $window = 0;
my $output = '';
my $gffversion = 3;
my $replacement = 1;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'gffversion=s' => \$gffversion,
			'feature=s' => \$feature,
			'sample=i' => \$sample,
			'window=i' => \$window,
			'output=s' => \$output,
			'replacement!' => \$replacement,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $sample);

if($replacement)
{
	print "Simple random sampling with replacement.\n";
}
else
{
	print "Simple random sampling without replacement.\n";
}

$output=$input.".$feature".".gff" if(!$output);
$output .= ".gff" if($output !~ /\.gff$/ig);
my @featurelist;
my $gffin = Bio::Tools::GFF->new(-file=>"$input",-gff_version=>$gffversion);
while( my $nextfeature = $gffin->next_feature() )
{
	if ($nextfeature->primary_tag() eq $feature)
	{
		push @featurelist,$nextfeature ;
	}
}
my $gffout = Bio::Tools::GFF->new(-gff_version => $gffversion,
                                 -file => ">$output");
my $position;
for (my $i=0;$i<$sample;$i++)
{
	my $ramdomindex=rand @featurelist;
	my $check = 1;
	if(exists $position->{$featurelist[$ramdomindex]->seq_id()})
	{
		for(@{$position->{$featurelist[$ramdomindex]->seq_id()}})
		{
			if(abs($_ - $featurelist[$ramdomindex]->start()) < $window || abs($_ - $featurelist[$ramdomindex]->end()) < $window)
			{
				$check = 0;
				last;
			}
		}
	}
	if($check)
	{
		$gffout->write_feature($featurelist[$ramdomindex]);
		push @{$position->{$featurelist[$ramdomindex]->seq_id()}}, $featurelist[$ramdomindex]->start(), $featurelist[$ramdomindex]->end();
		if(! $replacement)
		{
			splice(@featurelist, $ramdomindex, 1);
		}
	}
	else
	{
		$i--;
	}
}

exit; 

__END__

=head1 NAME

randomFeatureInGff.pl - Pick up random Feature in GFF

=head1 SYNOPSIS

randomFeatureInGff.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file (.gff)
   -gffversion      GFF file version
   -sample          sample size
   -window          window size
   -feature         feature to be picked
   -output          output file (.gff)
   -replacement     sampling method

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Name of input file in GFF format.

=item B<-gffversion> (optional)

GFF file version (default is 3)

=item B<-sample>

Give a sample size (int > 0).

=item B<-window>

Give a window size (int > 0).

=item B<-feature> (optional)

Picked feature (default is "gene")

=item B<-output> (optional)

Name of output file in png format (default is input-file-name.png).

=item B<-replacement> (optional)

Default is sampling with replacement.

B<-noreplacement> is to sample without replacement.

=back

=head1 DESCRIPTION

B<randomFeatureInGff> will pick up feature randomly in gff.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS



=head1 SEE ALSO 



=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
