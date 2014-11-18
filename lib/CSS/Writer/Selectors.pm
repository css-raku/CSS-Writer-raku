use v6;

use CSS::Grammar::CSS3;

class CSS::Writer::Selectors {

    use CSS::Grammar::AST :CSSSelector;

    multi method write-selector( CSSSelector::PseudoFunction, Hash $ast ) {
        ':' ~ $.write( 'func' => $ast );
    }

    multi method write-selector( CSSSelector::Class, Str $ast ) {
        '.' ~ $.write( 'ident' => $ast );
    }

    multi method write-selector( CSSSelector::Id, Str $ast ) {
        '#' ~ $.write( 'ident' => $ast );
    }

    multi method write-selector( Any $type, Any $ast ) is default {
        die "unable to handle value type: {$type.perl}, ast: {$ast.perl}"
    }


}
