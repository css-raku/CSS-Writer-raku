# perl6-CSS-Writer

AST writer/serializer module. Compatible with CSS:Module and CSS::Grammar ASTs.

## Examples


#### Serialize a list of declarations; converting named colors to RGB masks 
    use CSS::Writer;
    my $css-writer = CSS::Writer.new( :terse, :color-values, :color-masks );
    say $css-writer.write( :declarations[
                               { :ident<font-size>, :expr[ :pt(12) ] },
                               { :ident<color>,     :expr[ :ident<white> ] },
                               { :ident<z-index>,   :expr[ :num(-9) ] },
                          ] );

    # output: { font-size: 12pt; color: #FFF; z-index: -9; }


#### Tidy and reduce size of CSS
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


## Writer Options

- **`:color-masks`** Prefer hex mask notation for RGB values, .e.g. `#0085FF` instead of `rgb(0, 133, 255)`

- **`:color-names`** Convert RGB values to color names

- **`:color-values`** Convert color names to RGB values

- **`:terse`** write each stylesheet element on a single line, without indentation.

## Usage Notes

- The initial version CSS::Writer is based on the objects, values and serialization rules described in http://dev.w3.org/csswg/cssom/.






