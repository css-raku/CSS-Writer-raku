unit class CSS::Writer:ver<0.2.10>;

use CSS::Grammar::Defs;
use CSS::Grammar::CSS3;
use Color::Names::CSS3 :colors;

has Str $.indent is rw = '';
has Bool $.pretty is rw;
has Bool $.color-masks is rw;
has %!color-names;    #- maps rgb hex codes to named colors
has %!color-values;   #- maps color names to rgb values
has $.ast is rw;

sub tidy-color-name($name) { $name.subst(/'-'.*/, '') }
constant CSS3-Colors = %( COLORS.map: { tidy-color-name(.key) => .value } );

sub build-color-names(%colors) {
    %(
        %colors.kv.map: -> Str $name, %foo ( :name($), :@rgb! ) {
            my $hex = 256 * (256 * @rgb[0]  +  @rgb[1])  +  @rgb[2];
            $hex => $name;
        }
    )
}

sub build-color-values(%colors) {
    %(
        %colors.kv.map: -> Str $name, % ( :name($), :@rgb! ) {

            with $name.index("gray") {
                my $name-uk = $name;
                $name-uk.substr-rw($_, 4) = 'grey';
                $name|$name-uk => @rgb;
            }
            else {
                $name => @rgb;
            }
        }
    );
}

my subset BoolOrHash where Bool|Hash;
submethod TWEAK(BoolOrHash :$color-names = Bool, BoolOrHash :$color-values = Bool,
                Bool :$terse, # To be deprecated
               ) {

    $!pretty //= !$terse;
    die ":color-names and :color-values are mutually exclusive options"
        if $color-names && $color-values;

    with $color-names {

        when Bool {%!color-names := build-color-names( CSS3-Colors )
                            if .so; }
        when Hash { %!color-names := build-color-names( $_ ) }
    }
    else {
        with $color-values {
            when Bool { %!color-values := build-color-values( CSS3-Colors )
                            if .so; }
            when Hash { %!color-values := %$_ }
        }
    }

    $!color-masks //= True
        unless $!pretty || %!color-names || %!color-values;

}

method Str {
    with $.ast {
        $.write( $_ );
    }
    else {
        nextsame;
    }
}

proto method write(|c --> Str) {*}

#| @page   := $.write-at-keyw( 'page' )
method write-at-keyw( Str $_ ) {
    '@' ~ $.write-ident: $_;
}

#| 'foo', bar, 42 := $.write-args: [ :string<foo>, :ident<bar>, :num(42) ]
method write-args( List $_ ) {
    $.write: $_, :sep(', ');
}

#| [foo]   := $.write-attrib: [ :ident<foo> ]
method write-attrib( List $_ ) {
    [~] '[', .map({ $.write( $_ ) }).Slip, ']';
}

#| /* These are */ /* comments * / */ := $.write-comment: [ "These are", "comments */" ]
multi method write-comment( List:D $_ ) {
    .map({ $.write-comment( $_ ) }).join: $.nl;
}
multi method write-comment( Str:D $_ ) {
    when  /^ <CSS::Grammar::CSS3::comment> $/ { $_ }
    default { [~] '/* ', .trim.subst(/'*/'/, '* /'), ' */'; }
}
multi method write-comment($) {''}

#| .my-class := $.write-class( 'my-class' )
method write-class( Str $_) {
    '.' ~ $.write-name: $_;
}

# for example, the body of an HTML style tag
#| font-size:12pt; color:white; := $.write-declaration-list: [ { :ident<font-size>, :expr[ :pt(12) ] }, { :ident<color>, :expr[ :ident<white> ] } ]
method write-declaration-list( List $_ ) {
    .map({
        my $prop = .<ident>:exists
            ?? :property($_)
            !! $_;

        $.write-indented( $prop, 2);
    }).join: $.nl;
}

#| { font-size:12pt; color:white; } := $.write-declarations: [ { :ident<font-size>, :expr[ :pt(12) ] }, { :ident<color>, :expr[ :ident<white> ] } ]
method write-declarations( List $_ ) {
    ('{', $.write-declaration-list( $_ ).Slip, $.indent ~ '}').join: $.nl;
}

#| h1 := $.write-element-name('H1')
method write-element-name( Str $_ ) {
    when '*' {'*'}  # wildcard namespace
    default  { $.write-ident( .lc ) }
}

#| 'foo', bar+42 := $.write-expr: [ :string<foo>, :op<,>, :ident<bar>, :op<+>, :num(42) ]
method write-expr( List $_ ) {
    my $sep = '';

    [~] .map: -> %term is copy {
        $sep = '' if %term<op>;

        with %term<ident> {
            with %!color-values{ .lc } -> @rgb {
                # substitute a named color with it's rgb value
                %term = %( rgb => [ @rgb.map({ num => $_}) ] );
            }
        }

        my $out = $sep ~ $.write(%term);
        $sep = %term<op> && %term<op> ne ',' ?? '' !! ' ';
        $out;
    }
}

#| @charset 'utf-8';   := $.write( :at-rule{ :at-keyw<charset>, :string<utf-8> } )
multi method write-at-rule(% (:$at-keyw! where 'charset', :$string!) ) {
    $.write-nodes( (:$at-keyw), (:$string) ) ~ ';'
}

#| @import url('example.css') screen and (color); := $.write( :at-rule{ :at-keyw<import>, :url<example.css>, :media-list[ { :media-query[ { :ident<screen> }, { :keyw<and> }, { :property{ :ident<color> } } ] } ] } )
multi method write-at-rule(% (:$at-keyw! where 'import', :$url, :$string, :$media-list) ) {
    $.write-nodes( (:$at-keyw), (:$url), (:$string), (:$media-list) ) ~ ';'
}

#| @media all { body { background:lime; } } := $.write( :at-rule{ :at-keyw<media>, :media-list[ { :media-query[ :ident<all> ] } ], :rule-list[ { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<body> } ] } ] ], :declarations[ { :ident<background>, :expr[ :ident<lime> ] }, ] } } ]} )
multi method write-at-rule(% (:$at-keyw! where 'media', :$media-list, :$rule-list) ) {
    $.write-nodes( (:$at-keyw), (:$media-list), (:$rule-list) )
}

#| @namespace svg url('http://www.w3.org/2000/svg'); := $.write( :at-rule{ :at-keyw<namespace>, :ns-prefix<svg>, :url<http://www.w3.org/2000/svg> } )
multi method write-at-rule(% (:$at-keyw! where 'namespace', :$ns-prefix, :$url) ) {
    $.write-nodes( (:$at-keyw), (:$ns-prefix), (:$url) ) ~ ';'
}

#| @page :first { margin:5mm; } := $.write( :at-rule{ :at-keyw<page>, :pseudo-class<first>, :declarations[ { :ident<margin>, :expr[ :mm(5) ] }, ] } )
multi method write-at-rule(% (:$at-keyw! where 'page', :$pseudo-class, :$declarations) ) {
    $.write-nodes( (:$at-keyw), (:$pseudo-class), (:$declarations) )
}

#| @font-face { src:'foo.ttf'; } := $.write( :at-rule{ :at-keyw<font-face>, :declarations[ { :ident<src>, :expr[ :string<foo.ttf> ] }, ] } )
#| @top-left { margin:5px; } :=   $.write( :at-rule{ :at-keyw<top-left>, :declarations[ { :ident<margin>, :expr[ :px(5) ] }, ] } )
multi method write-at-rule(% (:$at-keyw!, :$declarations!)) {
    $.write-nodes( (:$at-keyw), (:$declarations) )
}

#| lang(klingon) := $.write-func: { :ident<lang>, :args[ :ident<klingon> ] }
method write-func(% (:$ident!, :$args, :$expr, :$comment)) {
    '%s(%s)%s'.sprintf(
        $.write-ident( $ident ),
        do with $args {$.write-args( $_ )}
        else {
            with $expr {$.write-expr( $_ )}
            else {''}
        },
        $.write-comment( $comment );
    );
}

#| #My-id := $.write-id( 'My-id' )
method write-id(Str $_) {
    '#' ~ $.write-name: $_;
}

#| -Moz-linear-gradient := $.write-ident('-Moz-linear-gradient' )
method write-ident(Str $_ is copy) {
    if .starts-with('--') {
        '-\\-' ~ $.write-name: .substr(2);
    }
    else {
        $.write-name: $_;
    }
}

#| 42 := $.write-int(42)
method write-int( Numeric $_ ) {
    $.write-num: $_ ;
}

#| color := $.write-keyw('Color')
method write-keyw( Str $_ ) {
    .lc;
}

#| projection, tv := $.write-media-list: [ :ident<projection>, :ident<tv> ]
method write-media-list( List $_ ) {
    $.write( $_, :sep(', ') );
}

#| screen and (color) := $.write-media-query: [ { :ident<screen> }, { :keyw<and> }, { :property{ :ident<color> } } ]
method write-media-query( List $_ ) {
    join(' ', .map({
        my $css = $.write: $_;

        if .<property> {
            # e.g. color:blue => (color:blue)
            $css = [~] '(', $css.subst(/';'$/, ''), ')';
        }

        $css
    }) );
}

#| hi\! := $.write-name("hi\x021")
method write-name( Str $_ ) {
    .subst(/<reg=CSS::Grammar::CSS3::nmreg>||./,
           {
               with $<reg> { .Str } else { escaped $/.Str }
           }, :g);
}

#| svg := $.write-ns-prefix( 'svg' )
method write-ns-prefix( Str $_) {
    when ''  {''}   # no namespace
    when '*' {'*'}  # wildcard namespace
    default  { $.write-ident: $_ }
}

#| 42 := $.write( :num(42) )

#| ~= := $.write( :op<~=> )
method write-op( Str $_ ) {
    .lc;
}

#| 100% := $.write-percent(100)
method write-percent( Numeric $_ ) {
    $.write-num( $_ ) ~ '%';
}

#| !important := $.write-prio('important')
method write-prio( Str $_ = 'important' ) {
    '!' ~ .lc;
}

#| color:red!important; := $.write-property: { :ident<color>, :expr[ :ident<red> ], :prio<important> }
method write-property(% (:$ident!, :$expr, :$prio, :$comment)) {
    my \sp = $!pretty ?? ' ' !! '';
    my Str @p = $.write-ident( $ident );
    @p.push: ':' ~ sp ~ $.write-expr($_)
        with $expr;
    @p.push: sp ~$.write-prio($_)
        with $prio;
    @p.push: ';';
    @p.push: sp ~ $.write-comment($_) with $comment;

    @p.join;
}

#| :first := $.write-pseudo-class('first')
method write-pseudo-class(Str $_) {
    ':' ~ $.write-name: $_;
}

#| ::first-letter := $.write-pseudo-elem: 'first-letter'
method write-pseudo-elem(Str $_) {
    '::' ~ $.write-name: $_;
}

#| :lang(klingon) := $.write-pseudo-func: { :ident<lang>, :args[ :ident<klingon> ] }
method write-pseudo-func( Hash $_ ) {
    ':' ~ $.write-func: $_;
}

#| svg|circle := $.write-qname: { :ns-prefix<svg>, :element-name<circle> }
method write-qname(% (:$element-name!, :$ns-prefix, :$comment)) {
    my $out = $.write-element-name($element-name);

    $out = $.write-ns-prefix($_) ~ '|' ~ $out
        with $ns-prefix;

    $out ~= $.write-comment( $_ ) with $comment;

    $out;
}

#| { h1 { margin:5pt; } h2 { margin:3pt; color:red; } } := $.write-rule-list: [ { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<h1> } ] } ] ], :declarations[ { :ident<margin>, :expr[ :pt(5) ] }, ] } }, { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<h2> } ] } ] ], :declarations[ { :ident<margin>, :expr[ :pt(3) ] }, { :ident<color>, :expr[ :ident<red> ] } ] } } ]
method write-rule-list(List $_) {
    ('{' , slip(.map({$.write-indented($_, 2)})), $.indent ~ '}').join: $.nl;
}

#| a:hover { color:green; } := $.write-ruleset: { :selectors[ :selector[ { :simple-selector[ { :element-name<a> }, { :pseudo-class<hover> } ] } ] ], :declarations[ { :ident<color>, :expr[ :ident<green> ] }, ] }
method write-ruleset(% (:$selectors, :$declarations), |c) {
    [~] $.write-nodes((:$selectors), (:$declarations), |c);
}

#| #container * := $.write-selector: [ { :id<container>}, { :element-name<*> } ]
method write-selector(List $_) {
    $.write: $_;
}

#| h1, [lang=en] := $.write-selectors: [ :selector[ { :simple-selector[ { :element-name<h1> } ] } ], :selector[ :simple-selector[ { :attrib[ :ident<lang>, :op<=>, :ident<en> ] } ] ] ]
method write-selectors(List $_ ) {
    $.write: $_, :sep(', ');
}

#| .foo:bar#baz := $.write-simple-selector: [ :class<foo>, :pseudo-class<bar>, :id<baz> ]
method write-simple-selector(List $_) {
    $.write: $_, :sep("");
}

sub escaped($_) {
    '\\' ~ (0x20 <= .ord <= 0x7F
            ?? $_
            !! .ord.fmt("%X "));
}

sub write-string-chunk($/) {
    with $<reg> {
        .Str
    }
    else {
        given $/.Str {
            $_ eq '"' ?? $_ !! escaped $_
        }
    }
}

#| 'I\'d like some \BEE f!' := $.write-string("I'd like some \x[bee]f!")
method write-string( Str() $str --> Str) {
    [~] ("'",
         $str.subst(/<reg=CSS::Grammar::CSS3::stringchar-regular>||./, { write-string-chunk($/) }, :g),
         "'");
}

#| h1 { color:blue; } := $.write-stylesheet: [ { :ruleset{ :selectors[ { :selector[ { :simple-selector[ { :qname{ :element-name<h1> } } ] } ] } ], :declarations[ { :ident<color>, :expr[ { :ident<blue> } ] }, ] } } ]
method write-stylesheet(List $_) {
    my $sep = $!pretty ?? "\n\n" !! "\n";
    $.write: $_, :$sep;
}

#| U+A?? := $.write-unicode-range: [0xA00, 0xAFF]
method write-unicode-range(List $_ ) {
    my ($lo, $hi) = $_.>>.fmt("%X");

    my $range = do if !$lo eq $hi {
        # single value
        $lo;
    }
    else {
        my $lo-sub = $lo.subst: /0+$/, '';
        my $hi-sub = $hi.subst: /F+$/, '';

        if $lo-sub eq $hi-sub {
            $hi-sub  ~ ('?' x ($hi.chars - $hi-sub.chars));
        }
        else {
            [~] $lo, '-', $hi;
        }
    }

    'U+' ~ $range;
}

#| url('snoopy.jpg') := $.write-url: 'snoopy.jpg'
method write-url( $_ ) {
    $.write-string($_).fmt: "url(%s)";
}

#! generic handling of Lists, Pairs, Hashs and Lists
multi method write(List $ast, Str :$sep=' ') {
    my Array %sifted = classify { .isa(Hash) && (.<comment>:exists) ?? 'comment' !! 'elem' }, $ast.list;
    my Str $out = (%sifted<elem> // []).list.map({ $.write( $_ ) }).join: $sep;
    $out ~= [~] %sifted<comment>.list.map({ ' ' ~ $.write($_) })
        if %sifted<comment>:exists && $!pretty;
    $out;
}

sub key(Str:D $k) {
    with $k.index(':') {
        $k.substr: 0, $_;
    }
    else {
        $k;
    }
}

multi method write(Pair $_) {
    my $node = key(.key);
    self."write-$node"( .value );
}

multi method write(Hash $ast!, :$node! ) {
    self."write-$node"( $ast{$node} );
}

method write-nodes(*@nodes, Str :$punc='', Str :$sep=' ', :$comments)  {
    my Str $str = @nodes.grep(*.value.defined).map({
        my $node := key(.key);
        self."write-$node"(.value);
   }).join($sep)  ~  $punc;

    $str ~= $.write-comment( $_ ) with $comments;

    $str;
}

multi method write(Hash $ast! ) {
    $.write: |$ast.keys.map: { key($_) => $ast{$_} };
}

multi method write( *@args, *%opt ) {
    my $key = %opt.keys.sort.first({ $.can("write-$_") || (CSS::Grammar::Defs::CSSUnits.enums{$_}:exists) })
        or die "unable to handle {%opt.keys} struct: {%opt.raku}";
    self."write-$key"(%opt{$key}, |%opt);
}

# -- helper methods --

#| handle indentation.
method write-indented( Any $ast, Int $indent! --> Str) {
    if $!pretty {
        temp $.indent ~= ' ' x $indent;
        $.indent ~ $.write( $ast );
    }
    else {
        $.write($ast)
    }
}

method nl returns Str {
    $!pretty ?? "\n" !! ' ';
}

    # -- colors -- #
multi method coerce-color(Int :$int!)         {$int}
multi method coerce-color(Numeric :$num!)     {+sprintf "%d", $num}
multi method coerce-color(Numeric :$percent!) {+sprintf "%d", $percent * 2.55}
multi method coerce-color                     {Any}

method color-channel($node) {
    my $num = $.coerce-color(|%$node)
        // return;
    max(0, min(255, $num));
}

method !write-rgb-mask( @mask ) {
    # can we reduce to the three hex digit form?
    # #aa77ff => #a7f
    my $reducable = [&&] @mask.map: { $_ %% 17 };
    my @hex-digits = $reducable
        ?? @mask.map: {($_ div 17).fmt: "%X"}
        !! @mask.map: {.fmt: "%02X"};

    [~] '#', @hex-digits.Slip;
}

#| rgb(10, 20, 30) := $.write-color: [ :num(10), :num(20), :num(30) ], 'rgb' or $.write( :rgb[ :num(10), :num(20), :num(30) ] ) or $.write-rgb: [ :num(10), :num(20), :num(30) ]
proto write-color(List $ast, Str $units --> Str) {*}

multi method write-color(List $ast, 'rgb') {
    return self.write-color($ast, 'rgba')
        if $ast == 4;
    my @mask = $ast.map: { $.color-channel($_) };

    return if +@mask != 3 || @mask.first: {!.defined}

    if %!color-names {
        # map to a color name, if possible
        my $idx = 256 * (256 * @mask[0]  +  @mask[1])  + @mask[2];
        return %!color-names{ $idx}
            if %!color-names{ $idx }:exists;
    }

    my $out = self!write-rgb-mask(@mask)
        if $!color-masks;

    $out // sprintf 'rgb(%s, %s, %s)', $ast.map: { $.write( $_ )};
}

multi method write-color( List $ast, 'rgba' ) {
    my \alpha = $ast[3]<num> // ($ast[3]<percent> // 100) / 100.0;

    if alpha =~= 0.0 && %!color-names {
        'transparent'
    }
    elsif alpha =~= 1.0 {
        # drop the alpha channel
        $.write-color( $ast[0..2], 'rgb' )
    }
    else {
        sprintf 'rgba(%s, %s, %s, %s)', $ast.map: {$.write( $_ )};
    }
}

multi method write-color(List $ast, 'hsl') {
    sprintf 'hsl(%s, %s, %s)', $ast.map: {$.write( $_ )};
}

multi method write-color(List $ast, 'hsla') {
    my \alpha = $ast[3]<num> // $ast[3]<percent> / 100.0;

    alpha =~= 0.0 && %!color-names
        ?? 'transparent'
        !! sprintf 'hsla(%s, %s, %s, %s)', $ast.map: {$.write( $_ )};
}

multi method write-color(Str $ast, Any $) {
    # e.g. 'currentcolor'
    $ast.lc;
}

multi method write-color( Any $color, Any $units ) {
    die "unable to handle color: {$color.raku}, units: {$units.raku}"
}


# -- numbers -- #
proto method write-num( Numeric $, $? --> Str) {*};

multi method write-num( 1, 'em' ) { 'em' }
multi method write-num( 1, 'ex' ) { 'ex' }
multi method write-num( $freq, 'khz' ) {
    $.write-num( $freq * 1000, 'hz' )
}
multi method write-num( Numeric $num, Str:D $units ) {
    $.write-num($num) ~ ($num == 0 ?? '' !! $units.lc)
}
multi method write-num( Numeric $num, Mu $units? ) {
    my $int = $num.Int;
    $int == $num ?? $int !! $num;
}

multi method write-num( *@args) {
    die "unable to .write-num({@args.raku})";
}

#| 42deg   := $.write-num( 42,  'deg') or $.write( :deg(42) )
#| 420hz   := $.write-num( 420, 'hz')  or $.write( :khz(.42) )
#| 42mm    := $.write-num( 42,  'mm')  or $.write( :mm(42) ) or $.write-mm(42)
#| 600dpi  := $.write-num( 600, 'dpi') or $.write( :dpi(600) )
#| 20s     := $.write-num( 20,  's' )  or $.write( :s(20) )

#| to be deprecated
method terse is rw is DEPRECATED<!pretty> {
    Proxy.new:
    FETCH => {! $!pretty},
    STORE => -> $, $v { $!pretty = ! $v }
}

method FALLBACK ($meth-name, $val, |c) {
    if $meth-name ~~ /^ 'write-' (.+) $/ {
        my $units = ~$0;
        given CSS::Grammar::Defs::CSSUnits.enums{$units} {
            when 'color' { $.write-color( $val, $units, |c) }
            default      { $.write-num( $val, $units, |c) }
        }
    }
    else {
        die "unknown method: $meth-name";
    }
}

