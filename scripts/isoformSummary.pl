#!/usr/bin/env perl

my $usage = "isoformSummary.pl [<alias> <filename>+\n";

die $usage if @ARGV==0;

my %hash;
my %sym1;
my %sym2;
my %hRevers;
my %tRevers;
my %counts;  # counts{file}{key}=count
my @header;
my @aliasArr = ();

while(@ARGV>0){

	my $alias    = shift;
	my $filename = shift or die "no filename assigned for $alias\n";
	push @aliasArr, $alias;

	open(FILE,"<$filename");
	while(<FILE>){
		chomp;
		@header=split(/\t/,$_) if $.==1;
		next if /^#/;
		my @t=split(/\t/,$_);
		my @s=();
		
		# extract blocks
		while($t[-1]=~/\(.+?\)/g){
			push @s,substr($t[-1],$-[0],$+[0]-$-[0])
		}
		
		# @r for backup block strings
		my @r=@s;
		$s[0]=~s/\([+|\-]*\d*/\(X/;
		$s[-1]=~s/[+|\-]*\d*\)/X\)/;
	
		# $pattern to be end-masked alignment string
		my $pattern=$t[-1];
		# must be the first
		substr($pattern,index($pattern,$r[0]),length($r[0]))=$s[0] if index($pattern,$r[0])>=0;
		# make sure to be the last
		my $lastMatchPos=index($pattern,$r[-1]);
		my $lastMatchPos_ex = $lastMatchPos;
		while($lastMatchPos>=0){
			$lastMatchPos_ex = $lastMatchPos;
			$lastMatchPos = index($pattern,$r[-1],$lastMatchPos+1);
		}
		substr($pattern,$lastMatchPos_ex,length($r[-1]))=$s[-1] if $lastMatchPos_ex>=0;
	
		my $symboH;
		my $symboT;
		my $relativeLen = 0;
		($symboH)=$r[0]=~/\(([+|\-]*\d*)/;  # number/shift in head
		($symboT)=$r[-1]=~/([+|\-]*\d*)\)/; # number/shift in tail
		
		# if first block external
		if( length($symboH)>0 ){
			if($r[0]=~/\((\d+)\s(\d+)\)/){
				$symboH=$1;
				$hRevers{$t[1],$pattern}=1 if ($2-$1)>0; # reverse selection, pick smallest
			
				if($2>$1){
					$relativeLen += ($2-$1+1);
				}else{
					$relativeLen += ($1-$2+1);
				}
			}else{
				$relativeLen += sprintf("%d",$symboH);
			}
		}
	
		# if last block external	
		if( length($symboT)>0 ){
			if($r[-1]=~/\((\d+)\s(\d+)\)/){
				$symboT=$2;
				$tRevers{$t[1],$pattern}=1 if ($2-$1)<0; # reverse selection, pick smallest
			
				if($2>$1){
					$relativeLen += ($2-$1+1);
				}else{
					$relativeLen += ($1-$2+1);
				}
			}else{
				$relativeLen += sprintf("%d",$symboT);
			}
		}
		
		my ($head,$tail)=(0,0);
		$head=$symboH if length($symboH)>0;
		$tail=$symboT if length($symboT)>0;
		
		push @{$hash{$t[1],$pattern}{$relativeLen}}, @t if not exists $hash{$t[1],$pattern}{$relativeLen};
		$counts{$alias}{$t[1],$pattern}++;
		$sym1{$t[1],$pattern}{$head}=$symboH;
		$sym2{$t[1],$pattern}{$tail}=$symboT
	}

	close FILE;
}
	
print "#".join("\t",@header[1..15])."\t$header[-1]\t".join("\t",@aliasArr)."\n";
for $key(sort keys %hash){
	# take the one with longest relativeLen
	$k=(sort {$b<=>$a} keys %{$hash{$key}})[0];
	
	# from greatest to smallest
	my @sorted1=sort {$b<=>$a} keys %{$sym1{$key}};
	my @sorted2=sort {$b<=>$a} keys %{$sym2{$key}};

	my $kk1=$sorted1[0];
	$kk1=$sorted1[-1] if exists $hRevers{$key};
	my $kk2=$sorted2[0];
	$kk2=$sorted2[-1] if exists $tRevers{$key};
	
	$newpattern=(split($;,$key))[1];
	$newpattern=~s/\(X/\($sym1{$key}{$kk1}/;
	$newpattern=~s/X\)/$sym2{$key}{$kk2}\)/;
	
	print join("\t",@{$hash{$key}{$k}}[1..15])."\t$newpattern";
	for my $alias (@aliasArr){
		if(exists $counts{$alias}{$key}){
			print "\t$counts{$alias}{$key}";
		}else{
			print "\t0";
		}
	}
	print "\n";
}
