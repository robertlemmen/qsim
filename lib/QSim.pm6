unit module QSim;

=begin pod
=head1 QSim -- Monte Carlo Simulation of Queue Networks

This program allows simulating networks of queues and processors, like the
ones analyzed and describe by Agner Krarup Erlang and David George Kendall. It 
does this not via proper maths, but simply by mote carlo simulation. This is 
less elegant, but easier for me and allows analyzing complicated cases as well.

The model used by this simulation is not as minimal and pure as it could be. 
This is done in the hope that it makes the expression of networks to be 
analyzed more concise. For example, this supports a "failure" mode that directly
routes to a specific point and skips further processing.

XXX more general docs

=head2 Data Model

The network being analyzed needs to be expressed as a graph of related objects 
from a relatively small set of types. It is important to understand these types
and what properties they have:

=head3 Queues

At the very heart of this model are queues of course, these can exhibit 
different behavior specified by a queue size, which can be infinite, and the 
behavior on overflow. For the latter this code supports three modes: cause 
failures on overflow (see below for failures), block the processor that is 
trying to put items on the queue, or just drop messages.

All queues in this model are FIFO.
=end pod

enum QueueOverflowBehavior (
    FAIL => 1,
    BLOCK => 2,
    DROP => 3,
);

class Queue is export {
    has $.id;
    has $.size;
    has $.overflow-behavior;
    has $.sink is rw;
    has @!queue;

    method plot-node($id) {
        say "  $id [label=\"Queue s=$!size\", shape=rect]";
    }

    method handle($message) {
        if @!queue.elems == 0 {
            # pass directly to sink
            if $!sink.handle($message) {
                return True;
            }
        }
        @!queue.push($message);
        say "  enqueuing $message, now at {@!queue.elems}";
        # XXX does not handle overflows at the moment
        return True;
    }

    method reset() {
        @!queue = [];
    }

    method tick() {
        if @!queue.elems {
            if $!sink.handle(@!queue.first) {
                my $prev-msg = @!queue.shift;
                say "  dequeued {$prev-msg}, now at {@!queue.elems}";
                return True;
            }
            return False;
        }
    }

    method measure() {
        return @!queue.elems;
    }
}

=begin pod
=head3 Processors

At the end of each queue sits a processor that consumes messages from the queue,
does something with them by virtue of a processing callable that modifies the
item if necessary and also determines the simulated time needed for this
processing.

Processors also have a configurable capacity of how many items can be processed
in parallel.
=end pod

class Processor is export {
    has $.id;
    has $.capacity;
    has &.proc-func;
    has $.sink is rw;
    has $!currently-active = 0;
    has @!processing-messages;
    has @!processing-done-times;

    method plot-node($id) {
        say "  $id [label=\"Processor c=$!capacity\", shape=ellipse]";
    }

    method handle($message) {
        if $!currently-active < $!capacity {
            $!currently-active++;
            # XXX only handles capacity == 1 at the moment
            my ($done-time, $out-message) = &!proc-func($message);
            say "  handling $message, will take $done-time";
            $*event-scheduler.next-tick-in($done-time);
            @!processing-messages[0] = $out-message;
            @!processing-done-times[0] = $*current-time + $done-time;
            return True;
        }
        else {
            return False;
        }
    }
    
    method reset() {
        $!currently-active = 0;
        @!processing-messages = [];
        @!processing-done-times = [];
    }


    method tick() {
        if $!currently-active > 0 && $*current-time >= @!processing-done-times[0] {
            if $!sink.handle(@!processing-messages[0]) {
                say "  finished processing {@!processing-messages[0]}";
                $!currently-active--;
                return True;
            }
        }
        return False;
    }
    
    method measure() {
        return $!currently-active;
    }
}

=begin pod
=head3 Routes

Processors emit their messages to routes which are typically (but see next
paragraph for exceptions) connected to one or more sink queues, and have a
function that decides which queue a message should be routed to.

There are exactly two exceptional routes in any model this software uses:
an input route that receives all messages that are sent through the network.
These are not emitted by a processor but by a network simulation test bed
object. Similarily, there is a single route that does not emit messages into
a queue, the output route that sends (non-failure) messages to the test bed
receiver.

Messages are delivered instantaneous trough routes, if you want to simulate
different, i.e. real-world behaviour, you need to model things like a network
transmission as a queue and a simple processor.

So a simple setup could look like this:

=begin code
                                            Processor
                      Queue                  ,----.
              -+---------------------+      /      \
      +------> | | | | s=5 | | | | | |----->| c=2  |-----+
      |       -+---------------------+      \     /      |
      |                                      `---'       |
      |                                                  V
    +--------------------------------------------------------+
    |                                                        |
    |                 SIMULATION TEST BED                    |
    |                                                        |
    +--------------------------------------------------------+
=end code
=end pod

class Route is export {
    has @.sinks is rw;
    has $.sink-select-func;

    method handle($message) {
        # XXX for now we do not suport multiple sinks or a sink-select-func
        return @!sinks[0].handle($message);
    }
}

=begin pod
=head3 Simulation Test Bed

The simulation test bed produces messages using a producer callable that also
defines the interval between a message and the next, and then sends these
messages through the network. They either arrive back at the test bed through
regular routing, or through a specal failure channel.
=end pod

class TestBed is export {
    has $.id = "tb";
    has $.sink is rw;
    has &.producer-func;
    has $!next-emission = 0;

    method plot-node($id) {
        say "  $id [label=\"TestBed\", shape=parallelogram, rank=0]";
    }

    method handle($message) {
        say "  $message done!";
    }

    method reset() {
        $!next-emission = 0;
    }

    method tick() {
        if $*current-time >= $!next-emission {
            my ($next-time, $message) = &!producer-func();
            say "  testbed emitting $message, next one ine $next-time";
            if ! $!sink.handle($message) {
                # XXX handle better
                say "$message dropped due to backlog";
            }
            $*event-scheduler.next-tick-in($next-time);
            $!next-emission = $*current-time + $next-time;
        }
        return False;
    }

    method measure() {
        # XXX not sure what to do
        return 0;
    }
}

# XXX docs, also needs to have slurpy second arg
sub connect($a, $b) is export {
    $a.sink = Route.new(sinks => ($b));
}

sub plot-network($start-node) is export {
    my $node = $start-node;
    my %seen{Any}; # XXX put outside inner loop
    my $node-id-seq = 1;

    # XXX put testbed in own subgraph to render it outside the
    # rest of the graph

    say "digraph G \{";
    say "  rankdir=LR";

    sub rec-iterate($node) {
        if %seen{$node} {
            return %seen{$node};
        }

        %seen{$node} = $node-id-seq;
        $node.plot-node($node-id-seq);
        my $node-id = $node-id-seq++;
        my $route = $node.sink;
        for $route.sinks -> $next-node {
            my $next-id = rec-iterate($next-node);
            say "  $node-id -> $next-id"
        }
        return $node-id;
    }

    rec-iterate($start-node);

    say "\}";
}

# XXX how do we get a poisson-distributed random distance function
# https://preshing.com/20111007/how-to-generate-random-timings-for-a-poisson-process/
# generate random number 0..1 if we want an event every X on average, then we
# need -ln U * X as the interval to the next. try this
sub random-poisson-distance($average-distance) is export {
    return 1.rand.log * $average-distance * -1;
}

class EventScheduler is export {
    has @!components;
    has @!scheduled-ticks;

    method register($comp) {
        @!components.push($comp);
    }

    method simulate($duration, $measurement-interval) {
        my $*current-time = 0;
        @!scheduled-ticks = [];
        # for the dynamic access
        my $*event-scheduler = self;
        my $next-measurement = 0;
        my @measurements;

        for @!components -> $comp {
            $comp.reset();
        }

        while $next-measurement < $duration {
            say "tick $*current-time";
            while $*current-time >= $next-measurement {
                my %measurement := { time => $next-measurement };
                say "measurement $next-measurement";
                for @!components -> $comp {
                    %measurement{$comp.id} = $comp.measure();
                }
                @measurements.push(%measurement);
                $next-measurement += $measurement-interval;
                # XXX measure all the things!
            }
            my $run-again;
            # if one component change state, we prod them all again to make sure
            # all possible state changes have happened
            repeat {
                $run-again = False;
                for @!components -> $comp {                
                    $run-again = $run-again ?| $comp.tick();
                }
            } while $run-again;

            @!scheduled-ticks = @!scheduled-ticks.sort;
            
            $*current-time = @!scheduled-ticks.shift;
        }
        return @measurements;
    }

    method next-tick-at($time) {
#        say "scheduling tick at $time";
        @!scheduled-ticks.push($time);
    }

    method next-tick-in($duration) {
        my $time = $*current-time + $duration;
        say "scheduling tick at $time";
        @!scheduled-ticks.push($time);
    }
}

sub refold-results(@input-results) is export {
    my @output;
    for @input-results -> @cr {
        my $idx = 0;
        for @cr -> %ccr {
            my $cor = @output[$idx] // { };
            for %ccr.pairs -> $cp {
                $cor{$cp.key}.push($cp.value);
            }
            @output[$idx] = $cor;
            $idx++;
        }
    }
    return @output;
}

sub apply-aggregate(@input-results, %aggregators) is export {
    my @output;
    for @input-results -> %ci {
        my %co;
        for %ci.keys -> $k {
            if %aggregators{$k}:exists {
                %co.push(%aggregators{$k}(%ci{$k}));
            }
            else {
                %co{$k} = %ci{$k};
            }
        }
        @output.push(%co);
    }
    return @output;
}

sub dump-results(@results) is export {
    my @header-fields = @results[0].keys.sort;
    
    say @header-fields.map({ sprintf("%12s", $_) }).join();
    for @results -> %r {
        say %r{@header-fields}.map({ $_ // -1 }).map({ sprintf("%12.6f", $_) }).join();
    }
}
