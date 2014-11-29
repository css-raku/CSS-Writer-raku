perl6-CSS-Writer
================

AST writer/serializer module. Compatible with CSS:Module and CSS::Grammar ASTs.

Examples
========

Serialize a list of declarations
--------------------------------
    use CSS::Writer;
    my $css-writer = CSS::Writer.new( :terse );
    say $css-writer.write( :declarations[
                               { :ident<font-size>, :expr[ :pt(12) ] },
                               { :ident<color>,     :expr[ :ident<white> ] },
                               { :ident<z-index>,   :expr[ :num(-9) ] },
                          ] );

    # output: { font-size: 12pt; color: white; z-index: -9; }


Tidy and minimise CSS
---------------------
    use CSS::Writer;
    use CSS::Grammar::CSS3;

    sub css-to-ast($css) {
        use CSS::Grammar::CSS3;
        use CSS::Grammar::Actions;
        my $actions = CSS::Grammar::Actions.new;
        CSS::Grammar::CSS3.parse($css, :$actions)
           or die "unable to parse: $css";

        return $/.ast
    }

    my $css-writer = CSS::Writer.new( :terse );
    my $ast = css-to-ast( 'H1{  cOlor: RED; z-index  : -3}' );

    say $css-writer.write( :stylesheet($ast) );

    # output: h1 { color: red; z-index: -3; }


Usage Notes
============

-- The initial version CSS::Writer is based on the objects, values and serialization rules described in http://dev.w3.org/csswg/cssom/.

-- colors are currently serialized using `rgb(...)` notation, etc. Options for `#aabbcc` and named color output will be added shortly.





