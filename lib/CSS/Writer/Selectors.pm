use v6;

use CSS::Grammar::CSS3;

class CSS::Writer::Selectors {

    use CSS::Grammar::AST :CSSSelector;

    multi method write-selector( CSSSelector::SelectorList, List $ast ) {
        join(', ',  $ast.map({ $.write( $_ ) }) );
    }

    multi method write-selector( CSSSelector::Selector, List $ast ) {
        join(' ',  $ast.map({ $.write( $_ ) }) );
    }

    multi method write-selector( CSSSelector::SelectorComponent, List $ast ) {
        [~] $ast.map({ $.write( $_ ) });
    }

    multi method write-selector( CSSSelector::Combinator, Str $ast ) {
        $ast.lc;
    }

    multi method write-selector( CSSSelector::PseudoClass, Str $ast ) {
        ':' ~ $.write( 'ident' => $ast );
    }

    multi method write-selector( CSSSelector::PseudoFunction, Hash $ast ) {
        ':' ~ $.write( 'func' => $ast );
    }

    multi method write-selector( CSSSelector::Class, Str $ast ) {
        '.' ~ $.write( 'ident' => $ast );
    }

    multi method write-selector( CSSSelector::AttributeSelector, List $ast ) {
        [~] '[', $ast.map({ $.write( $_ ) }), ']';
    }

    multi method write-selector( CSSSelector::AttributeOp, Str $ast ) {
        $ast.lc;
    }

    multi method write-selector( CSSSelector::Id, Str $ast ) {
        '#' ~ $.write( 'ident' => $ast );
    }

    multi method write-selector( CSSSelector::MediaList, List $ast ) {
        join(' ', $ast.map({ $.write( $_ ) }) );
    }

    multi method write-selector( CSSSelector::MediaQuery, List $ast ) {
        join(' ', $ast.map({ $.write( $_ ) }) );
    }

    multi method write-selector( Any $type, Any $ast ) is default {
        die "unable to handle value type: {$type.perl}, ast: {$ast.perl}"
    }

}
