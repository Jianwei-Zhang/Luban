#!/usr/local/bin/perl -w
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $output = '';
my $collist = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'output=s' => \$output,
			'collist=s' => \$collist,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output && $collist);

#prepare columns to be removed

@collist=();
foreach (split (/,/,$collist))
{
	if(/-/)
	{
		for($i=$`;$i<=$';$i++)
		{
			push @collist,$i;
		}
	}
	else
	{
		push @collist,$_;
	}
}

@collist=sort { $a <=> $b } uniq(@collist);


open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
open (INPUT,"$input") or die "can't open input file: $!";
while(<INPUT>)
{
	chop;
	@inline=split(/\t/,$_);
	$i=0;
	foreach (@collist)
	{
		splice(@inline, $_-1-$i, 1);
		$i++;
	}
	print OUTPUT join ("\t",@inline)."\n";
}
close (INPUT);
close (OUTPUT);

sub uniq { 
    return keys %{{ map { $_ => 1 } @_ }}; 
#       my %hash = map { $_, 1 } @array;
# or a hash slice: @hash{ @array } = ();
# or a foreach: $hash{$_} = 1 foreach ( @array );
#       my @unique = keys %hash;
} 
__END__

=head1 NAME

rmCol.pl - Removing columns from a table

=head1 SYNOPSIS

rmCol.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -output          output file
   -collist         column list

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a file in Tab delimited text format.

=item B<-output>

Output data to a file.

=item B<-collist>

Columns list to be removed. For example,

 "-collist 1" means "remove 1st column".
 "-collist 2-4" means "remove 2nd to 4th columns".
 "-collist 1,3-5" means "remove 1st,and 3rd to 5th columns".

Multiple removals must be saperated by "Comma[,]", no blank-spaces allowed.

=back

=head1 DESCRIPTION

B<rmCol> will remove columns from table by given column number.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

addCol.pl row2col.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
