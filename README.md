perl6-CSS-Writer
================
*** Under Construction ***

Description
===========

AST writer/serializer module. Compatible with CSS:Module and CSS::Grammar produced ASTs.
Forward compatable with CSS::Drafts.

Based on the objects, values and serialization rules described in http://dev.w3.org/csswg/cssom/

Examples
========

serialize a declaration list to CSS
-----------------------------------
    use CSS::Writer;
    my $css-writer = CSS::Writer.new( :terse );
    say $css-writer.write-node( :declarations[
                               { :ident<font-size>, :expr[ :pt(12) ] },
                               { :ident<color>,    :expr[ :ident<white> ] },
                               { :ident<z-index>,  :expr[ :num(-9) ] },
                          ] );

    # output: { font-size: 12pt; color: white; z-index: -9; }


tidy and minimise CSS
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

    say $css-writer.write-node( :stylesheet($ast) );

    # output: h1 { color: red; z-index: -3; }

