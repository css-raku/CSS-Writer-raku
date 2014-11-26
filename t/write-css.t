#!/usr/bin/env perl6

# these tests check for conformance with error handling as outline in
# http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#parsing-errors

use Test;
use JSON::Tiny;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::Test;
use CSS::Writer;

my $actions = CSS::Grammar::Actions.new();
my $css-writer = CSS::Writer.new;

for 't/write-css.json'.IO.lines {

    next if .substr(0,2) eq '//';

    my ($rule, $css, $opts) = @( from-json($_) );
    $opts //= {};
    my %expected = %$opts;

    if my $skip = %expected<skip> {
        skip "$rule - $skip";
        next;
    }

    %expected<ast> = Any;
    my $expected-out = %expected<out> // $css;
    my $todo = %expected<todo>:delete;

    temp $/ = CSS::Grammar::Test::parse-tests(CSS::Grammar::CSS3, $css, :$rule, :$actions, :%expected, :suite($rule) );

    my $ast = $/.ast;
    $ast = {$rule => $ast} if $ast.defined && !$ast.isa('Hash');

    my $test-name = "css3 $rule round trip: " ~ $css.subst(/\n.*/, ' ...');

    todo( $todo ) if $todo;
    is $css-writer.write( $ast ), $expected-out, $test-name
        or diag {suite => $rule, parse => ~$/, ast => $/.ast}.perl;

    if my $terse-expected-out = %expected<terse> {
        temp $css-writer.terse = True;
        is $css-writer.write( $ast ), $terse-expected-out, "$test-name - :terse"
            or diag {suite => $rule, parse => ~$/, ast => $/.ast}.perl;
    }
}

done;
