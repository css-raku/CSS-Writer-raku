use v6;


class CSS::Writer::Values {

    use CSS::Grammar::CSS3;
    use CSS::AST :CSSValue;

    multi method write-num( 1, 'em' ) { 'em' }
    multi method write-num( 1, 'ex' ) { 'ex' }

    multi method write-num( Numeric $num, Any $units? ) {
        my $int = $num.Int;
        return ($int == $num ?? $int !! $num) ~ ($units.defined ?? $units.lc !! '');
    }

    method write-string( Str $str) {
        [~] ("'",
             $str.comb.map({
                 when /<CSS::Grammar::CSS3::stringchar-regular>|\"/ {$_}
                 when /<CSS::Grammar::CSS3::regascii>/ {'\\' ~ $_}
                 default { .ord.fmt("\\%X ") }
             }),
             "'");
    }

    proto write-color(List $ast, Str $units --> Str) {*}

    multi method write-color(List $ast, 'rgb') {
        sprintf 'rgb(%s, %s, %s)', $ast.map: { $.write( $_ )};
    }

    multi method write-color( List $ast, 'rgba' ) {

        return $.write-color( [ $ast[0..2] ], 'rgb' )
            if $ast[3]<num> == 1.0;

        sprintf 'rgba(%s, %s, %s, %s)', $ast.map: {$.write( $_ )};
    }

    multi method write-color(List $ast, 'hsl') {
        sprintf 'hsl(%s, %s, %s)', $ast.map: {$.write( $_ )};
    }

    multi method write-color(List $ast, 'hsla') {
        sprintf 'hsla(%s, %s, %s, %s)', $ast.map: {$.write( $_ )};
    }

    multi method write-color( Any $color, Any $units ) is default {
        die "unable to handle color: {$color.perl}, units: {$units.perl}"
    }

    proto write-value(Str $, Any $ast, :$units? --> Str) {*}

    multi method write-value( CSSValue::ColorComponent, List $ast, :$units ) {
        $.write-color( $ast, $units);
    }

    multi method write-value( CSSValue::Component, Str $ast ) {
        ...
    }

    multi method write-value( CSSValue::IdentifierComponent, Str $ast) {

        my $ident = $ast;
        my $pfx = $ident ~~ s/^"-"// ?? '-' !! '';
        my $minus = $ident ~~ s/^"-"// ?? '\\-' !! '';
        [~] $pfx, $minus, $.write( 'name' => $ident);
    }

    multi method write-value( CSSValue::NameComponent, Str $ast) {

        [~] $ast.comb.map({
            when /<CSS::Grammar::CSS3::nmreg>/    { $_ };
            when /<CSS::Grammar::CSS3::regascii>/ { '\\' ~ $_ };
            default                               { .ord.fmt("\\%X ") }
        });
    }

    multi method write-value( CSSValue::NamespacePrefixComponent, Str $_ ) {
        when ''  {''}   # no namespace
        when '*' {'*'}  # wildcard namespace
        default  { $.write-value( CSSValue::IdentifierComponent, $_ ) }
    }

    multi method write-value( CSSValue::ElementNameComponent, Str $_ ) {
        when '*' {'*'}  # wildcard namespace
        default  { $.write-value( CSSValue::IdentifierComponent, $_ ) }
    }

    multi method write-value( CSSValue::AtKeywordComponent, Str $ast ) {
        '@' ~ $.write( CSSValue::IdentifierComponent => $ast );
    }

    multi method write-value( CSSValue::KeywordComponent, Str $ast ) {
        $ast;
    }

    multi method write-value( CSSValue::LengthComponent, Numeric $ast, Any :$units? ) {
        $.write-num( $ast, $units);
    }

    multi method write-value( CSSValue::Map, Any $ast ) {
        ...
    }

    multi method write-value(CSSValue::OperatorComponent, Str $ast) {
        $ast.lc;
    }

    multi method write-value( CSSValue::PercentageComponent, Numeric $ast ) {
        $.write-num( $ast, '%' );
    }

    multi method write-value( CSSValue::Property, Hash $ast, :$indent=0 ) {
        my $prio = $ast<prio> ?? ' !important' !! '';
        my $expr = $ast<expr> ?? sprintf ': %s', $.write( $ast, :token<expr> ) !! '';
        [~] (' ' x $indent), $.write( $ast, :token<ident> ), $expr, $prio, ';';
    }

    multi method write-value( CSSValue::PropertyList, List $ast ) {
        sprintf "\{\n%s\n\}", join("\n", $ast.map: {$.write-value( CSSValue::Property, $_, :indent(2) )});
    }

    multi method write-value( CSSValue::StringComponent, Str $ast ) {
        $.write-string($ast);
    }

    multi method write-value( CSSValue::URLComponent, Str $ast ) {
        sprintf "url(%s)", $.write-string( $ast );
    }

    multi method write-value( CSSValue::NumberComponent, Numeric $ast ) {
        $.write-num( $ast );
    }

    multi method write-value( CSSValue::IntegerComponent, Int $ast ) {
        $.write-num( $ast );
    }

    multi method write-value( CSSValue::AngleComponent, Numeric $ast, Any :$units? ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::FrequencyComponent, Numeric $ast, Any :$units? ) {
        # 'The frequency in hertz serialized as per <number> followed by the literal string "hz"'
        # - http://dev.w3.org/csswg/cssom/#serializing-css-values
        return $units eq 'khz'
            ?? $.write-num($ast * 1000, 'hz')
            !! $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::FunctionComponent, Hash $ast ) {
        sprintf '%s(%s)', $.write( $ast, :token<ident> ), do {
            when $ast<args>:exists {$.write( $ast, :token<args> )}
            when $ast<expr>:exists {$.write( $ast, :token<expr> )}
            default {''};
        }
    }

    multi method write-value( CSSValue::ArgumentListComponent, List $args ) {
        join(', ', @$args.map({ $.write($_) }) );
    }

    multi method write-value( CSSValue::ExpressionComponent, List $terms ) {
        my $sep = '';

        [~] @$terms.map( -> $term {

            $sep = '' if $term<op> && $term<op>;
            my $out = $sep ~ $.write($term);
            $sep = $term<op> && $term<op> ne ',' ?? '' !! ' ';

            $out;
        });
    }

    multi method write-value( CSSValue::ResolutionComponent, Numeric $ast, Any :$units? ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::TimeComponent, Numeric $ast, Any :$units? ) {
        $.write-num( $ast, $units );
    }

    multi method write-value( CSSValue::UnicodeRangeComponent, List $ast ) {

        my $range;
        my ($lo, $hi) = @$ast.map: {sprintf("%X", $_)};

        if !$lo eq $hi {
            # single value
            $range = sprintf '%x', $lo;
        }
        else {
            my $lo-sub = $lo.subst(/0+$/, '');
            my $hi-sub = $hi.subst(/F+$/, '');

            if $lo-sub eq $hi-sub {
                $range = $lo-sub  ~ ('?' x ($lo.chars - $lo-sub.chars));
            }
            else {
                $range = [~] $lo, '-', $hi;
            }
        }

        'U+' ~ $range;
    }

    multi method write-value( CSSValue::QnameComponent, Hash $ast ) {
        my $out = $.write($ast, :token<element-name>);
        $out = [~] $.write($ast, :token<ns-prefix>), '|', $out
            if $ast<ns-prefix>:exists;
        $out;
    }

    multi method write-value( Any $type, Any $ast ) is default {
        die "unable to handle value type: {$type.perl}, ast: {$ast.perl}"
    }

}
