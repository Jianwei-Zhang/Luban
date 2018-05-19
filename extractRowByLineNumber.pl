#!/usr/local/bin/perl -w
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $lines = '';
my $output = '';
my $head = 1;
my $duplicate = 1;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'lines=s' => \$lines,
			'output=s' => \$output,
			'head!' => \$head,
			'duplicate!' => \$duplicate,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output && $lines);

#prepare rows to be extracted
%rowsToBeExtracted=();
open (INPUT,"$lines") or die "can't open input file: $!";
while(<INPUT>)
{
	chop;
	if(exists $rowsToBeExtracted{$_})
	{
		$rowsToBeExtracted{$_}++;
	}
	else
	{
		$rowsToBeExtracted{$_}=1;
	}
}
close (INPUT);

$linenumber=1;
open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
open (INPUT,"$input") or die "can't open input file: $!";
while(<INPUT>)
{
	chop;
	if($head)
	{
		$head=0;
		print OUTPUT $_."\n";
		next;
	}
	if(exists $rowsToBeExtracted{$linenumber})
	{
		if($duplicate)
		{
			for ($i=0;$i<$rowsToBeExtracted{$linenumber};$i++)
			{
				print OUTPUT $_."\n";
			}
		}
		else
		{
			print OUTPUT $_."\n";
		}
	}
	$linenumber++;
}
close (INPUT);
close (OUTPUT);
__END__

=head1 NAME

extractRowByLineNumber.pl - Extracting rows from list by line numbers

=head1 SYNOPSIS

extractRowByLineNumber.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -lines           line numbers file
   -output          output file
   -head            head line
   -duplicate       output duplicates

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a text file.

=item B<-lines>

line numbers list file.

=item B<-output>

Output data to a file.

=item B<-head> (optional)

defaut is with head line in the input file.

B<-nohead> will set the input file without head line.

=item B<-duplicate> (optional)

If the same number appears twice or more, the output will be also appear twice or more. 

B<-noduplicate> for not outputting more than once.

=back

=head1 DESCRIPTION

B<extractRowByLineNumber> will ...

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

randomNumbers.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
