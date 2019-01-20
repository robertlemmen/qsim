#!/usr/bin/env perl6

use lib 'lib';

use QSim;

sub tb-producer() {
    state $i = 0;
    my $interval = 34;
    if 2000 < $*current-time < 5000 {
        $interval = 20;
    }
    return (random-poisson-distance($interval), "m" ~ $i++);
}

sub p2-processor($message) {
    return (random-poisson-distance(240), $message ~ '+');
}

my $example = TestBed.new(producer-func => &tb-producer);
my $q1 = Queue.new(id => "q1", size => 5);
my $p1 = Processor.new(id => "p1", proc-func => &p2-processor, capacity => 8);

connect($example, $q1);
connect($q1, $p1);
connect($p1, $example);

my $scheduler = EventScheduler.new;
$scheduler.register($example);
$scheduler.register($q1);
$scheduler.register($p1);

my @results = [];
for ^250 {
    my @m = $scheduler.simulate(10000, 10);
    @results.push(@m);
}

@results = refold-results(@results);

@results = apply-aggregate(@results, {
    time => sub (@vals) { return time => @vals[0]; }, # XXX we should also assert they are all the same!
    p1 => sub (@vals) {
        my $mean = ([+] @vals).Num / @vals.elems;
        my $dev = Nil;
        if (@vals.elems > 1) {
            $dev = sqrt([+] @vals.map({ ($_ - $mean) ** 2 })).Num / (@vals.elems - 1);
        }
        return p1_mean => $mean, p1_dev => $dev;
    },
    q1 => sub (@vals) { # XXX same as above refactor
        my $mean = ([+] @vals).Num / @vals.elems;
        my $dev = Nil;
        if (@vals.elems > 1) {
            $dev = sqrt([+] @vals.map({ ($_ - $mean) ** 2 })).Num / (@vals.elems - 1);
        }
        return q1_mean => $mean, q1_dev => $dev;
    },
    tb => sub (@vals) {
        return {};
    }
});

my $result-fh = open("overload-1.data", :w);
dump-results(@results, $result-fh);
$result-fh.close;
