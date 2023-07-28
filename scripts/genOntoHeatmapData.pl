#!/usr/bin/perl -w

use Getopt::Long;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

my $usage = "Usage: genOntoHeatmapData.pl [-term <string>] [-x <p-value cutoff>] <p-value column> [<input name> <input file>]+\n";
$usage   .= "     -x <float>     : p-value cutoff (default: 0.05)\n";
$usage   .= "     -term <string> : combination of columns for term definitions (default: \"1\")\n";

my $pCut = 0.05;
my $termIdxStr = "1";

#Retrieve parameter
my @arg_idx=(0..@ARGV-1);
for my $i (0..@ARGV-1) {
	if ($ARGV[$i] eq '-x') {
		$pCut = $ARGV[$i+1];
		delete @arg_idx[$i,$i+1];
	}elsif($ARGV[$i] eq '-term'){
		$termIdxStr = $ARGV[$i+1];
		delete @arg_idx[$i,$i+1];
	}
}
my @new_arg;
for (@arg_idx) { push(@new_arg,$ARGV[$_]) if (defined($_)); }
@ARGV=@new_arg;

my $pCol = shift or die $usage;
my @termIdxCols = split(/,/,$termIdxStr);

# collect numbers from all files
my $setName;
my $filename;
my @setNameArr = ();
my %valHash  = ();
my %termHash = (); # for collected terms
while(@ARGV>0){
	$setName  = shift or die $usage;
	$filename = shift or die $usage;
	push @setNameArr, $setName;
	
	open(FILE,"<$filename");
	while(<FILE>){
		chomp;
		my @t=split(/\t/);
		my $pVal = $t[$pCol-1];
		
		next if not looks_like_number($pVal);
		
		my $term="";
		for my $idx (@termIdxCols){
			if(length($term)==0){
				$term = $t[$idx-1];
			}else{
				$term .= "_$t[$idx-1]";
			}
		}
		$valHash{$setName}{$term} = $pVal;
		
		# collect this term if pass
		if($pVal < $pCut){
			$termHash{$term}=1;
		}
	}
	close FILE;
}

# output
print "TERM\t".join("\t",@setNameArr)."\n";
for my $term (sort keys %termHash){
	print "$term";
	for my $set (@setNameArr){
		if(exists $valHash{$set}{$term}){
			my $val = $valHash{$set}{$term};
			$val = -log10($val);
			print "\t$val";
		}else{
			print "\t0";
		}
	}
	print "\n";
}

# Logarithm
sub log10 {
	my $n = shift;
	return log($n)/log(10);
}
