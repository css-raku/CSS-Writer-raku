use v6;
use CSS::Grammar::AST :CSSObject;

class CSS::Writer::Objects {

    proto write-object( Str $type, Any $ast, Str $units --> Str ) {*}

    multi method write-object( CSSObject::CharsetRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::FontFaceRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::GroupingRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::ImportRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::MarginRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::MediaRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::NamespaceRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::PageRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::Rule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::RuleList;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::StyleDeclaration;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::StyleRule;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( CSSObject::StyleSheet;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-object( Any $type, Any $ast, Any $units ) is default {
        die "unable to find delegate for type: {~$type}, units: $units"
    }

}
