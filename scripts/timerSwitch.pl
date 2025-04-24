#!/usr/bin/env -S perl -w

my $devConfig = "./dev.cfg";
my $startTime = "";
my $startSwitch = 1;

my $usage  = "Usage: timerSwitch.pl [options] <deviceName> [<time interval>]+\n";
$usage    .= "     -config <config>   : device config file (default: $devConfig)\n";
$usage    .= "     -startTime <time>  : start at specified time (default: start immediately)\n";
$usage    .= "     -startSwitch <0|1> : start with switch state (default: 1 (switch on))\n";
$usage    .= "     -test              : test purpose. Will switch on and off for every 2 seconds\n";

# retrieve parameter
my @arg_idx=(0..@ARGV-1);
for my $i (0..@ARGV-1) {
    if($ARGV[$i] eq "-config") {
        $devConfig = $ARGV[$i+1];
	delete @arg_idx[$i,$i+1];
    }elsif($ARGV[$i] eq "-startTime") {
        $startTime = $ARGV[$i+1];
        delete @arg_idx[$i,$i+1];
    }elsif($ARGV[$i] eq "-startSwitch") {
        $startSwitch = $ARGV[$i+1];
        delete @arg_idx[$i,$i+1];
    }
}
my @new_arg;
for (@arg_idx) { push(@new_arg,$ARGV[$_]) if (defined($_)); }
@ARGV=@new_arg;

my $devName = shift or die $usage;
my @timeSeq = ();

for my $str (@ARGV){
    my $ansSec = 0;
    
    # dirty work, just list all combination
    if($str=~/^(\d+)$/){
        $ansSec = $1;
    }elsif($str=~/^(\d+)h$/i){
        $ansSec = $1*60*60;
    }elsif($str=~/^(\d+)m$/i){
        $ansSec = $1*60;
    }elsif($str=~/^(\d+)s$/i){
        $ansSec = $1;
    }elsif($str=~/^(\d+)h(\d+)m(\d+)s$/i){
        $ansSec = $1*60*60 + $2*60 + $3;
    }elsif($str=~/^(\d+)h(\d+)s$/i){
        $ansSec = $1*60*60 + $2;
    }elsif($str=~/^(\d+)h(\d+)m$/i){
        $ansSec = $1*60*60 + $2*60;
    }elsif($str=~/^(\d+)m(\d+)s$/i){
        $ansSec = $1*60 + $2;
    }else{
        print STDERR "invalid time interval: $str\n";
        exit 1;
    }
    
    if($ansSec == 0){
        print STDERR "time interval cannot be 0: $str\n";
        exit 1;
    }
    
    push @timeSeq, $ansSec;
}
