#!/usr/bin/env perl6

use lib 'lib';

use QSim;

constant samples-total = 10000000;
constant bin-size = 2;
constant hist-width = 70;
constant event-window = 5000;

sub random-events($basename, &random-func) {
    my $i = 0;
    my @hist;
    my $event-fh = open("{$basename}-events.data", :w);
    my $histogram-fh = open("{$basename}-hist.data", :w);
    while $i < samples-total {
        my $sample = &random-func();
        $i += $sample;
        if $i < event-window {
            $event-fh.say($i);
        }
        my $idx = round($sample/bin-size); 
        @hist[$idx]++;
    }
    for ^hist-width -> $idx {
        my $cv = @hist[$idx] // 0;
        if $idx > 0 {
            $histogram-fh.say("{$idx * bin-size} $cv");
        }
    }
    $event-fh.close;
    $histogram-fh.close;
}

random-events("normal", { 60 + 30.rand + 30.rand - 30.rand - 30.rand });
random-events("random", { 120.rand });
random-events("poisson", { random-poisson-distance(60) });

