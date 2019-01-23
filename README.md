# QSim -- Monte Carlo Simulation of Queue Networks

This repository contains code to analyze networks of queues and processors, like
in the work of Agner Krarup Erlang and David George Kendall. This can be useful
to e.g. understand failure modes of distributed software systems better. The
code is written primarily for a presentation contained in the talk/ directory.

## Documentation

The code typically comes in pairs of perl 6 programs that run experiments and
generate numbers, and R scripts that turn these into graphs. The perl 6 programs
use the main code in lib/QSim.pm6.

All actual documentation of that module, if present at all, is in POD format in the code, 
please refer to that

## License

QSim is licensed under the [Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0).

## Feedback and Contact

Please let me know what you think: Robert Lemmen <robertle@semistable.com>
