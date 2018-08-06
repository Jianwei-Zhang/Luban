use GD;
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $output = '';
my $reflength = '';
my $showvalue = 1;
my $showconfidence = 1;

my $imagewidth = 5000;
my $headheight=100;
my $barheight=25;
my $chartheight=300;
my $spaceheight=30;
my $bottomheight=100;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'output=s' => \$output,
			'reflength=s' => \$reflength,
			'imagewidth=i' => \$imagewidth,
			'value!' => \$showvalue,
			'confidence!' => \$showconfidence,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output && $reflength);

#read refseq_length
my $norefname="NOREFNAME";
my %lengthdetail;
open INPUT2,"<$reflength" or die "$!";
while (<INPUT2>) {
	chop;
	/^#/ and next;
	$_ =~ s/\s*$//g;
	@line = split (/\t/,$_);
	if($line[0] =~ /:/)
	{
		$lengthdetail{$`}{$'}=$line[1];
	}
	else
	{
		$lengthdetail{$norefname}{$line[0]}=$line[1];
	}
}
close INPUT2;

#read bin data
my %bin=();
my $nolane="NOLANE";
my %referenceorder=();
my $referenceorder=0;
my $maxcount=-99999999;
my $mincount=99999999;
my @numberlist=(1 .. 99); #for non numberic data line
my %assignnumber=();
my $max=1;
open INPUT,"<$input" or die "$!";
while (<INPUT>) {
	chop;
	/^#/ and next;
	$_ =~ s/\s*$//g;
	@line = split(/\t/,$_);
	$line[4]=$norefname if (!$line[4]);
	#if the bin value is not a number, then the script will assign one
	$confidencemark="";
	if($line[3] =~ /\*+$/) # confidence mark
	{
		$line[3]= $`;
		$confidencemark=$&;
	}
	if($line[3] !~ /^[+-]?([1-9]\d*|0)(\.\d+)?([eE][+-]?(\d+)(\.\d+)?)?$/) #determine number or not
	{
		if(!exists $assignnumber{$line[3]})
		{
			$assignnumber{$line[3]}=shift @numberlist;
			$line[3]=$assignnumber{$line[3]};
		}
	}
	if($line[0] =~ /:/)
	{
		$line[2]=$lengthdetail{$line[4]}{$'} if ($line[2] > $lengthdetail{$line[4]}{$'});
		$bin{$`}{$'}{$line[1]}{$line[2]}{$line[4]}=$line[3];
		$confidencemark{$`}{$'}{$line[1]}{$line[2]}{$line[4]}=$confidencemark if $confidencemark;
	}
	else
	{   $line[0]= $line[4].":".$line[0];
		$line[2]=$lengthdetail{$line[4]}{$line[0]} if ($line[2] > $lengthdetail{$line[4]}{$line[0]});
		$bin{$line[4]}{$line[0]}{$line[1]}{$line[2]}{$line[4]}=$line[3];
		$confidencemark{$nolane}{$line[0]}{$line[1]}{$line[2]}{$line[4]}=$confidencemark if $confidencemark;
	}
	$maxcount = $line[3] if($maxcount < $line[3]);
	$mincount = $line[3] if($mincount > $line[3]);
	if(!exists $referenceorder{$line[4]})
	{
		$referenceorder{$line[4]}=$referenceorder;
		$referenceorder++;
	}
}
$max=abs($maxcount) if(abs($maxcount)>abs($mincount));
$max=abs($mincount) if(abs($maxcount)<abs($mincount));
$max=abs($mincount) if(abs($maxcount)==abs($mincount));


close INPUT;


if($output =~ /\.png$/i)
{
	open OUTPUT, ">$output";
}
else
{
	open OUTPUT, ">$output.png";
}
#get total bars to be be drawn
my $totalbars=0;
foreach $lane (keys %bin)
{
	foreach (keys %{$bin{$lane}})
	{
		$totalbars++;
	}
}

my $imageheight=($barheight+$chartheight+$spaceheight)*$totalbars + $headheight + $bottomheight;

my $im = new GD::Image($imagewidth,$imageheight); 
my $white = $im->colorAllocate(255,255,255); 
my $black = $im->colorAllocate(0,0,0); 
my $red = $im->colorAllocate(255,0,0);
my $blue = $im->colorAllocate(0,0,255);
my $green = $im->colorAllocate(0,255,0);
my $hetero = $im->colorAllocate(255,255,0);
my $background=$im->colorAllocate(200,200,200);
$im->transparent($white);
$im->interlaced('true');
#$im->alphaBlending(1);

## /--head region start--/
	#draw color samples
	if($barheight > 0)
	{
		
		
			$startpoint=9 * length($mincount);
			$im->string(gdGiantFont,1,1,$mincount,$black);
		
		
		for ($i=0;$i<256;$i++)
		{
			$color[$i] = $im->colorAllocate($i,255-$i,255-$i); #if use truecolor, $im->colorAllocateAlpha($i,255-$i,255-$i,0); The alpha value may range from 0 (opaque) to 127 (transparent).;
			$im->line($startpoint+$i,0,$startpoint+$i,$barheight,$color[$i]);
		}
		$im->string(gdGiantFont,$startpoint+$i+1,1,$maxcount,$black);
		if(keys %assignnumber)
		{
			#if the bin value is not a number, then the script will assign one
			$j=0;
			$stringlength=0;
			foreach (sort keys %assignnumber)
			{
				$colorindex=int ($assignnumber{$_}*255/$maxcount);
				$im->filledRectangle($startpoint+255+$j*$barheight+$stringlength+5+9 * length($mincount),0,$startpoint+255+($j+1)*$barheight+$stringlength+9 * length($mincount),$barheight,$color[$colorindex]);
				$im->string(gdGiantFont,$startpoint+255+($j+1)*$barheight+$stringlength+1+9 * length($mincount),1,$_,$black);
				$stringlength += 9 * length($_);
				$j++;
			}
		}
		#else
		###}
	}
	
	
	#draw coordinator
	$im->filledRectangle(0,20+$barheight,$imagewidth,30+$barheight,$black);
	for (1..50){
		$im->line($_*$imagewidth/50,5+$barheight,$_*$imagewidth/50,20+$barheight,$black);
	}
	for (1..9){
		my $scale_temp=$_*5;
		my $scale=$scale_temp." Mb";
		my $scalelength=length $scale;
		$im->string(gdGiantFont,$_*$imagewidth/10-7*$scalelength/2,35+$barheight,$scale,$black);
	}
## /--head region end--/

## /--data region start--/
my $seqnumber= 0;
my $charttop;
my $chartbottom;
my $chartcentral;
my %chartdrawn;
my %bardrawn;
my $barbottom;
$charttop=$headheight;

foreach $lane (sort keys %bin)
{
	foreach $chr (sort keys %{$bin{$lane}})
	{
		foreach $binstart (sort {$a <=> $b} keys %{$bin{$lane}{$chr}})
		{
			foreach $binend (sort {$b <=> $a} keys %{$bin{$lane}{$chr}{$binstart}})
			{
				foreach $referencename (keys %{$bin{$lane}{$chr}{$binstart}{$binend}})
				{
					$colorindex=int (($bin{$lane}{$chr}{$binstart}{$binend}{$referencename}-$mincount)*255/($maxcount-$mincount));
					if($chartheight > 0)
					{
						
						
							
							if (!exists $chartdrawn{$referencename}{$chr})
							{   
							    $charttop=$seqnumber*($chartheight+$barheight+$spaceheight)+$headheight;
							    $chartcentral=$charttop+$chartheight/2;
							    $chartbottom=$charttop+$chartheight;
								
								#vertical line
								$im->line(0,$charttop,0,$chartbottom,$black);
								#top mark
								$im->line(0,$charttop,5,$charttop,$black);
								#$im->string(gdGiantFont,5,$charttop,$maxcount,$black);
								#central line
								$im->line(0,$chartcentral,$lengthdetail{$referencename}{$chr}*$imagewidth/50000000,$chartcentral,$background);
								#central mark
								$im->line(0,$chartcentral,5,$chartcentral,$black);
								#bottom mark
								$im->line(0,$chartbottom,5,$chartbottom,$black);
								$chartdrawn{$referencename}{$chr}=1;
							}
							#draw data
							if($mincount < 0 && $maxcount>0)
							{
								if($chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename} >= 0)
								{
									$im->filledRectangle($binstart*$imagewidth/50000000,$chartcentral-$chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename}/($max*2),$binend*$imagewidth/50000000,$chartcentral,$black);
									#draw confidence mark:
									if($showconfidence && exists $confidencemark{$lane}{$chr}{$binstart}{$binend}{$referencename})
									{
										$confidencemarknumber=0;
										foreach (split //,$confidencemark{$lane}{$chr}{$binstart}{$binend}{$referencename})
										{
											$im->string(gdTinyFont,$binstart*$imagewidth/50000000,$chartcentral-($confidencemarknumber+1)*8-$chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename}/($maxcount-$mincount),$_,$red);
											$confidencemarknumber++;
										}
									}
								}
								else
								{
									$im->filledRectangle($binstart*$imagewidth/50000000,$chartcentral,$binend*$imagewidth/50000000,$chartcentral-$chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename}/($max*2),$black);
									#draw confidence mark:
									if($showconfidence && exists $confidencemark{$lane}{$chr}{$binstart}{$binend}{$referencename})
									{
										$confidencemarknumber=0;
										foreach (split //,$confidencemark{$lane}{$chr}{$binstart}{$binend}{$referencename})
										{
											$im->string(gdTinyFont,$binstart*$imagewidth/50000000,$chartcentral+$confidencemarknumber*8-$chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename}/($maxcount-$mincount),$_,$red);
											$confidencemarknumber++;
										}
									}
								}
							}
							if($mincount > 0)
							{
								$im->filledRectangle($binstart*$imagewidth/50000000,$chartbottom-$chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename}/$maxcount,$binend*$imagewidth/50000000,$chartbottom,$black);
								#draw confidence mark:
								if($showconfidence && exists $confidencemark{$lane}{$chr}{$binstart}{$binend}{$referencename})
								{
									$confidencemarknumber=0;
									foreach (split //,$confidencemark{$lane}{$chr}{$binstart}{$binend}{$referencename})
									{
										$im->string(gdTinyFont,$binstart*$imagewidth/50000000,$chartbottom-($confidencemarknumber+1)*8-$chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename}/$maxcount,$_,$red);
										$confidencemarknumber++;
									}
								}
							}
							if($maxcount < 0)
							{
							$im->filledRectangle($binstart*$imagewidth/50000000,$chartbottom-$chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename}/$mincount,$binend*$imagewidth/50000000,$chartbottom,$black);
								#draw confidence mark:
								if($showconfidence && exists $confidencemark{$lane}{$chr}{$binstart}{$binend}{$referencename})
								{
									$confidencemarknumber=0;
									foreach (split //,$confidencemark{$lane}{$chr}{$binstart}{$binend}{$referencename})
									{
										$im->string(gdTinyFont,$binstart*$imagewidth/50000000,$chartbottom-($confidencemarknumber+1)*8-$chartheight*$bin{$lane}{$chr}{$binstart}{$binend}{$referencename}/$maxcount,$_,$red);
										$confidencemarknumber++;
									}
								}
							}
						}
					
					
					if($barheight > 0)
					{
						
						
							#draw background
							$bartop = $charttop+$chartheight;
							$barbottom=$bartop+$barheight-1;
							if (!exists $bardrawn{$referencename}{$chr})
							{  
								$im->filledRectangle(0,$bartop,$lengthdetail{$referencename}{$chr}*$imagewidth/50000000,$barbottom,$background);
								if($lane eq $nolane)
								{
									$im->string(gdGiantFont,$lengthdetail{$referencename}{$chr}*$imagewidth/50000000+5,$bartop,$referencename.":".$chr,$black);
								}
								else
								{
									$im->string(gdGiantFont,$lengthdetail{$referencename}{$chr}*$imagewidth/50000000+5,$bartop,$lane.":".$chr,$black);
								}
								$bardrawn{$referencename}{$chr}=1;
							}
							#draw data
							$im->filledRectangle($binstart*$imagewidth/50000000,$bartop,$binend*$imagewidth/50000000,$barbottom,$color[$colorindex]);
							if($showvalue)
							{
								$im->string(gdTinyFont,$binstart*$imagewidth/50000000,$bartop+1,$bin{$lane}{$chr}{$binstart}{$binend}{$referencename},$black);
							}
						
						
					}
				}
			}
		}
		$seqnumber++;
		
	}
}
## /--data region end--/

binmode OUTPUT; 
print OUTPUT $im->png; 
close OUTPUT;
exit; 

__END__
=head1 NAME
bin2png.pl - Drawing bin charts
=head1 SYNOPSIS
bin2png.pl [options]
 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -output          output file
   -reflength       reference length
   -imagewidth      image width
   -value           show value of each bin
   -confidence      show confidence mark
=head1 OPTIONS
=over 8
=item B<-help>
Print a brief help message and exits.
=item B<-man>
Prints the manual page and exits.
=item B<-input>
Input data from a file in Tab delimited text format. For example,
 #chr	bin_start	bin_end	bin_data	ref_name
 chr01	1	200000	4	IRGSP
 chr01	200001	400000	5	IRGSP
 ...
The bin data can be generated by binMaker.pl, etc.
=item B<-reflength>
sequence legnth file name. For example: (generated by seqLength.pl)
 #seqid	length
 IRGSP:chr01	43268879
 IRGSP:chr02	35930381
 ...
=item B<-output>
Output data to a file.
=item B<-imagewidth> (optional)
Set image width (int > 0), default is 5000 pixel.
=item B<-value> (optional)
Display value of each bin, default is true.
B<-novalue> will not display values.
=item B<-confidence> (optional)
Display confidence mark (asterisk) of each bin if exists, default is true.
B<-noconfidence> will not display confidence mark.
=back
=head1 DESCRIPTION
B<bin2png> will create PNG map from bin data.
=head1 AUTHOR 
Jianwei Zhang @ Arizona Genomics Institute
=head1 EMAIL
jzhang@cals.arizona.edu
=head1 BUGS
none.
=head1 SEE ALSO 
seqLength.pl binMaker.pl piBinMaker.pl tdBinMaker.pl thetaBinMaker.pl
=head1 COPYRIGHT 
This program is free software. You may copy or redistribute it under the same terms as Perl itself.
=cut