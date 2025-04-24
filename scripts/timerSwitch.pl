#!/usr/bin/env -S perl -w

use Time::Local;
use Time::HiRes qw(usleep);

my $debug = 1;

my $devConfig   = "./dev.cfg";
my $startTime   = "";
my $startSwitch = 1;
my $testFlag    = "";

# time interval sequence
my @timeSeq = ();

my $usage  = "Usage: timerSwitch.pl [options] <deviceName> [<time interval>]+\n";
$usage    .= "     -config <config>   : device config file (default: $devConfig)\n";
$usage    .= "     -startTime <h:m:s> : start at specified time (default: start immediately)\n";
$usage    .= "     -startSwitch <0|1> : start with switch state (default: 1 (switch on))\n";
$usage    .= "     -test              : test purpose. Will switch on and off for every 2 seconds\n";
$usage    .= "     -testON            : test purpose. Will switch on the device\n";
$usage    .= "     -testOFF           : test purpose. Will switch off the device\n";

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
    }elsif($ARGV[$i] eq "-testON") {
        $testFlag = "testON";
        delete $arg_idx[$i];
    }elsif($ARGV[$i] eq "-testOFF") {
        $testFlag = "testOFF";
        delete $arg_idx[$i];
    }elsif($ARGV[$i] eq "-test") {
        $testFlag = "test";
        $startTime = "";
        @timeSeq = (2);
        delete $arg_idx[$i];
    }
}
my @new_arg;
for (@arg_idx) { push(@new_arg,$ARGV[$_]) if (defined($_)); }
@ARGV=@new_arg;

my $targetDevice = shift or die $usage;

# read config file
my %deviceHash = ();
if (-e $devConfig && -f $devConfig) {
    open(FILE,"<$devConfig");
    my $lastLine = "";
    my $deviceName;
    while(<FILE>){
        chomp;
        s/^\s+|\s+$//g;
        my @t=split;
        
        if(length($lastLine)==0 && length($_)>0){
            # last line empty, this line non-empty
            # first token as device name
            $deviceName = $t[0];
            
            if(exists $deviceHash{$deviceName}){
                print STDERR "repeated device name: $deviceName\n";
                exit 1;
            }
        }elsif(length($lastLine)>0 && length($_)>0){
            # last line non-empty, this line non-empty
            # this line push into the array
            push @{$deviceHash{$deviceName}}, $_;
            # in so doing, the line second to device name would be index 0 (ie off),
            # and the next line would be index 1 (ie on).
        }
        
        $lastLine = $_;
    }
    close FILE;
}else{
    print STDERR "$devConfig does not exist or is not a regular file.\n";
    exit 1;
}

# check target in config
if(not exists $deviceHash{$targetDevice}){
    print STDERR "$targetDevice not defined in config file $devConfig\n";
    exit 1;
}

### TEST ON
if($testFlag eq "testON"){
    execForceNewline($deviceHash{$targetDevice}[1]);
    exit 0;
}
### TEST OFF
elsif($testFlag eq "testOFF"){
    execForceNewline($deviceHash{$targetDevice}[0]);
    exit 0;
}
### TEST
elsif($testFlag eq "test"){
    # no need to read time intervals
}
### regular use
else{
    # read time interval sequence
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
    
    if(0==@timeSeq){
        print STDERR "must specify at least one interval\n";
        exit 1;
    }
}

# time related variable init
my $currentTime = time;

my $switchIdx = $startSwitch;
my @switchArr = (0, 1); # off and on
my $timeSeqIdx = 0;

# sleep if $startTime specified
if(length($startTime)>0){
    my ($targetHour, $targetMinute, $targetSecond);
    
    # format check
    if($startTime!~/(\d+):(\d+):(\d+)/){
        print STDERR "-startTime $startTime format error\n";
        exit 1;
    }
    ($targetHour,$targetMinute,$targetSecond) = ($1,$2,$3);
    if($targetHour>=24){
        print STDERR "hour must less than 24: $targetHour\n";
        exit 1;
    }
    if($targetMinute>=60){
        print STDERR "minute must less than 60: $targetMinute\n";
        exit 1;
    }
    if($targetSecond>=60){
        print STDERR "second must less than 60: $targetSecond\n";
        exit 1;
    }
    
    # get current time
    my ($sec, $min, $hour, $day, $month, $year) = localtime;
    
    my $targetTime = timelocal($targetSecond, $targetMinute, $targetHour, $day, $month, $year);
    $currentTime = time;
    
    # ex: current time 00:05:00 and target 00:04:00 => one more day
    $targetTime += (60*60*24) if $targetTime<=$currentTime;
    
    ($sec, $min, $hour, $day, $month, $year) = localtime($targetTime);
    $year += 1900;  # Convert year
    $month += 1;    # Convert month (0-based)
    
    print "Will start at time: ".dateString($targetTime)."\n";
    $currentTime = preciseSleepTo($targetTime);
}

# time interval iteration, infinity
while(1){
    print "TIME: ".dateString(time).", ACTION: $switchIdx\n";
    execForceNewline($deviceHash{$targetDevice}[$switchIdx]);
    
    $switchIdx++;
    $switchIdx=0 if $switchIdx>=@switchArr;
    
    $currentTime += $timeSeq[$timeSeqIdx];
    $timeSeqIdx++;
    $timeSeqIdx=0 if $timeSeqIdx>=@timeSeq;
    
    $currentTime = preciseSleepTo($currentTime);
}

# subroutine for date string
sub dateString {
    my $targetTime = shift;
    
    my ($sec, $min, $hour, $day, $month, $year) = localtime($targetTime);
    $year += 1900;  # Convert year
    $month += 1;    # Convert month (0-based)
    
    return "$year-$month-$day ".sprintf("%02d:%02d:%02d",$hour,$min,$sec);
}

# subroutine to preicse wait, the input should be epoch second
sub preciseSleepTo {
    my $targetTime = shift;
    
    my $currentTime = time;
    
    # non-precise sleep to 2 second before target
    if($targetTime-$currentTime>2){
        sleep ($targetTime-$currentTime-2);
    }
    # loop with precise sleep
    $currentTime = time;
    while($currentTime<$targetTime){
        usleep(100_000); # sleep 0.1 second
        $currentTime = time;
    }
    return $targetTime;
}

# subroutine to execute a command with force-newline output
sub execForceNewline {
    my $cmd = shift;
    
    open(my $fh, "$cmd 2>&1 |") or die "Failed: $!";
    while (<$fh>) {
        chomp;
        print "$_\n";
    }
    close($fh);
}
