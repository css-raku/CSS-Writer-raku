use v6;

class CSS::Writer {...}

use CSS::Grammar::AST;
use CSS::Writer::Objects;
use CSS::Writer::Values;

class CSS::Writer is CSS::Writer::Objects is CSS::Writer::Values {

    method write($ast, :$item) {

        my $token;

        return '' unless $ast.defined;

        if $item {
            my $data = $ast{ $item }
                // die "node does not contain: $item";
            $token = CSS::Grammar::AST.token( $data, :type($item));
        }
        elsif $ast.can('type') {
            # already tokenised
            $token = $ast;
        }
        elsif ($ast.isa(Hash) || $ast.isa(Pair)) {
            # it's a token represented by a type/value pair
            my ($type, $data, @_guff) = $ast.kv;
                die "node contains multple tokens: {$ast.keys}"
                    if @_guff;

            $token = CSS::Grammar::AST.token( $data, :$type);
        }

        unless $token.defined {
            note "unable to determine token: $ast";
            return '';
        }

        my $type;
        my $type-name := ~$token.type;
        my $units := $token.units;

        if $type = CSS::Grammar::AST::CSSObject( $type-name ) {
            $.write-object( $type, $token, :$units );
        }
        elsif $type = CSS::Grammar::AST::CSSValue( $type-name ) {
            $.write-value( $type, $token, :$units );
        }
        else {
            note "unknown type: $type";
            '';
        }
    }

}
