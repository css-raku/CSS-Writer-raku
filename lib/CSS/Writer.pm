use v6;

use CSS::Writer::Objects;
use CSS::Writer::Values;
use CSS::Writer::Selectors;

class CSS::Writer
    is CSS::Writer::Objects
    is CSS::Writer::Values
    is CSS::Writer::Selectors {

    use CSS::AST;

    method write($ast, :$token) {

        my $node;

        return '' unless $ast.defined;

        if $token {
            my $data = $ast{ $token }
                // die "node does not contain: $token";
            $node = CSS::AST.token( $data, :type($token));
        }
        elsif $ast.can('type') {
            # already tokenised
            $node = $ast;
        }
        elsif ($ast.isa(Hash) || $ast.isa(Pair)) {
            # it's a token represented by a type/value pair
            my ($type, $data, @_guff) = $ast.kv;
            die "empty AST node" unless $type;
            die "AST node contains multple tokens: {$ast.keys}"
                if @_guff;    

            $type = $type.subst(/':'.*/, '');

            $node = CSS::AST.token( $data, :$type);
        }

        unless $node.defined {
            note "unable to determine token: {$ast.perl}";
            return '';
        }

        my $type-name := ~$node.type
            or die "untyped object: {$node.perl}";
        my $units := $node.units;

        my $type = CSS::AST::CSSObject( $type-name )
            // CSS::AST::CSSValue( $type-name )
            // CSS::AST::CSSSelector( $type-name );

        if $type {
            given $type {
                when CSS::AST::CSSValue {
                    $.write-value( $type, $node, :$units );
                }
                when CSS::AST::CSSObject {
                    $.write-object( $type, $node, :$units );
                }
                when CSS::AST::CSSSelector {
                    $.write-selector( $type, $node, :$units );
                }
                default {die "unhandled type: $type"}
            }
        }
        else {
            note "unknown type: $type-name";
            '';
        }
    }

}
