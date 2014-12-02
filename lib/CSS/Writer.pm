use v6;

use CSS::Writer::BaseTypes;

class CSS::Writer
    is CSS::Writer::BaseTypes {

    use CSS::Grammar::AST;
    use CSS::Grammar::CSS3;

    has Str $.indent is rw;
    has Bool $.terse is rw;
    has Bool $.rgb-masks is rw;
    has %.color-values is rw;   #- maps color names to rgb values
    has %.color-names is rw;    #- maps rgb hex codes to named colors

    submethod BUILD(:$!indent='', :$!terse=False, :$!rgb-masks=False, :$color-names, :$color-values is copy) {

        sub build-color-names(%colors) {
            my %color-names;

            for %colors {
                my ($name, $rgb) = .kv;
                my $hex = 256 * (256 * $rgb[0]  +  $rgb[1])  +  $rgb[2];
                %color-names{ $hex } = $name;
            }

            return %color-names;
        }

        if $!terse {
            $!rgb-masks //= True;
        }

        if $color-names.defined {
            die ":color-names and :color-values are mutually exclusive options"
                if $color-values;

            given $color-names {
                when Bool { %!color-names = build-color-names( %CSS::Grammar::AST::CSS3-Colors )
                                if $_; }
                when Hash { %!color-names = build-color-names( $_ ) }
                default {
                    die 'usage :color-names [for CSS3 Colors] or :color-names(%table) [e.g. :color-names(CSS::Grammar::AST::CSS3-Colors)]';
                }
            }
        }
        elsif $color-values.defined {
            given $color-values {
                when Bool { %!color-values = %CSS::Grammar::AST::CSS3-Colors
                                if $_; }
                when Hash { %!color-values = %$_ }
                default {
                    die 'usage :color-values [for CSS3 Colors] or :color-values(%table) [e.g. :color-values(CSS::Grammar::AST::CSS3-Colors)]';
                }
            }
        }

    }

    #| @top-left { margin: 5px; } :=   $.write( :at-keyw<top-left>, :declarations[ { :ident<margin>, :expr[ :px(5) ] } ] )
    multi method write( Str :$at-keyw!, List :$declarations! ) {
        ($.write( :$at-keyw ),  $.write( :$declarations)).join: ' ';
    }

    #| 42deg   := $.write( :angle(42), :units<deg>) or $.write( :deg(42) )
    multi method write( Numeric :$angle!, Any :$units? ) {
        $.write-num( $angle, $units );
    }

    #| @page   := $.write( :at-keyw<page> )
    multi method write( Str :$at-keyw! ) {
        '@' ~ $.write( :ident($at-keyw) );
    }

    #| 'foo', bar, 42 := $.write( :args[ :string<foo>, :ident<bar>, :num(42) ] )
    multi method write( List :$args! ) {
        @$args.map({ $.dispatch($_) }).join: ', ';
    }

    #| [foo]   := $.write( :attrib[ :ident<foo> ] )
    multi method write( List :$attrib! ) {
        [~] '[', $attrib.map({ $.dispatch( $_ ) }), ']';
    }

    #| @charset 'utf-8';   := $.write( :charset-rule<utf-8> )
    multi method write( Str :$charset-rule! ) {
        [~] '@charset ', $.write( :string($charset-rule) ), ';'
    }

    #| rgb(10, 20, 30) := $.write( :color[ :num(10), :num(20), :num(30) ], :units<rgb> )
    #| or $.write( :rgb[ :num(10), :num(20), :num(30) ] )
    multi method write( Any :$color!, Any :$units? ) {
        $.write-color( $color, $units );
    }

    #| .my-class := $.write( :class<my-class> )
    multi method write( Str :$class!) {
        '.' ~ $.write( :name($class) );
    }

    #| { font-size: 12pt; color: white; } := $.write( :declarations[ { :ident<font-size>, :expr[ :pt(12) ] }, { :ident<color>, :expr[ :ident<white> ] } ] )
    multi method write( List :$declarations! ) {
        my @decls-indented =  $declarations.map: {
            my $prop = .<ident>:exists
                ?? %(property => $_)
                !! $_;

            $.dispatch( $prop, :indent(2) );
        };

        ('{', @decls-indented, $.indent ~ '}').join: $.nl;
    }

    #| h1 := $.write: :element-name<H1>
    multi method write( Str :$element-name! ) {
        given $element-name {
            when '*' {'*'}  # wildcard namespace
            default  { $.write( :ident($_) ).lc }
        }
    }

    #| 'foo', bar+42 := $.write( :expr[ :string<foo>, :op<,>, :ident<bar>, :op<+>, :num(42) ] )
    multi method write( List :$expr! ) {
        my $sep = '';

        [~] @$expr.map( -> $term is copy {

            $sep = '' if $term<op> && $term<op>;

            if %.color-values && ($term<ident>:exists) && my $rgb = %.color-values{ $term<ident>.lc } {
                # substitute a named color with it's rgb value
                $term = {rgb => $rgb.map({ num => $_})};
            }

            my $out = $sep ~ $.dispatch($term);
            $sep = $term<op> && $term<op> ne ',' ?? '' !! ' ';
            $out;
        });
    }

    #| @font-face { src: 'foo.ttf'; } := $.write( :fontface-rule{ :declarations[ { :ident<src>, :expr[ :string<foo.ttf> ] } ] } )
    multi method write( Hash :$fontface-rule! ) {
        [~] '@font-face ', $.dispatch( $fontface-rule, :node<declarations> );
    }

    #| 420hz   := $.write( :freq(420), :units<hz>) or $.write( :khz(.42) )
    multi method write( Numeric :$freq!, Str :$units ) {
        given $units {
            when 'hz' {$.write-num( $freq, 'hz' )}
            when 'khz' {$.write-num( $freq * 1000, 'hz' )}
            default {die "unhandled frequency unit: $units";}
        }
    }
    multi method write( Numeric :$freq!, :$units='khz' ) {
        $.write-num( $freq * 1000, 'hz' );
    }

    #| :lang(klingon) := $.write( :pseudo-func{ :ident<lang>, :args[ :ident<klingon> ] } )
    multi method write( Hash :$func!) {
        sprintf '%s(%s)', $.dispatch( $func, :node<ident> ), do {
            when $func<args>:exists {$.dispatch( $func, :node<args> )}
            when $func<expr>:exists {$.dispatch( $func, :node<expr> )}
            default {''};
        }
    }

    #| #My-id := $.write( :id<My-id> )
    multi method write( Str :$id!) {
        '#' ~ $.write( :name($id) );
    }

    #| -Moz-linear-gradient := $.write( :ident<-Moz-linear-gradient> )
    multi method write( Str :$ident! is copy) {
        my $pfx = $ident ~~ s/^"-"// ?? '-' !! '';
        my $minus = $ident ~~ s/^"-"// ?? '\\-' !! '';
        [~] $pfx, $minus, $.write( :name($ident) )
    }

    #| @import url('example.css') screen and (color); := $.write( :import{ :url<example.css>, :media-list[ { :media-query[ { :ident<screen> }, { :keyw<and> }, { :property{ :ident<color> } } ] } ] } )
    multi method write( Hash :$import! ) {
        [~] '@import ', join(' ', <url media-list>.grep({ $import{$_}:exists }).map({ $.dispatch( $import, :node($_) ) })), ';';
    }

    #| 42 := $.write: :num(42)
    multi method write( Numeric :$int! ) {
        $.write-num( $int );
    }

    #| color := $.write: :keyw<Color>
    multi method write( Str :$keyw! ) {
        $keyw.lc;
    }

    #| 42mm   := $.write( :length(42), :units<mm>) or $.write( :mm(42) )
    multi method write( Numeric :$length!, Any :$units? ) {
        $.write-num( $length, $units );
    }

    #| projection, tv := $.write( :media-list[ :ident<projection>, :ident<tv> ] )
    multi method write( List :$media-list! ) {
        join(', ', $media-list.map({ $.dispatch( $_ ) }) );
    }

    #| screen and (color) := $.write( :media-query[ { :ident<screen> }, { :keyw<and> }, { :property{ :ident<color> } } ] )
    multi method write( List :$media-query! ) {
        join(' ', $media-query.map({
            my $css = $.dispatch( $_ );

            if .<property> {
                # e.g. color:blue => (color:blue)
                $css = [~] '(', $css.subst(/';'$/, ''), ')';
            }

            $css
        }) );
    }

    #| @media all { body { background: lime; }} := $.write( :media-rule{ :media-list[ { :media-query[ :ident<all> ] } ], :rule-list[ { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<body> } ] } ] ], :declarations[ { :ident<background>, :expr[ :ident<lime> ] } ] } } ]} )
    multi method write( Hash :$media-rule! ) {
        ('@media', <media-list rule-list>.grep({ $media-rule{$_}:exists }).map({ $.dispatch( $media-rule, :node($_) ) })).join: ' ';
    }

    #| hi\! := $.write( :name("hi\x021") )
    multi method write( Str :$name! ) {
        [~] $name.comb.map({
            when /<CSS::Grammar::CSS3::nmreg>/    { $_ };
            when /<CSS::Grammar::CSS3::regascii>/ { '\\' ~ $_ };
            default                               { .ord.fmt("\\%X ") }
        });
    }

    #| @namespace svg url('http://www.w3.org/2000/svg'); := $.write( :namespace-rule{ :ns-prefix<svg>, :url<http://www.w3.org/2000/svg> } )
    multi method write( Hash :$namespace-rule! ) {
        join(' ', '@namespace', <ns-prefix url>.grep({ $namespace-rule{$_}:exists }).map({ $.dispatch( $namespace-rule, :node($_) ) })) ~ ';';
    }

    #| svg := $.write( :ns-prefix<svg> )
    multi method write( Str :$ns-prefix! ) {
        given $ns-prefix {
            when ''  {''}   # no namespace
            when '*' {'*'}  # wildcard namespace
            default  { $.write( :ident($_) ) }
        }
    }

    #| 42 := $.write( :num(42) )
    multi method write( Numeric :$num! ) {
        $.write-num( $num )
    }

    #| ~= := $.write( :op<~=> )
    multi method write( Str :$op! ) {
        $op.lc;
    }

    #| @page :first { margin: 5mm; } := $.write( :page-rule{ :pseudo-class<first>, :declarations[ { :ident<margin>, :expr[ :mm(5) ] } ] } )
    multi method write( Hash :$page-rule! ) {
        join(' ', '@page', <pseudo-class declarations>.grep({ $page-rule{$_}:exists }).map({ $.dispatch( $page-rule, :node($_) ) }) );
    }

    #| 100% := $.write( :percent(100) )
    multi method write( :$percent! ) {
        $.write-num( $percent, '%' );
    }

    #| color: red !important; := $.write( :property{ :ident<color>, :expr[ :ident<red> ], :prio<important> } )
    multi method write( Hash :$property! ) {
        my $expr = $property<expr>:exists
            ?? ': ' ~ $.dispatch($property, :node<expr>)
            !! '';
        my $prio = $property<prio>
            ?? ' !' ~ $property<prio>
            !! '';

        [~] $.dispatch( $property, :node<ident> ), $expr, $prio, ';';
    }

    #| :first := $.write: :pseudo-class<first>
    multi method write( Str :$pseudo-class! ) {
        ':' ~ $.write( :name($pseudo-class) );
    }

    #| ::nth := $.write: :pseudo-elem<nth>
    multi method write( Str :$pseudo-elem! ) {
        '::' ~ $.write( :name($pseudo-elem) );
    }

    #| :lang(klingon) := $.write( :pseudo-func{ :ident<lang>, :args[ :ident<klingon> ] } )
    multi method write( Hash :$pseudo-func! ) {
        ':' ~ $.write( :func($pseudo-func) );
    }

    #| svg|circle := $.write( :qname{ :ns-prefix<svg>, :element-name<circle> } )
    multi method write( Hash :$qname! ) {
        my $out = $.dispatch($qname, :node<element-name>);
        $out = [~] $.dispatch($qname, :node<ns-prefix>), '|', $out
            if $qname<ns-prefix>:exists;
        $out;
    }

    #| 600dpi   := $.write( :resolution(600), :units<dpi>) or $.write( :dpi(600) )
    multi method write( Numeric :$resolution!, Any :$units? ) {
        $.write-num( $resolution, $units );
    }

    #| { h1 { margin: 5pt; } h2 { margin: 3pt; color: red; }} := $.write( :rule-list[ { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<h1> } ] } ] ], :declarations[ { :ident<margin>, :expr[ :pt(5) ] } ] } }, { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<h2> } ] } ] ], :declarations[ { :ident<margin>, :expr[ :pt(3) ] }, { :ident<color>, :expr[ :ident<red> ] } ] } } ])
    multi method write( List :$rule-list! ) {
        '{ ' ~ $rule-list.map( { $.dispatch($_) } ).join($.nl) ~ '}';
    }

    #| a:hover { color: green; } := $.write( :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<a> }, { :pseudo-class<hover> } ] } ] ], :declarations[ { :ident<color>, :expr[ :ident<green> ] } ] } )
    multi method write( Hash :$ruleset! ) {
        sprintf "%s %s", $.dispatch($ruleset, :node<selectors>), $.dispatch($ruleset, :node<declarations>);
    }

    #| #container * := $.write( :selector[ { :id<container>}, { :element-name<*> } ] )
    multi method write( List :$selector! ) {
        $selector.map({ $.dispatch( $_ ) }).join(' ');
    }

    #| h1, [lang=en] := $.write( :selectors[ :selector[ { :simple-selector[ { :element-name<h1> } ] } ], :selector[ :simple-selector[ { :attrib[ :ident<lang>, :op<=>, :ident<en> ] } ] ] ] )
    multi method write( List :$selectors! ) {
        $selectors.map({ $.dispatch( $_ ) }).join(', ');
    }

    #| .foo:bar#baz := $.write: :simple-selector[ :class<foo>, :pseudo-class<bar>, :id<baz> ]
    multi method write( List :$simple-selector! ) {
        [~] $simple-selector.map({ $.dispatch( $_ ) })
    }

    #| 'Hi\' there\FA !' := $.write( :string("Hi' there\x[fa]!") )
    multi method write( Str :$string! ) {
        $.write-string($string);
    }

    #| h1 { color: blue; } := $.write( :stylesheet[ { :ruleset{ :selectors[ { :selector[ { :simple-selector[ { :qname{ :element-name<h1> } } ] } ] } ], :declarations[ { :ident<color>, :expr[ { :ident<blue> } ] } ] } } ] )
    multi method write( List :$stylesheet! ) {
        my $sep = $.terse ?? "\n" !! "\n\n";
        join($sep, $stylesheet.map({ $.dispatch( $_ ) }) );
    }

    #| 20s := $.write( :time(20), :units<s> ) or $.write( :s(20) )
    multi method write( Numeric :$time!, Any :$units? ) {
        $.write-num( $time, $units );
    }

    #| U+A?? := $.write( :unicode-range[0xA00, 0xAFF] )
    multi method write( List :$unicode-range! ) {
        my $range;
        my ($lo, $hi) = @$unicode-range.map: {sprintf("%X", $_)};

        if !$lo eq $hi {
            # single value
            $range = sprintf '%x', $lo;
        }
        else {
            my $lo-sub = $lo.subst(/0+$/, '');
            my $hi-sub = $hi.subst(/F+$/, '');

            if $lo-sub eq $hi-sub {
                $range = $hi-sub  ~ ('?' x ($hi.chars - $hi-sub.chars));
            }
            else {
                $range = [~] $lo, '-', $hi;
            }
        }

        'U+' ~ $range;
    }

    #| url('snoopy.jpg') := $.write( :url<snoopy.jpg> )
    multi method write( Str :$url! ) {
        sprintf "url(%s)", $.write-string( $url );
    }

    multi method write( *@args, *%opts ) is default {

        die "unexpected arguments: {[@args].perl}"
            if @args;

        use CSS::Grammar::AST :CSSUnits;
        for %opts.keys {
            if my $type = CSSUnits.enums{$_} {
                # e.g. redispatch $.write( :px(12) ) as $.write( :length(12), :units<px> )
                my %new-opts = $type => %opts{$_}, units => $_;
                return $.write( |%new-opts );
            }
        }
        
        die "unable to handle struct: {%opts.perl}"
    }

    # -- helper methods --

    method nl {
        $.terse ?? ' ' !! "\n";
    }

    method dispatch($ast, :$node, :$indent?) {

        return '' unless $ast.defined;
        my $sp = '';
        temp $.indent;
        if $indent.defined && !$.terse {
            $.indent ~= ' ' x $indent;
            $sp = $.indent;
        }

        if $ast.isa(Hash) || $ast.isa(Pair) {
            # it's a token represented by a type/value pair
            my %params = $ast.keys.map: {
                .subst(/':'.*/, '') => $ast{$_};
            }

            %params = $node => %params{$node}
                if $node.defined;

            $sp ~ $.write( |%params );
        }
        else {
            warn "dunno how to dispatch: {$ast.perl}";
        }

    }
}
