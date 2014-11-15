#!/usr/bin/env perl6

# these tests check for conformance with error handling as outline in
# http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#parsing-errors

use Test;
use JSON::Tiny;

use CSS::Writer;

for 't/serialize.json'.IO.lines {

    next if .substr(0,2) eq '//';

    my $test = from-json($_);
    my $css = $test<css>;
    my $ast = $test<ast>;
    my $opt = $test<opt> // {};

    if my $skip = $opt<skip> {
        skip $skip;
        next;
    }

    is CSS::Writer.write( $ast ), $css, "serialize {$ast.keys} to: $css"
        or diag {ast => $ast}.perl;
}

done;
