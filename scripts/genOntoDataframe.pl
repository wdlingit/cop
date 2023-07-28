#!/usr/bin/perl -w

use Getopt::Long;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

my $debug = 0;

my $usage = "Usage: genOntoDataframe.pl [options] [<input name> <input file>]+\n";
$usage   .= "     -filter <col> <filter> : column to be filtered by the filter (default: none)\n";
$usage   .= "     -term <string>         : combination of columns for term definitions (default: \"1\")\n";
$usage   .= "     -data <col> <header>   : assign data column and header name (default: no columns)\n";

my $termIdxStr = "1";
my @dataCol    = ();
my %dataColHeader = ();
my @filterArray = ();

#Retrieve parameter
my @arg_idx=(0..@ARGV-1);
for my $i (0..@ARGV-1) {
	if($ARGV[$i] eq '-term'){
		$termIdxStr = $ARGV[$i+1];
		delete @arg_idx[$i,$i+1];
	}elsif($ARGV[$i] eq '-data'){
		push @dataCol, $ARGV[$i+1];
		$dataColHeader{$ARGV[$i+1]}=$ARGV[$i+2];
		delete @arg_idx[$i..$i+2];
	}elsif($ARGV[$i] eq '-filter'){
		push @filterArray, $ARGV[$i+1], $ARGV[$i+2];
		delete @arg_idx[$i..$i+2];
	}
}
my @new_arg;
for (@arg_idx) { push(@new_arg,$ARGV[$_]) if (defined($_)); }
@ARGV=@new_arg;

die "$usage\nno data colum inputted (-data)\n" if @dataCol==0;

my @termIdxCols = split(/,/,$termIdxStr);

# collect numbers from all files
my $setName;
my $filename;
my @setNameArr = ();
my %valHash  = (); # $valHash{$term}{$setName} = @valArray
my %termHash = (); # for collected terms
while(@ARGV>0){
	$setName  = shift or die $usage;
	$filename = shift or die $usage;
	push @setNameArr, $setName;
	
	open(FILE,"<$filename");
	while(<FILE>){
		chomp;
		my @t=split(/\t/);
		
		my $testRes=1;
		print "LINE: $_\n" if $debug;
		for(my $testI=0; $testI<@filterArray; $testI+=2){
			my $testCol = $filterArray[$testI];
			my $testVal = $t[$testCol-1];
			my $testCond = $filterArray[$testI+1];
			
			if(not looks_like_number($testVal)){
				$testRes = 0;
				next;
			}
			
			print "EVAL: $testVal $testCond\n" if $debug;
			my $tmpRes = eval "$testVal $testCond";
			print "RES1: $tmpRes\n" if $debug;
			if($@){
				$tmpRes = 0;
			}
			print "RES2: $tmpRes\n" if $debug;
			
			$testRes=0 if not $tmpRes;
		}
		
		my $term="";
		for my $idx (@termIdxCols){
			if(length($term)==0){
				$term = $t[$idx-1];
			}else{
				$term .= "_$t[$idx-1]";
			}
		}

		for my $idx (@dataCol){
			push @{$valHash{$term}{$setName}}, $t[$idx-1];
		}
		
		# collect this term if pass
		if($testRes){
			$termHash{$term}=1;
		}
	}
	close FILE;
}

# output
print "TERM\tSET";
for my $idx (@dataCol){
	print "\t$dataColHeader{$idx}";
}
print "\n";
for my $term (sort keys %termHash){
	for my $set (@setNameArr){
		print "$term\t$set\t".join("\t",@{$valHash{$term}{$set}})."\n" if exists $valHash{$term}{$set};
	}
}

# Logarithm
sub log10 {
	my $n = shift;
	return log($n)/log(10);
}
