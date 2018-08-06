#!/usr/local/bin/perl -w
#
# gff2png.pl
#
# This script draw a PNG figure from a gff file.
use strict;
use GD;
use GD::Text::Wrap;
use Bio::Tools::GFF;
use Getopt::Long;
use Pod::Usage;
use Cwd 'abs_path';

my $man = '';
my $help = '';
my $colorlist = '';
my $input = '';
my $ignore = '';
my $output = '';
my $gffversion = 3;
my $imagewidth = 2000;
my $imageheader = 50;
my $rightmargin = 0;
my $bgcolor = 'white';
my $transparentcolor = 'white'; # this is a fixed variable, don't change it.
my $tracksize = 50;
my $trackstart = 0;
my $trackend =0;
my $featurecolor = '';
my $featuresize = 6;
my $smallfeaturestyle = 1;
my $featurename = 1;
my $featurenamecolor = 'black';
my $seqidcolor = 'black';
my $barheight = 10;
my $barcolor = 'black';
my $synteny = '';
my $syntenycolor = 'blue';
my $homology = '';
my $homologycolor = 'green';
my $colorfile = '';
my $programPath = abs_path($0); #get programPath
$programPath =~ m/(.+)[\/\\](.+)$/;
#$fullPath = $1;
#$fileName = $2;
my $fontspath = $1.'/fonts';
my $rulercolor = 'gray';
my $rulergridlinecolor = 'gray';
my $mainrulergridlinecolor = 'green';
my $gridlinecolor = 'silver';
my $maingridlinecolor = 'yellow';
my $graduationsize = 10;
my $graduationcolor = 'red';

my %rgb;
#pre-defined colors (http://en.wikipedia.org/wiki/Web_colors)
@{$rgb{'white'}}=(255,255,255);
@{$rgb{'black'}}=(0,0,0);
@{$rgb{'red'}}=(255,0,0);
@{$rgb{'lime'}}=(0,255,0);
@{$rgb{'green'}}=(0,128,0);
@{$rgb{'blue'}}=(0,0,255);
@{$rgb{'gray'}}=(128,128,128);
@{$rgb{'silver'}}=(192,192,192);
@{$rgb{'maroon'}}=(128,0,0);
@{$rgb{'yellow'}}=(255,255,0);
@{$rgb{'olive'}}=(128,128,0);
@{$rgb{'aqua'}}=(0,255,255);
@{$rgb{'teal'}}=(0,128,128);
@{$rgb{'navy'}}=(0,0,128);
@{$rgb{'fuchsia'}}=(255,0,255);
@{$rgb{'purple'}}=(128,0,128);

my %availablergb;
&readcolor("$fontspath/rgb.txt") if (-e "$fontspath/rgb.txt");

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'colorlist' => \$colorlist,
			'input=s' => \$input,
			'gffversion=s' => \$gffversion,
			'ignore=s' => \$ignore,
			'imagewidth=i' => \$imagewidth,
			'imageheader=i' => \$imageheader,
			'rightmargin=i' => \$rightmargin,
			'bgcolor=s' => \$bgcolor,
			'tracksize=i' => \$tracksize,
			'trackstart=i' => \$trackstart,
			'trackend=i' => \$trackend,
			'featurecolor=s' => \$featurecolor,
			'featuresize=i' => \$featuresize,
			'smallfeaturestyle=i' => \$smallfeaturestyle,
			'featurename!' => \$featurename,
			'featurenamecolor=s' => \$featurenamecolor,
			'seqidcolor=s' => \$seqidcolor,
			'barheight=i' => \$barheight,
			'barcolor=s' => \$barcolor,
			'synteny=s' => \$synteny,
			'syntenycolor=s' => \$syntenycolor,
			'homology=s' => \$homology,
			'homologycolor=s' => \$homologycolor,
			'rulercolor=s' => \$rulercolor,
			'gridlinecolor=s' => \$gridlinecolor,
			'maingridlinecolor=s' => \$maingridlinecolor,
			'graduationcolor=s' => \$graduationcolor,
			'colorfile=s' => \$colorfile,
			'output=s' => \$output,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
#read customized color file
&readcolor("$colorfile") if(-e "$colorfile" && $colorfile);
if($colorlist)
{
	print "Available colors:\n". join ("\, ", (sort keys %availablergb)) .".\n\n" if (keys %availablergb);
	print "Basic colors:\n". join ("\, ", (sort keys %rgb)) .".\n";
	exit;
}
pod2usage(1) unless ($input);

$imagewidth=500 if($imagewidth < 500);
$imageheader=30 if($imageheader < 30);
$rightmargin=0 if($rightmargin < 0);
$tracksize=5 if($tracksize < 5);
$barheight =10 if($barheight<10);
$featuresize=2 if($featuresize < 2);
$featurename=0 if($featuresize < 6);

$output=$input.".png" if(!$output);
$output .= ".png" if($output !~ /\.png$/ig);

my %featurecolor;
if($featurecolor)
{
	for (split (/\s*\,\s*/,$featurecolor))
	{
		my($trackname,$colorname)=split(/\s*:\s*/,$_);
		$colorname=lc($colorname);
		$featurecolor{$trackname}=$colorname if (exists $rgb{$colorname} || exists $availablergb{$colorname});
		@{$rgb{$colorname}} = @{$availablergb{$colorname}} if (!exists $rgb{$colorname} && exists $availablergb{$colorname});
		print "Warning: color \"$colorname\" is not defined yet. Please check the available color name. Anyway, system will assign one for \"$trackname\" from the available color list.\n" if (!exists $rgb{$colorname} && !exists $availablergb{$colorname});
	}
}
$bgcolor = &checkcolor($bgcolor,'white');
$featurenamecolor = &checkcolor($featurenamecolor,'black');
$barcolor = &checkcolor($barcolor,'black');
$seqidcolor = &checkcolor($seqidcolor,'black');
$syntenycolor = &checkcolor($syntenycolor,'blue');
$homologycolor = &checkcolor($homologycolor,'green');
$rulercolor = &checkcolor($rulercolor,'gray');
$rulergridlinecolor = &checkcolor($rulergridlinecolor,'gray');
$mainrulergridlinecolor = &checkcolor($mainrulergridlinecolor,'black');
$gridlinecolor = &checkcolor($gridlinecolor,'silver');
$maingridlinecolor = &checkcolor($maingridlinecolor,'black');
$graduationcolor = &checkcolor($graduationcolor,'black');

#non white colors
my @nonbgcolors;
for(sort keys %rgb)
{
	push @nonbgcolors, $_ if ($_ ne $bgcolor);
}

my %ignore;
if($ignore)
{
	for (split (/\s*\,\s*/,$ignore))
	{
		$ignore{$_}=1;
	}
}
my %seq;
my %seqlength;
my $maxseqlength=0;
my $maxseqidlength=0;
my %featurename;
my $featurenumber =0;
my %featurenumber;
my @featurenumber;
my $maxfeaturenumber=0;
my $gffin = Bio::Tools::GFF->new(-file=>"$input",-gff_version=>$gffversion);

while( my $feature = $gffin->next_feature() )
{
	if($feature->end() > $maxseqlength)
	{
		$maxseqlength = $feature->end();
	}
	$seqlength{$feature->seq_id()} = $feature->end() if(!exists $seqlength{$feature->seq_id()});
	if($feature->end() > $seqlength{$feature->seq_id()})
	{
		$seqlength{$feature->seq_id()} = $feature->end();
	}
	if(length ($feature->seq_id()) > $maxseqidlength)
	{
		$maxseqidlength = length ($feature->seq_id());
	}
	$featurecolor{$feature->primary_tag()} = shift @nonbgcolors if (!exists $featurecolor{$feature->primary_tag()}); # this will let me know how many trackes to be drawn.
	my $id='';
	my $parent='';
	my $hasparent='';
	if($feature->has_tag('ID'))
	{
		my @id = $feature->get_tag_values('ID'); 
		$id=$id[0];
		if(exists $featurename{$id[0]})
		{
			print "Error: duplicate id detected. Please check you gff file.\n";
			exit;
		}
		if ($feature->has_tag('Name'))
		{
			my @featurename = $feature->get_tag_values('Name');
			$featurename{$id[0]}=$featurename[0];
		}
		else
		{
			$featurename{$id[0]}=$id[0];
		}
	}
	if($feature->has_tag('Parent'))
	{
		my @parent = $feature->get_tag_values('Parent'); 
		$hasparent=1;
		$parent=join ":Parent:", @parent;
	}
	push @{$seq{$feature->seq_id()}},$feature->source_tag()."\t".$feature->primary_tag()."\t".$feature->start()."\t".$feature->end()."\t".$feature->strand()."\t".$feature->frame()."\t".$id."\t".$hasparent."\t".$parent;
	
    
	
}

$trackend = $maxseqlength if($trackend == 0);
if($trackstart > $trackend)
{
	print "Error: trackstart must be smaller than trackend.\n";
	exit;
}


my $unitseqheight=$tracksize*2+$barheight;
my $imageheight=$imageheader+(keys %seq)*$unitseqheight;


# create background layout
my $bglayer = new GD::Image($imagewidth,$imageheight);
my %bglayercolor;
for (keys %rgb)
{
	$bglayercolor{$_} = $bglayer->colorAllocate(@{$rgb{$_}});
}

# make the background transparent and interlaced
$bglayer->filledRectangle(0,0,$imagewidth-1,$imageheight-1,$bglayercolor{$bgcolor});
$bglayer->transparent($bglayercolor{$transparentcolor});
$bglayer->interlaced('true');

#draw coordinator/ruler
my $ruler = $trackend-$trackstart;
my $leftmargin = $barheight*$maxseqidlength;
$rightmargin = $leftmargin if ($rightmargin == 0);
my $unitlength=($imagewidth-1-$rightmargin-$leftmargin)/$ruler;
for (0..50){
	$bglayer->line($leftmargin+$_*($imagewidth-1-$rightmargin-$leftmargin)/50,$imageheader-10,$leftmargin+$_*($imagewidth-1-$rightmargin-$leftmargin)/50,$imageheader,$bglayercolor{$rulergridlinecolor});
	$bglayer->dashedLine($leftmargin+$_*($imagewidth-1-$rightmargin-$leftmargin)/50,$imageheader,$leftmargin+$_*($imagewidth-1-$rightmargin-$leftmargin)/50,$imageheight,$bglayercolor{$gridlinecolor});
}

my $rulerwrap = GD::Text::Wrap->new( $bglayer,
      line_space  => 0,
      color       => $bglayercolor{$graduationcolor},
      align       => 'center',
      width       => ($imagewidth-1-$rightmargin-$leftmargin)/10,
  );
$rulerwrap->font_path($fontspath);
$rulerwrap->set_font('arial', $graduationsize); #Arial

for (0..10){
	my $graduation=int ($_*$ruler/10) + $trackstart;
	$rulerwrap->set(text => $graduation);
	$rulerwrap->draw($leftmargin+($_-0.5)*($imagewidth-1-$rightmargin-$leftmargin)/10,$imageheader-30);
	$bglayer->line($leftmargin+$_*($imagewidth-1-$rightmargin-$leftmargin)/10,$imageheader-15,$leftmargin+$_*($imagewidth-1-$rightmargin-$leftmargin)/10,$imageheader,$bglayercolor{$mainrulergridlinecolor});
	$bglayer->dashedLine($leftmargin+$_*($imagewidth-1-$rightmargin-$leftmargin)/10,$imageheader,$leftmargin+$_*($imagewidth-1-$rightmargin-$leftmargin)/10,$imageheight,$bglayercolor{$maingridlinecolor});
}
$bglayer->filledRectangle($leftmargin,$imageheader-5,$imagewidth-1-$rightmargin,$imageheader,$bglayercolor{$rulercolor});

#draw legend
my $legendwrap = GD::Text::Wrap->new( $bglayer,
      line_space  => 0,
      align       => 'left',
      color       => $bglayercolor{$featurenamecolor},
  );
$legendwrap->font_path($fontspath);
$legendwrap->set_font('arial', $graduationsize); #Arial
my $lastlegendend=$leftmargin;
for(sort keys %featurecolor)
{
	next if (exists $ignore{$_});
	$bglayer->filledRectangle($lastlegendend,0,$lastlegendend+$graduationsize,$graduationsize,$bglayercolor{$featurecolor{$_}});
	$legendwrap->set(text => $_);
	$legendwrap->draw($lastlegendend+$graduationsize+1,0);
	$lastlegendend =$lastlegendend+$graduationsize*(length($_)+1);
}


# create main layer image
my $mainlayer = new GD::Image($imagewidth,$imageheight);
my %mainlayercolor;
for (keys %rgb)
{
	$mainlayercolor{$_} = $mainlayer->colorAllocate(@{$rgb{$_}});
}

# make the background transparent and interlaced
$mainlayer->filledRectangle(0,0,$imagewidth-1,$imageheight-1,$mainlayercolor{$transparentcolor});
$mainlayer->transparent($mainlayercolor{$transparentcolor});
$mainlayer->interlaced('true');

my %seqnumber;
my %seqname;
my %level;
my %strand;
my %occupationleft;
my %occupationright;
my $seqnumber=0;

my $seqidwrap = GD::Text::Wrap->new( $mainlayer,
      line_space  => 0,
      color       => $mainlayercolor{$seqidcolor},
      align       => 'right',
      width       => $leftmargin,
  );
$seqidwrap->font_path($fontspath);
$seqidwrap->set_font('arial', $barheight); #Arial, 1X bar height font size

my $featurenamewrap = GD::Text::Wrap->new( $mainlayer,
      line_space  => 0,
      color       => $mainlayercolor{$featurenamecolor},
      align       => 'left',
  );
$featurenamewrap->font_path($fontspath);
$featurenamewrap->set_font('OCRAEXT', $featuresize-6); #1X feature height font size

#available fonts (FIXED WIDTH)
#LucidaTypewriterBold
#LucidaTypewriterBoldOblique
#LucidaTypewriterOblique
#LucidaTypewriterRegular
#OCRAEXT
#consola
#consolab
#consolai
#consolaz
#cour
#lucon
#simkai                                                                                                          
#simsunb

for ( map { $_->[0] } sort { $a->[1] <=> $b->[1] || $a->[2] cmp $b->[2]} map { [$_, /(\d+)/, uc($_)]} (keys %seq)) #seqid was sorted by numbers, then letters
{
	#print seq_id
	my $seqid = $_;
	$seqnumber{$seqid}=$seqnumber;
	$seqidwrap->set(text => $seqid);
	$seqidwrap->draw(0,$imageheader+$seqnumber*$unitseqheight+$tracksize);
	$seqlength{$_} = $trackend if ($seqlength{$_} > $trackend);
	$mainlayer->filledRectangle($leftmargin,$imageheader+$seqnumber*$unitseqheight+$tracksize,$leftmargin+($seqlength{$_}-$trackstart)*$unitlength,$imageheader+$seqnumber*$unitseqheight+$tracksize+$barheight,$mainlayercolor{$barcolor});
	
	#sort by the "source" "hasparent" "primary_tag" "start", see http://perldoc.perl.org/functions/sort.html
	@{$seq{$seqid}} = map { $_->[0] } sort { $a->[1] cmp $b->[1] ||  $a->[8] cmp $b->[8] || $a->[2] cmp $b->[2] || $a->[3] <=> $b->[3]} map { [$_, /(.*)\t(.*)\t(\d+)\t(\d+)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*)/] } @{$seq{$seqid}};

	my %occupationplus;
	my %occupationminus;
	for (@{$seq{$seqid}})
	{
		my @objectline=split(/\t/,$_);
		next if (exists	$ignore{$objectline[1]}); #ignore features
		next if ($objectline[2] > $trackend); #ignore start > track end
		next if ($objectline[3] < $trackstart); #ignore end < track start
		$seqname{$objectline[6]}=$seqid;
		$strand{$objectline[6]}=$objectline[4];
		my $objectstart=int ($leftmargin+($objectline[2]-$trackstart)*$unitlength);
		my $objectend=int ($leftmargin+($objectline[3]-$trackstart)*$unitlength);
		my $objectcenter=int ($leftmargin+($objectline[2]+$objectline[3]-2*$trackstart)*$unitlength/2);
		my $smallgene = 0;
		my $featurenamelength=0;
		$featurenamelength=length($featurename{$objectline[6]})*$featuresize*5/6 if(exists $featurename{$objectline[6]} && $featurename);
		if(abs ($objectstart-$objectend) <1)
		{
			my $halfbottom;
			if($smallfeaturestyle == 1)
			{
				if($featuresize/4 > 3)
				{
					$halfbottom=3;
				}
				else
				{
					$halfbottom=int ($featuresize/4);
				}
			}
			else
			{
				$halfbottom=$featuresize-1;
			}
			$halfbottom= 1 if($halfbottom < 1);
			$objectstart=$objectcenter-$halfbottom;
			$objectend=$objectcenter+$halfbottom;
			$smallgene = 1;
		}
		if($objectline[4] == 1) #plus strand
		{
			my $goodlevel=0;
			for (sort {$a <=> $b} keys %occupationplus)
			{
				my $currentlevel=$_;
				for(split ("\t",$occupationplus{$currentlevel}))
				{
					my ($occupationleft,$occupationright)=split ("-",$_);
					if((($occupationleft-1 <= $objectstart) && ($occupationright+1 >= $objectstart)) || (($occupationleft-1 <= $objectend+$featurenamelength) && ($occupationright+1 >= $objectend+$featurenamelength)) || (($occupationleft >= $objectstart) && ($occupationright <= $objectend+$featurenamelength)))#there is overlap
					{
						$goodlevel=$currentlevel+1;
						last;
					}
				}
				last if($goodlevel == $currentlevel);
			}
			$level{$objectline[6]}=$goodlevel;
			if($smallgene)
			{
				my $triangle = new GD::Polygon;
				$triangle->addPt($objectstart,$imageheader+$seqnumber*$unitseqheight+$tracksize-$goodlevel*($featuresize+1)-$featuresize);
				$triangle->addPt($objectend,$imageheader+$seqnumber*$unitseqheight+$tracksize-$goodlevel*($featuresize+1)-$featuresize);
				$triangle->addPt($objectcenter,$imageheader+$seqnumber*$unitseqheight+$tracksize-$goodlevel*($featuresize+1)-1);
				$mainlayer->filledPolygon($triangle,$mainlayercolor{$featurecolor{$objectline[1]}});
				$occupationleft{$objectline[6]} = $objectcenter;
				$occupationright{$objectline[6]} = $objectcenter;
			}
			else
			{
				$mainlayer->filledRectangle($objectstart,$imageheader+$seqnumber*$unitseqheight+$tracksize-$goodlevel*($featuresize+1)-$featuresize-1,$objectend,$imageheader+$seqnumber*$unitseqheight+$tracksize-$goodlevel*($featuresize+1)-2,$mainlayercolor{$featurecolor{$objectline[1]}});		
				$occupationleft{$objectline[6]} = $objectstart;
				$occupationright{$objectline[6]} = $objectend;
			}
			if($featurenamelength)
			{
				$featurenamewrap->set(text => $featurename{$objectline[6]});
				$featurenamewrap->draw($objectend,$imageheader+$seqnumber*$unitseqheight+$tracksize-$goodlevel*($featuresize+1)-$featuresize-6);
				$objectend += $featurenamelength;
			}
			$occupationplus{$goodlevel} .="$objectstart-$objectend\t";
		}
		else # minus strand
		{
			my $goodlevel=0;
			for (sort {$a <=> $b} keys %occupationminus)
			{
				my $currentlevel=$_;
				for(split ("\t",$occupationminus{$currentlevel}))
				{
					my ($occupationleft,$occupationright)=split ("-",$_);
					if((($occupationleft-1 <= $objectstart) && ($occupationright+1 >= $objectstart)) || (($occupationleft-1 <= $objectend+$featurenamelength) && ($occupationright+1 >= $objectend+$featurenamelength)) || (($occupationleft >= $objectstart)&& ($occupationright <= $objectend+$featurenamelength)))#there is overlap
					{
						$goodlevel=$currentlevel+1;
						last;
					}
				}
				if($goodlevel == $currentlevel)
				{
					last;
				}
			}
			$level{$objectline[6]}=$goodlevel;
			if($smallgene)
			{
				my $triangle = new GD::Polygon;
				$triangle->addPt($objectstart,$imageheader+$seqnumber*$unitseqheight+$tracksize+$barheight+$goodlevel*($featuresize+1)+$featuresize);
				$triangle->addPt($objectend,$imageheader+$seqnumber*$unitseqheight+$tracksize+$barheight+$goodlevel*($featuresize+1)+$featuresize);
				$triangle->addPt($objectcenter,$imageheader+$seqnumber*$unitseqheight+$tracksize+$barheight+$goodlevel*($featuresize+1)+1);
				$mainlayer->filledPolygon($triangle,$mainlayercolor{$featurecolor{$objectline[1]}});
				$occupationleft{$objectline[6]} = $objectcenter;
				$occupationright{$objectline[6]} = $objectcenter;
			}
			else
			{
				$mainlayer->filledRectangle($objectstart,$imageheader+$seqnumber*$unitseqheight+$tracksize+$barheight+$goodlevel*($featuresize+1),$objectend,$imageheader+$seqnumber*$unitseqheight+$tracksize+$barheight+$goodlevel*($featuresize+1)+$featuresize-1,$mainlayercolor{$featurecolor{$objectline[1]}});		
				$occupationleft{$objectline[6]} = $objectstart;
				$occupationright{$objectline[6]} = $objectend;
			}
			if($featurenamelength)
			{
				$featurenamewrap->set(text => $featurename{$objectline[6]});
				$featurenamewrap->draw($objectend,$imageheader+$seqnumber*$unitseqheight+$tracksize+$barheight+$goodlevel*($featuresize+1)-5);
				$objectend += $featurenamelength;
			}
			$occupationminus{$goodlevel} .="$objectstart-$objectend\t";
		}
	}
	$seqnumber++;
}

#draw synteny region
if(($synteny) && (-e $synteny))
{
	my $syntenyline=0;
	open(SYNTENY,"$synteny") or die "can't open synteny file: $synteny!";
	while(<SYNTENY>)
	{
		$syntenyline++;
		chomp;
		/^#/ and next;
		/^\s*$/ and next;
		my @syntenyaln=split(/\t/,$_);
		$syntenyaln[1] .="_".$syntenyaln[0] if($syntenyaln[0] ne "");
		$syntenyaln[7] .="_".$syntenyaln[6] if($syntenyaln[6] ne "");
		$syntenyaln[1] =~ s/^\s+//;
		$syntenyaln[1] =~ s/\s+$//;
		$syntenyaln[7] =~ s/^\s+//;
		$syntenyaln[7] =~ s/\s+$//;
		if(!exists $seqnumber{$syntenyaln[1]} || !exists $seqnumber{$syntenyaln[7]})
		{
			print "Warning: wrong synteny information detected. Please check you synteny file line $syntenyline.\n";
			next;
		}
		if($seqnumber{$syntenyaln[1]} > $seqnumber{$syntenyaln[7]})
		{
			($syntenyaln[1],$syntenyaln[7])=($syntenyaln[7],$syntenyaln[1]);
			($syntenyaln[2],$syntenyaln[8])=($syntenyaln[8],$syntenyaln[2]);
			($syntenyaln[3],$syntenyaln[9])=($syntenyaln[9],$syntenyaln[3]);
			($syntenyaln[4],$syntenyaln[10])=($syntenyaln[10],$syntenyaln[4]);
			($syntenyaln[5],$syntenyaln[11])=($syntenyaln[11],$syntenyaln[5]);
		}
		next if ($syntenyaln[2] > $trackend || $syntenyaln[8] > $trackend); #ignore start > track end
		next if ($syntenyaln[3] < $trackstart || $syntenyaln[9] < $trackstart); #ignore end < track start
		my $seqstart1=int ($leftmargin+($syntenyaln[2]-$trackstart)*$unitlength);
		my $seqend1=int ($leftmargin+($syntenyaln[3]-$trackstart)*$unitlength);
		my $seqstart2=int ($leftmargin+($syntenyaln[8]-$trackstart)*$unitlength);
		my $seqend2=int ($leftmargin+($syntenyaln[9]-$trackstart)*$unitlength);
		my $alignment = new GD::Image($imagewidth,$imageheight);
		my %alignmentcolor;
		for (keys %rgb)
		{
			$alignmentcolor{$_} = $alignment->colorAllocate(@{$rgb{$_}});
		}
		# make the background transparent and interlaced
		$alignment->filledRectangle(0,0,$imagewidth-1,$imageheight-1,$alignmentcolor{$transparentcolor});
		$alignment->transparent($alignmentcolor{$transparentcolor});
		$alignment->interlaced('true');

		my $alignmentpoly = new GD::Polygon;
		if($syntenyaln[4] eq "+")
		{
			$alignmentpoly->addPt($seqstart1,$imageheader+$seqnumber{$syntenyaln[1]}*$unitseqheight+$tracksize+$barheight+1);
			$alignmentpoly->addPt($seqend1,$imageheader+$seqnumber{$syntenyaln[1]}*$unitseqheight+$tracksize+$barheight+1);
		}
		else
		{
			$alignmentpoly->addPt($seqend1,$imageheader+$seqnumber{$syntenyaln[1]}*$unitseqheight+$tracksize+$barheight+1);
			$alignmentpoly->addPt($seqstart1,$imageheader+$seqnumber{$syntenyaln[1]}*$unitseqheight+$tracksize+$barheight+1);
		}
		if($syntenyaln[10] eq "+")
		{
			$alignmentpoly->addPt($seqend2,$imageheader+$seqnumber{$syntenyaln[7]}*$unitseqheight+$tracksize-1);
			$alignmentpoly->addPt($seqstart2,$imageheader+$seqnumber{$syntenyaln[7]}*$unitseqheight+$tracksize-1);
		}
		else
		{
			$alignmentpoly->addPt($seqstart2,$imageheader+$seqnumber{$syntenyaln[7]}*$unitseqheight+$tracksize-1);
			$alignmentpoly->addPt($seqend2,$imageheader+$seqnumber{$syntenyaln[7]}*$unitseqheight+$tracksize-1);
		}
		$alignment->filledPolygon($alignmentpoly,$alignmentcolor{$syntenycolor});
		$bglayer->copyMerge($alignment,$leftmargin,0,$leftmargin,0,$imagewidth-$rightmargin-$leftmargin,$imageheight,10);
	}
	close (SYNTENY);
}

#link homolog genes
if(($homology) && (-e $homology))
{
	my $homologyline=0;
	open(HOMOLOGY,"$homology") or die "can't open homology file: $homology!";
	while(<HOMOLOGY>)
	{
		$homologyline++;
		chomp;
		/^#/ and next;
		/^\s*$/ and next;
		my @homologyaln=split(/\t/,$_);
		$homologyaln[1] =~ s/^\s+//;
		$homologyaln[1] =~ s/\s+$//;
		$homologyaln[4] =~ s/^\s+//;
		$homologyaln[4] =~ s/\s+$//;
		next if(!exists $occupationleft{$homologyaln[1]} || !exists $occupationleft{$homologyaln[4]});
		if(!exists $seqname{$homologyaln[1]} || !exists $seqname{$homologyaln[4]})
		{
			print "Warning: wrong homology information detected. Please check you homology file line $homologyline.\n";
			next;
		}

		my $alignment = new GD::Image($imagewidth,$imageheight);
		my %alignmentcolor;
		for (keys %rgb)
		{
			$alignmentcolor{$_} = $alignment->colorAllocate(@{$rgb{$_}});
		}
		# make the background transparent and interlaced
		$alignment->filledRectangle(0,0,$imagewidth-1,$imageheight-1,$alignmentcolor{$transparentcolor});
		$alignment->transparent($alignmentcolor{$transparentcolor});
		$alignment->interlaced('true');

		my $alignmentpoly = new GD::Polygon;
		($homologyaln[1],$homologyaln[4])=($homologyaln[4],$homologyaln[1]) if($seqnumber{$seqname{$homologyaln[1]}} > $seqnumber{$seqname{$homologyaln[4]}});
		if($strand{$homologyaln[1]} == 1)
		{
			$alignmentpoly->addPt($occupationleft{$homologyaln[1]},$imageheader+$seqnumber{$seqname{$homologyaln[1]}}*$unitseqheight+$tracksize-$level{$homologyaln[1]}*$featuresize-$featuresize/2);
			$alignmentpoly->addPt($occupationright{$homologyaln[1]},$imageheader+$seqnumber{$seqname{$homologyaln[1]}}*$unitseqheight+$tracksize-$level{$homologyaln[1]}*$featuresize-$featuresize/2);
		}
		else
		{
			$alignmentpoly->addPt($occupationright{$homologyaln[1]},$imageheader+$seqnumber{$seqname{$homologyaln[1]}}*$unitseqheight+$tracksize+$barheight+$level{$homologyaln[1]}*$featuresize+$featuresize/2);
			$alignmentpoly->addPt($occupationleft{$homologyaln[1]},$imageheader+$seqnumber{$seqname{$homologyaln[1]}}*$unitseqheight+$tracksize+$barheight+$level{$homologyaln[1]}*$featuresize+$featuresize/2);
		}
		if($strand{$homologyaln[4]} == 1)
		{
			$alignmentpoly->addPt($occupationright{$homologyaln[4]},$imageheader+$seqnumber{$seqname{$homologyaln[4]}}*$unitseqheight+$tracksize-$level{$homologyaln[4]}*$featuresize-$featuresize/2);
			$alignmentpoly->addPt($occupationleft{$homologyaln[4]},$imageheader+$seqnumber{$seqname{$homologyaln[4]}}*$unitseqheight+$tracksize-$level{$homologyaln[4]}*$featuresize-$featuresize/2);
		}
		else
		{
			$alignmentpoly->addPt($occupationleft{$homologyaln[4]},$imageheader+$seqnumber{$seqname{$homologyaln[4]}}*$unitseqheight+$tracksize+$barheight+$level{$homologyaln[4]}*$featuresize+$featuresize/2);
			$alignmentpoly->addPt($occupationright{$homologyaln[4]},$imageheader+$seqnumber{$seqname{$homologyaln[4]}}*$unitseqheight+$tracksize+$barheight+$level{$homologyaln[4]}*$featuresize+$featuresize/2);
		}
		$alignment->filledPolygon($alignmentpoly,$alignmentcolor{$homologycolor});
		$bglayer->copyMerge($alignment,$leftmargin,0,$leftmargin,0,$imagewidth-$rightmargin-$leftmargin,$imageheight,50);
	}
	close (HOMOLOGY);
}

$bglayer->copyMerge($mainlayer,0,0,0,0,$imagewidth,$imageheight,100);

#create a png file
open (IMHANDLE,">$output");
# make sure we are writing to a binary stream
binmode IMHANDLE;
print IMHANDLE $bglayer->png;
close (IMHANDLE);

sub readcolor()
{
	my $colorlistfile=shift;
	open(COLOR,"$colorlistfile") or die "can't open color file: $colorlistfile!";
	while(<COLOR>)
	{
		chomp;
		/^#/ and next;
		/^\s*$/ and next;
		s/^\s+//;
		s/\s+$//;
		@{$availablergb{lc($4)}}=($1,$2,$3) if (/^(\d+)\s+(\d+)\s+(\d+)\s+(.+)/);
	}
	close (COLOR);
}

sub checkcolor()
{
	my ($tobechecked,$defaultcolor)=@_;
	print "Warning: color \"$tobechecked\" is not defined yet. Please check the available color name. Anyway, system will use default one.\n" and $tobechecked = $defaultcolor if (!exists $rgb{$tobechecked} && !exists $availablergb{$tobechecked});
	@{$rgb{$tobechecked}} = @{$availablergb{$tobechecked}} if (!exists $rgb{$tobechecked} && exists $availablergb{$tobechecked});
	return $tobechecked;
}
exit; 

__END__
=head1 NAME
gff2png.pl - GFF to PNG
=head1 SYNOPSIS
gff2png.pl [options]
 Options:
   -help            brief help message
   -man             full documentation
   -colorlist       available colors
   -input           input file (.gff)
   -gffversion      GFF file version
   -ignore          ignore feature
   -imagewidth      image width
   -imageheader     image header
   -rightmargin     right margin
   -bgcolor         background color
   -tracksize       track size
   -trackstart      track start
   -trackend        track end
   -featuresize     size of feature symbols
   -smallfeaturestyle small feature style
   -featurename     display feature names
   -featurenamecolor feature name color
   -barheight       bar height
   -barcolor        bar color
   -synteny         synteny file
   -syntenycolor    synteny color
   -homology        homology file
   -homologycolor   homology color
   -rulercolor      ruler color
   -rulergridlinecolor ruler gridline color
   -mainrulergridlinecolor main ruler gridline color
   -gridlinecolor   gridline color
   -maingridlinecolor main gridline color
   -graduationcolor graduation color
   -colorfile       color file
   -output          output file (.png)
=head1 OPTIONS
=over 8
=item B<-help>
Print a brief help message and exits.
=item B<-man>
Prints the manual page and exits.
=item B<-colorlist>
Prints available colors and exits.
=item B<-input>
Name of input file in GFF format.
=item B<-gffversion> (optional)
GFF file version (default is 3)
=item B<-ignore> (optional)
Ignore particular feature(s)
=item B<-imagewidth> (optional)
Image width (>=500, default 2000 pixels)
=item B<-imageheader> (optional)
Image header (>=30, default 50 pixels)
=item B<-rightmargin> (optional)
right margin of image
=item B<-bgcolor> (optional)
background color (default is "white")
=item B<-tracksize> (optional)
Track size (>=5, default 15 pixels)
=item B<-trackstart> (optional)
Track start (default 0)
=item B<-trackend> (optional)
Track end (default is the length of largest sequence)
=item B<-featuresize> (optional)
size of feature symbols (>=2, default 6 pixels)
=item B<-smallfeaturestyle> (optional)
small feature style (default 1:.... to be added, ask author for explanation)
=item B<-featurecolor> (optional)
Feature color list. e.g.
B<-featurecolor> CDS:red,exon:green
=item B<-featurename> (optional)
Default is to draw feature with name. If "featuresize" < 6, no feature name drawn.
B<-nofeaturename> is to draw without feature name.
=item B<-featurenamecolor> (optional)
color of feature name (default is "black")
=item B<-barheight> (optional)
Bar height (>=10, default 10 pixels)
=item B<-barcolor> (optional)
color of bar (default is "black")
=item B<-synteny> (optional)
synteny file name
#species1	seqid1	start1	end1	strand1	reserved	species2	seqid2	start2	end2	strand2	reserved
=item B<-syntenycolor> (optional)
synteny color (default is "blue")
=item B<-homology> (optional)
homology file name
#species1	geneid1	reserved	species2	geneid2	reserved
=item B<-homologycolor> (optional)
homology color (default is "green")
=item B<-rulercolor> (optional)
ruler color (default is "gray")
=item B<-rulergridlinecolor> (optional)
ruler gridline color (default is "gray")
=item B<-mainrulergridlinecolor> (optional)
main ruler gridline color (default is "black")
=item B<-gridlinecolor> (optional)
gridline color (default is "silver")
=item B<-maingridlinecolor> (optional)
main gridline color (default is "black")
=item B<-graduationcolor> (optional)
graduation color (default is "black")
=item B<-colorfile> (optional)
color file name. (Note: RGB code in "colorfile" will override system color). color list example:
 255 255 255		White
 192 192 192		Silver
 128 128 128		Gray
   0   0   0		Black
 255   0   0		Red
 128   0   0		Maroon
 255 255   0		Yellow
 128 128   0		Olive
   0 255   0		Lime
   0 128   0		Green
   0 255 255		Aqua
   0 128 128		Teal
   0   0 255		Blue
   0   0 128		Navy
 255   0 255		Fuchsia
 128   0 128		Purple
 ...
 Please refer to http://en.wikipedia.org/wiki/List_of_colors_%28compact%29 for color RGB code.
=item B<-output> (optional)
Name of output file in png format (default is input-file-name.png).
=back
=head1 DESCRIPTION
B<gff2png> will convert data in gff format to png file.
=head1 AUTHOR 
Jianwei Zhang @ Arizona Genomics Institute
=head1 EMAIL
jzhang@cals.arizona.edu
=head1 BUGS
=head1 SEE ALSO 
=head1 COPYRIGHT 
This program is free software. You may copy or redistribute it under the same terms as Perl itself.
=cut