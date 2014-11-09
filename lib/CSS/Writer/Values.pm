use v6;

use CSS::Grammar::CSS3;

class CSS::Writer::Values {

    use CSS::Grammar::AST :CSSValue;

    multi method write-num( 1, 'em' ) { 'em' }
    multi method write-num( 1, 'ex' ) { 'ex' }

    multi method write-num( Numeric $num, Str $units? ) {
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
        my $space = 0;
        [~] @$terms.map({
            my ($name, $val, @_guff) = .kv;
            die "malformed term: {.perl}"
                if @_guff;
            given $name {
                when 'operator' {$space = 0; $.write-op($val)}
                default         {($space++ ?? ' ' !! '') ~ $.write($val)}
            }
        })
    }

    proto write-color(Hash $ast, Str $units --> Str) {*}

    multi method write-color(Hash $ast, 'rgb') {
        sprintf 'rgb(%d, %d, %d)', $ast<r g b>;
    }

    multi method write-color( Hash $ast, 'rgba' ) {

        return $.write-color( $ast, 'rgb' )
            if $ast<a> == 1.0;

        sprintf 'rgba(%d, %d, %d, %s)', $ast<r g b a>;
    }

    multi method write-color( Any $color, Any $units ) is default {
        die "unable to handle color: {$color.perl}, units: {$units.perl}"
    }

    proto write-value(Str $;; Any $ast, :$units? --> Str) {*}

    multi method write-value( CSSValue::ColorComponent, Hash $ast, :$units ) {
        note {color => $ast, units => $units}.perl;
        $.write-color( $ast, $units);
    }

    multi method write-value( CSSValue::Component;; Str $ast ) {
        ...
    }

    multi method write-value( CSSValue::IdentifierComponent;; Str $ast) {
        $.write-ident( $ast );
    }

    multi method write-value( CSSValue::KeywordComponent;; Str $ast ) {
        $ast;
    }

    multi method write-value( CSSValue::LengthComponent;; Numeric $ast, Str :$units ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::Map;; Any $ast ) {
        ...
    }

    multi method write-value( CSSValue::PercentageComponent;; Numeric $ast ) {
        $.write-num( $ast, '%' );
    }

    multi method write-value( CSSValue::Property;; Hash $ast, :$indent=0 ) {
        sprintf '%s%s: %s%s;', ' ' x $indent, $.write-ident( $ast<property> ), $.write-expr( $ast<expr> ), $ast<prio> ?? ' !important' !! '';
    }

    multi method write-value( CSSValue::PropertyList;; List $ast ) {
        join("\n", $ast.map: {$.write-value( CSSValue::Property, $_, :indent(2) )});
    }

    multi method write-value( CSSValue::StringComponent;; Str $ast ) {
        $.write-string($ast);
    }

    multi method write-value( CSSValue::StyleDeclaration;; Any $ast ) {
        ...
    }

    multi method write-value( CSSValue::URLComponent;; Str $ast ) {
        sprintf "url(%s)", $.write-string( $ast );
    }

    multi method write-value( CSSValue::NumberComponent;; Numeric $ast ) {
        $.write-num( $ast );
    }

    multi method write-value( CSSValue::IntegerComponent;; Int $ast ) {
        $.write-num( $ast );
    }

    multi method write-value( CSSValue::AngleComponent;; Numeric $ast, Str :$units ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::FrequencyComponent;; Numeric $ast, Str :$units ) {
        # 'The frequency in hertz serialized as per <number> followed by the literal string "hz"'
        # - http://dev.w3.org/csswg/cssom/#serializing-css-values
        return $units eq 'khz'
            ?? $.write-num($ast * 1000, 'hz')
            !! $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::FunctionComponent;; List $ast ) {
        my ($name, $params) = @$ast; 
        sprintf '%s(%s)', $.write-ident( $name<ident> ), $.write-expr( $params<args> );
    }

    multi method write-value( CSSValue::ResolutionComponent;; Numeric $ast, Str :$units ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::TimeComponent;; Numeric $ast, Str :$units ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( Any $type, Any $ast ) is default {
        die "unable to handle value type: {$type.perl}, ast: {$ast.perl}"
    }

}
