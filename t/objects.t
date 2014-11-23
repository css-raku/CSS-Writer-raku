#!/usr/bin/env perl6

# these tests check for conformance with error handling as outline in
# http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#parsing-errors

use Test;
use JSON::Tiny;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::Test;
use CSS::Module::CSS3;
use CSS::Drafts::CSS3;

use CSS::Writer;

my $grammar-actions = CSS::Grammar::Actions.new(:verbose);
my $module-actions = CSS::Module::CSS3::Actions.new(:verbose);
my $draft-actions = CSS::Drafts::CSS3::Actions.new(:verbose);

for 't/objects.json'.IO.lines {

    next if .substr(0,2) eq '//';

    my ($rule, $input, $opts) = @( from-json($_) );
    $opts //= {out => $input};

    for grammar => [CSS::Grammar::CSS3, $grammar-actions],
        module  => [CSS::Module::CSS3, $module-actions],
        drafts  => [CSS::Drafts::CSS3, $draft-actions] {

        my ($suite, $a) = .kv;
        my ($class, $actions) = @$a;

        my %expected = %$opts, %( $opts{$suite} // {} );

        if my $skip = %expected<skip> {
            skip "$suite $rule - $skip";
            next;
        }

        %expected<ast> = Any;
        my $expected-out = %expected<out> // $input;
        my $todo = %expected<todo>:delete;

        temp $/ = CSS::Grammar::Test::parse-tests($class, $input, :$rule, :$actions, :%expected, :$suite);

        my @warnings = $actions.warnings;

        my $test-name = "$suite $rule round trip: $input";

        todo( $todo ) if $todo;
        is CSS::Writer.write( $/.ast ), $expected-out, $test-name
            or diag {suite => $suite, parse => ~$/, ast => $/.ast}.perl;
    }
}

done;
