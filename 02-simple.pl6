#!/usr/bin/env perl6

use lib 'lib';

use QSim;

# this demonstrates the basic queue network setup, a single run as well
# as a monte carlo run and aggregation. as a third result, it re-runs the 
# simple model simulation with a concurrent processor

sub tb-producer() {
    state $i = 0;
    return (random-poisson-distance(35), "m" ~ $i++);
}

sub p1-processor($message) {
    return (random-poisson-distance(30), $message ~ '+');
}

my $example = TestBed.new(producer-func => &tb-producer);
my $q1 = Queue.new(id => "q1", size => 5);
my $p1 = Processor.new(id => "p1", proc-func => &p1-processor, capacity => 1);

connect($example, $q1);
connect($q1, $p1);
connect($p1, $example);

my $scheduler = EventScheduler.new;
$scheduler.register($example);
$scheduler.register($q1);
$scheduler.register($p1);

my @results;
for ^1 {
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

my $result-fh = open("simple-queue.data", :w);
dump-results(@results, $result-fh);
$result-fh.close;

@results = [];
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

my $result-fh = open("simple-queue-2.data", :w);
dump-results(@results, $result-fh);
$result-fh.close;

# -------------------------------

sub p2-processor($message) {
    return (random-poisson-distance(240), $message ~ '+');
}

$example = TestBed.new(producer-func => &tb-producer);
$q1 = Queue.new(id => "q1", size => 5);
$p1 = Processor.new(id => "p1", proc-func => &p2-processor, capacity => 8);

connect($example, $q1);
connect($q1, $p1);
connect($p1, $example);

$scheduler = EventScheduler.new;
$scheduler.register($example);
$scheduler.register($q1);
$scheduler.register($p1);

@results = [];
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

my $result-fh = open("simple-queue-3.data", :w);
dump-results(@results, $result-fh);
$result-fh.close;
