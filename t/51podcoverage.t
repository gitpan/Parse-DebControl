#!/usr/bin/perl -w 

use strict;
use Test::More tests => 1;
push @INC, "./lib";
eval "use Pod::Coverage";
plan skip_all => "Pod::Coverage required for documentation check" if $@;

my $pc = Pod::Coverage->new(package => "Parse::DebControl");
ok($pc->coverage == 1, "Pod::Coverage documentation overview is ok");
