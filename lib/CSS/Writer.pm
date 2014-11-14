use v6;

class CSS::Writer {...}

use CSS::Grammar::AST;
use CSS::Writer::Objects;
use CSS::Writer::Values;

class CSS::Writer is CSS::Writer::Objects is CSS::Writer::Values {

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
                die "node contains multple tokens: {$ast.keys}"
                    if @_guff;

            $node = CSS::Grammar::AST.token( $data, :$type);
        }

        unless $node.defined {
            note "unable to determine token: $ast";
            return '';
        }

        my $type;
        my $type-name := ~$node.type;
        my $units := $node.units;

        if $type = CSS::Grammar::AST::CSSObject( $type-name ) {
            $.write-object( $type, $node, :$units );
        }
        elsif $type = CSS::Grammar::AST::CSSValue( $type-name ) {
            $.write-value( $type, $node, :$units );
        }
        else {
            note "unknown type: $type";
            '';
        }
    }

}
