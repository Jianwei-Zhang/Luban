#!/usr/local/bin/perl -w
use Getopt::Long;
use Pod::Usage;

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
print OUTPUT "##gff-version 3\n";
open (INPUT,"$input") or die "can't open input File: $!";
while(<INPUT>)
{
	1 .. /score/ and next;
	/^\s*$/ and next;
	s/^\s*//g;
	@line=split(/\s+/,$_);
	if($line[8] eq "C")
	{
		$line[8]="-";
	}
	print OUTPUT $line[4],"\tRepeatMasker","\t",$line[10],"\t",$line[5],"\t",$line[6],"\t.\t",$line[8],"\t.\t.\t",$line[9],"\n";
}
close (INPUT);
close (OUTPUT);
__END__

=head1 NAME

repeatmasker2gff.pl - Converting RepeatMasker output to gff3 format

=head1 SYNOPSIS

repeatmasker2gff.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -output          output file

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a RepeatMasker output file.

=item B<-output>

Output data to a file.

=back

=head1 DESCRIPTION

B<repeatmasker2gff> will convert RepeatMasker result to gff3 format.

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
