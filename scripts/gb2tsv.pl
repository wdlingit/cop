#!/usr/bin/env perl

my $usage = "Usage: GenBank2table.pl\n";

# Retrieve parameter
my @arg_idx=(0..@ARGV-1);
for my $i (0..@ARGV-1) {
	if ($ARGV[$i] eq '-redundancy') {
	}
}

my @new_arg;
for (@arg_idx) { push(@new_arg,$ARGV[$_]) if (defined($_)); }
@ARGV=@new_arg;

my $flagProc = 0;

my $recIdx = 0;
my %featureHash = ();   # recIdx -> feature
my %recLines = ();      # recIdx -> lines
while(<>){
	# start processing if meet starting FEATURES
	if(/^FEATURES/){ $flagProc = 1; next }
	if(/^\S/){ $flagProc = 0; }
	
	next if not $flagProc;
	
	# processing
	chomp;
	s/\s+$//; # remove possible tailing space
	
	my ($tag,$val)=/(.{21})(.+)/; # assuming the leading width is 21

	$tag=~s/^\s+|\s+$//g;
	if(length($tag)>0){
		$recIdx++;
		$featureHash{$recIdx} = $tag;
	}
	push @{$recLines{$recIdx}}, $val;
}

# post processing
my %recAttrs = ();      # recIdx -> lines
my %attrHash = ();      # for all attrs
for my $idx (sort {$a<=>$b} keys %recLines){

	my @lines = @{$recLines{$idx}};
	
	# always take first line as location
	$lines[0]="/LOCATION=$lines[0]";
	
	# concatenate lines if of the same attr
	my @newLines;
	for my $line (@lines){
		if($line=~/^\//){
			push @newLines, $line;
		}else{
			$newLines[-1].=" $line";
		}
	}
	
	# form attr values
	for my $line (@newLines){
		if($line=~/^\/(.+?)=(.+)/){
			my $attr = $1;
			my $val  = $2;
			
			$val = $1 if $val=~/^"(.+)"$/;  # remove leading and tailing quote signs
			
			if(exists $recAttrs{$idx}{$attr}){
				$recAttrs{$idx}{$attr} .= " | $val";
			}else{
				$recAttrs{$idx}{$attr} = $val;
			}
			
			$attrHash{$attr}=1;
		}elsif($line=~/^\/(.+)/){
			my $attr = $1;
			my $val  = "V";
			
			$recAttrs{$idx}{$attr} = $val;
			$attrHash{$attr}=1;
		}else{
			print STDERR "something wrong with $line\n";
			exit 1;
		}
	}
	
	# post processing on specific attrs
	for my $attr (keys %{$recAttrs{$idx}}){
		if($attr eq "translation"){
			$recAttrs{$idx}{$attr}=~s/\s//g; # remove spaces
		}
	}
}

# output, header
print "#index\tFEATURE";
for my $attr (sort keys %attrHash){
	print "\t$attr";
}
print "\n";

# output, rest
for my $idx (sort {$a<=>$b} keys %recLines){
	print "$idx\t$featureHash{$idx}";
	for my $attr (sort keys %attrHash){
		if(exists $recAttrs{$idx}{$attr}){
			print "\t$recAttrs{$idx}{$attr}";
		}else{
			print "\t";
		}
	}
	print "\n";
}
