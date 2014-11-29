use CSS::Writer;

use Test;

my $writer = CSS::Writer.new( :terse );

for CSS::Writer.^methods.map({.candidates}).map({.WHY}).grep({.defined}).map({.Str}) -> $doc {
    if $doc ~~ /:s $<output>=[.*?] ':=' $<synopsis>=[.*?] $/ {
        my $expected = ~$<output>;
        for split(/ \s+ or \s+ /, $<synopsis>) -> $code-sample {
            my $code = $code-sample.subst( / '$.' /, '$writer.');
            my $out;
            lives_ok { $out = EVAL $code }, "compiles: $code"
                and is $out, $expected, "output is $expected";
        }
    }
}


done();
