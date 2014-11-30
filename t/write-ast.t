#!/usr/bin/env perl6

# these tests check for conformance with error handling as outline in
# http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#parsing-errors

use Test;
use JSON::Tiny;

use CSS::Writer;

my $css-writer = CSS::Writer.new;

for 't/write-ast.json'.IO.lines {

    next if .substr(0,2) eq '//';

    my $test = from-json($_);
    my $css = $test<css>;
    my %node = %( $test<ast> );
    my $opt = $test<opt> // {};

    if my $skip = $opt<skip> {
        skip $skip;
        next;
    }

    is $css-writer.write( |%node ), $css, "serialize {%node.keys} to: $css"
        or diag {node => %node}.perl;

    if my $rgb-masks-css = $test<rgb-masks> {
        temp $css-writer.rgb-masks = True;
        is $css-writer.write( |%node ), $rgb-masks-css, "serialize (color-masks) {%node.keys} to: $rgb-masks-css"
            or diag {node => %node}.perl;
    }
}

done;
