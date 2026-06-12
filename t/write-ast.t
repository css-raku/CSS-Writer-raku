#!/usr/bin/env raku

# these tests check for conformance with error handling as outline in
# http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#parsing-errors

use Test;
use JSON::Fast;

use CSS::Writer;

my CSS::Writer $css-writer .= new;
my CSS::Writer $css-writer_2 .= new( :color-names );
my CSS::Writer $css-writer_3 .= new( :color-values );
my CSS::Writer $css-writer_4 .= new( :xml );

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
        or diag {node => %node}.raku;

    if my $color-masks-css = $test<color-masks> {
        temp $css-writer.color-masks = True;
        is $css-writer.write( |%node ), $color-masks-css, "serialize (:color-masks) {%node.keys} to: $color-masks-css"
            or diag {node => %node}.raku;
    }

    if my $xml-css = $test<xml-css> {
        is $css-writer_4.write( |%node ), $xml-css, "serialize (:xml) {%node.keys} to: $xml-css"
            or diag {node => %node}.raku;
    }

    if my $color-values-css = $test<color-values> {
        is $css-writer_3.write( |%node ), $color-values-css, "serialize (:color-values) {%node.keys} to: $color-values-css"
            or diag {node => %node}.raku;
    }

}

done-testing;
