use v6;

class CSS::Writer {...}

use CSS::Grammar::AST;
use CSS::Writer::Objects;
use CSS::Writer::Values;

class CSS::Writer is CSS::Writer::Objects is CSS::Writer::Values {

    method write($ast) {
        my $type-val;
        my $units;
        my $data;

        return '' unless $ast.defined;

        if $ast.can('type') {
            # compact token, performing the CSS::Grammar::AST::Token rule
            $type-val := ~$ast.type;
            $units := $ast.units;
            $data := $ast;
        }

        return '' unless $type-val.defined;

        my $type;
        my $writer-class;

        if $type = CSS::Grammar::AST::CSSObject( $type-val ) {
            $.write-object( $type, $data, :$units );
        }
        elsif $type = CSS::Grammar::AST::CSSValue( $type-val ) {
            $.write-value( $type, $data, :$units );
        }
        else {
            note "unknwon type: $type";
            '';
        }
    }

}
