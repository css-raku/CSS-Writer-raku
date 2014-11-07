use v6;

use CSS::Grammar::CSS3;

class CSS::Writer::Values {

    use CSS::Grammar::AST :CSSValue;

    method write-num( Numeric $num, Str $units? ) {
        my $int = $num.Int;
        return ($int == $num ?? $int !! $num) ~ ($units.defined ?? $units.lc !! '');
    }

    method write-string( Str $str) {
        [~] ("'",
             $str.comb.map({
                 when /<CSS::Grammar::CSS3::stringchar-regular>/ {$_}
                 when "'" {"\\'"}
                 default { .ord.fmt("\\%X ") }
             }),
             "'");
    }

    method write-ident( Str $ident ) {
        $ident;
        [~] $ident.comb.map({
            when /<CSS::Grammar::CSS3::nmreg>/    { $_ };
            when /<CSS::Grammar::CSS3::nonascii>/ { $_ };
            default { .ord.fmt("\\%X ") }
        });
    }

    method write-op(Str $_) {
        when ',' {", "}
        default  {$_}
    }

    method write-expr( $terms ) {
        [~] @$terms.map({
            my ($name, $val, @_guff) = .kv;
            die "malformed term: {.perl}"
                if @_guff;
            given $name {
                when 'operator' {$.write-op($val)}
                default     {$.write($val)}
            }
        })
    }

    proto write-value(Str $;; Any $ast, Str $units? --> Str) {*}


    multi method write-value( CSSValue::ColorComponent, Hash $ast, 'rgb' ) {
        sprintf 'rgb(%d, %d, %d)', $ast<r g b>;
    }

    multi method write-value( CSSValue::ColorComponent, Any $ast, 'rgba' ) {

        return $.write-value( CSSValue::ColorComponent, $ast, 'rgb' )
            if $ast<a> == 1.0;

        sprintf 'rgba(%d, %d, %d, %s)', $ast<r g b a>;
    }

    multi method write-value( CSSValue::Component;; Str $ast ) {
        ...
    }

    multi method write-value( CSSValue::IdentifierComponent;; Str $ast, Any $_units ) {
        $.write-ident( $ast );
    }

    multi method write-value( CSSValue::KeywordComponent;; Str $ast, Any $_units ) {
        $ast;
    }

    multi method write-value( CSSValue::LengthComponent;; Numeric $ast, Str $units? ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::Map;; Any $ast, Str $units? ) {
        ...
    }

    multi method write-value( CSSValue::PercentageComponent;; Numeric $ast, Any $_units ) {
        $.write-num( $ast, '%' );
    }

    multi method write-value( CSSValue::Property;; Any $ast, Any $_units? ) {
        sprintf '%s : %s%s;', $.write-ident( $ast<property> ), $.write-expr( $ast<expr> ), $ast<prio> ?? ' !important' !! '';
    }

    multi method write-value( CSSValue::PropertyList;; Any $ast, Any $_units? ) {
        'tba property-list';
    }

    multi method write-value( CSSValue::StringComponent;; Str $ast, Any $_units? ) {
        $.write-string($ast);
    }

    multi method write-value( CSSValue::StyleDeclaration;; Any $ast, Any $units? ) {
        ...
    }

    multi method write-value( CSSValue::URLComponent;; Str $ast, Any $units? ) {
        sprintf "url(%s)", $.write-string( $ast );
    }

    multi method write-value( CSSValue::NumberComponent;; Numeric $ast, Any $units? ) {
        $.write-num( $ast );
    }

    multi method write-value( CSSValue::IntegerComponent;; Int $ast, Str $units? ) {
        $.write-num( $ast );
    }

    multi method write-value( CSSValue::AngleComponent;; Numeric $ast, Str $units ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::FrequencyComponent;; Numeric $ast, Str $units ) {
        # 'The frequency in hertz serialized as per <number> followed by the literal string "hz"'
        # - http://dev.w3.org/csswg/cssom/#serializing-css-values
        return $units eq 'khz'
            ?? $.write-num($ast * 1000, 'hz')
            !! $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::FunctionComponent;; List $ast, Any $units? ) {
        my ($name, $params) = @$ast; 
        sprintf '%s(%s)', $.write-ident( $name<ident> ), $.write-expr( $params<args> );
    }

    multi method write-value( CSSValue::ResolutionComponent;; Numeric $ast, Str $units ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::TimeComponent;; Numeric $ast, Str $units ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( Any $type, Any $ast, Any $units ) is default {
        die "unable to find delegate for type: {$type.perl}, units: {$units.perl}"
    }

}
