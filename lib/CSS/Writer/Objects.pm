use v6;

class CSS::Writer::Objects {

    use CSS::AST :CSSObject;
    proto write-object( Str $type, Any $ast, Str $units --> Str ) {*}

    multi method write-object( CSSObject::CharsetRule, Str $ast ) {
        [~] '@charset ', $.write( 'string' => $ast ), ';'
    }

    multi method write-object( CSSObject::FontFaceRule, Any $ast ) {
        ...
    }

    multi method write-object( CSSObject::GroupingRule, Any $ast ) {
        ...
    }

    multi method write-object( CSSObject::ImportRule, Hash $ast ) {
        [~] '@import ', join(' ', <url media-list>.grep({ $ast{$_}:exists }).map({ $.write( $ast, :token($_) ) })), ';';
    }

    multi method write-object( CSSObject::MarginRule, Any $ast ) {
        ...
    }

    multi method write-object( CSSObject::MediaRule, Hash $ast ) {
        [~] '@media ', <media-list rule-list>.grep({ $ast{$_}:exists }).map({ $.write( $ast, :token($_) ) });
    }

    multi method write-object( CSSObject::NamespaceRule, Any $ast ) {
        ...
    }

    multi method write-object( CSSObject::PageRule, Any $ast ) {
        [~] '@page ', <pseudo-elem declarations>.grep({ $ast{$_}:exists }).map({ $.write( $ast, :token($_) ) });
    }

    multi method write-object( CSSObject::RuleSet, Hash $ast ) {
        sprintf "%s %s", $.write($ast, :token<selectors>), $.write($ast, :token<declarations>);
    }

    multi method write-object( CSSObject::RuleList, List $ast ) {
        ' { ' ~ join("\n", $ast.map: { $.write($_) } ) ~ '}';
    }

    multi method write-object( CSSObject::StyleSheet, List $ast ) {
        join("\n\n", $ast.map({ $.write( $_ ) }) );
    }

    multi method write-object( Any $type, Any $ast ) is default {
        die "unable to handle type: {$type.perl}, ast: {$ast.perl}"
    }

}
