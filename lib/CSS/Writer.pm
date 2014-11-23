use v6;

class CSS::Writer {...}

use CSS::Grammar::AST;
use CSS::Writer::Objects;
use CSS::Writer::Values;
use CSS::Writer::Selectors;

class CSS::Writer
    is CSS::Writer::Objects
    is CSS::Writer::Values
    is CSS::Writer::Selectors {

    method write($ast, :$token) {

        my $node;

        return '' unless $ast.defined;

        if $token {
            my $data = $ast{ $token }
                // die "node does not contain: $token";
            $node = CSS::Grammar::AST.token( $data, :type($token));
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

            $node = CSS::Grammar::AST.token( $data, :$type);
        }

        unless $node.defined {
            note "unable to determine token: {$ast.perl}";
            return '';
        }

        my $type-name := ~$node.type
            or die "untyped object: {$node.perl}";
        my $units := $node.units;

        my $type = CSS::Grammar::AST::CSSObject( $type-name )
            // CSS::Grammar::AST::CSSValue( $type-name )
            // CSS::Grammar::AST::CSSSelector( $type-name );

        if $type {
            given $type {
                when CSS::Grammar::AST::CSSValue {
                    $.write-value( $type, $node, :$units );
                }
                when CSS::Grammar::AST::CSSObject {
                    $.write-object( $type, $node, :$units );
                }
                when CSS::Grammar::AST::CSSSelector {
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
