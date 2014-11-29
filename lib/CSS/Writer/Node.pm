use v6;

use CSS::Writer::BaseTypes;

class CSS::Writer::Node
    is CSS::Writer::BaseTypes {

    use CSS::Grammar::CSS3;

    #| @top-left { margin: 5px; } :=   $.write-node( :at-keyw<top-left>, :declarations[ { :ident<margin>, :expr[ :px(5) ] } ] )
    multi method write-node( Str :$at-keyw!, List :$declarations! ) {
        ($.write-node( :$at-keyw ),  $.write-node( :$declarations)).join: ' ';
    }

    #| 42deg   := $.write-node( :angle(42), :units<deg>) or $.write-node( :deg(42) )
    multi method write-node( Numeric :$angle!, Any :$units? ) {
        $.write-num( $angle, $units );
    }

    #| @page   := $.write-node( :at-keyw<page> )
    multi method write-node( Str :$at-keyw! ) {
        '@' ~ $.write-node( :ident($at-keyw) );
    }

    #| 'foo', bar, 42 := $.write-node( :args[ :string<foo>, :ident<bar>, :num(42) ] )
    multi method write-node( List :$args! ) {
        @$args.map({ $.write($_) }).join: ', ';
    }

    #| [foo]   := $.write-node( :attrib[ :ident<foo> ] )
    multi method write-node( List :$attrib! ) {
        [~] '[', $attrib.map({ $.write( $_ ) }), ']';
    }

    #| @charset 'utf-8';   := $.write-node( :charset-rule<utf-8> )
    multi method write-node( Str :$charset-rule! ) {
        [~] '@charset ', $.write-node( :string($charset-rule) ), ';'
    }

    #| rgb(10, 20, 30) := $.write-node( :color[ :num(10), :num(20), :num(30) ], :units<rgb> )
    #| or $.write-node( :rgb[ :num(10), :num(20), :num(30) ] )
    multi method write-node( Any :$color!, Any :$units? ) {
        $.write-color( $color, $units );
    }

    #| .my-class := $.write-node( :class<my-class> )
    multi method write-node( Str :$class! is copy ) {
        '.' ~ $.write-node( :name($class) );
    }

    #| { font-size: 12pt; color: white; } := $.write-node( :declarations[ { :ident<font-size>, :expr[ :pt(12) ] }, { :ident<color>, :expr[ :ident<white> ] } ] )
    multi method write-node( List :$declarations! ) {
        my @declarations-indented = do {

            $declarations.map: {
                my $prop = .<ident>:exists
                    ?? %(property => $_)
                    !! $_;

                $.write( $prop, :indent(2) );
            }
        };
        ('{', @declarations-indented, $.indent ~ '}').join: $.nl;
    }

    #| h1 := $.write-node: :element-name<H1>
    multi method write-node( Str :$element-name! ) {
        given $element-name {
            when '*' {'*'}  # wildcard namespace
            default  { $.write-node( :ident($_) ).lc }
        }
    }

    #| 'foo', bar+42 := $.write-node( :expr[ :string<foo>, :op<,>, :ident<bar>, :op<+>, :num(42) ] )
    multi method write-node( List :$expr! ) {
        my $sep = '';

        [~] @$expr.map( -> $term {

            $sep = '' if $term<op> && $term<op>;
            my $out = $sep ~ $.write($term);
            $sep = $term<op> && $term<op> ne ',' ?? '' !! ' ';
            $out;
        });
    }

    #| @font-face { src: 'foo.ttf'; } := $.write-node( :fontface-rule{ :declarations[ { :ident<src>, :expr[ :string<foo.ttf> ] } ] } )
    multi method write-node( Hash :$fontface-rule! ) {
        [~] '@font-face ', $.write( $fontface-rule, :node<declarations> );
    }

    #| 42hz   := $.write-node( :freq(42), :units<hz>) or $.write-node( :hz(42) )
    multi method write-node( Numeric :$freq!, Any :$units? ) {
        $.write-num( $freq, $units );
    }

    #| :lang(klingon) := $.write-node( :pseudo-func{ :ident<lang>, :args[ :ident<klingon> ] } )
    multi method write-node( Hash :$func! is copy ) {
        sprintf '%s(%s)', $.write( $func, :node<ident> ), do {
            when $func<args>:exists {$.write( $func, :node<args> )}
            when $func<expr>:exists {$.write( $func, :node<expr> )}
            default {''};
        }
    }

    #| #My-id := $.write-node( :id<My-id> )
    multi method write-node( Str :$id! is copy ) {
        '#' ~ $.write-node( :name($id) );
    }

    #| -Moz-linear-gradient := $.write-node( :ident<-Moz-linear-gradient> )
    multi method write-node( Str :$ident! is copy ) {
        my $pfx = $ident ~~ s/^"-"// ?? '-' !! '';
        my $minus = $ident ~~ s/^"-"// ?? '\\-' !! '';
        [~] $pfx, $minus, $.write-node( :name($ident) )
    }

    #| @import url('example.css') screen and (color); := $.write-node( :import{ :url<example.css>, :media-list[ { :media-query[ { :ident<screen> }, { :keyw<and> }, { :property{ :ident<color> } } ] } ] } )
    multi method write-node( Hash :$import! ) {
        [~] '@import ', join(' ', <url media-list>.grep({ $import{$_}:exists }).map({ $.write( $import, :node($_) ) })), ';';
    }

    #| 42 := $.write-node: :num(42)
    multi method write-node( Numeric :$int! ) {
        $.write-num( $int );
    }

    #| color := $.write-node: :keyw<Color>
    multi method write-node( Str :$keyw! ) {
        $keyw.lc;
    }

    #| 42mm   := $.write-node( :length(42), :units<mm>) or $.write-node( :mm(42) )
    multi method write-node( Numeric :$length!, Any :$units? ) {
        $.write-num( $length, $units );
    }

    #| projection, tv := $.write-node( :media-list[ :ident<projection>, :ident<tv> ] )
    multi method write-node( List :$media-list! ) {
        join(', ', $media-list.map({ $.write( $_ ) }) );
    }

    #| screen and (color) := $.write-node( :media-query[ { :ident<screen> }, { :keyw<and> }, { :property{ :ident<color> } } ] )
    multi method write-node( List :$media-query! ) {
        join(' ', $media-query.map({
            my $css = $.write( $_ );

            if .<property> {
                # e.g. color:blue => (color:blue)
                $css = [~] '(', $css.subst(/';'$/, ''), ')';
            }

            $css
        }) );
    }

    #| @media all { body { background: lime; }} := $.write-node( :media-rule{ :media-list[ { :media-query[ :ident<all> ] } ], :rule-list[ { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<body> } ] } ] ], :declarations[ { :ident<background>, :expr[ :ident<lime> ] } ] } } ]} )
    multi method write-node( Hash :$media-rule! ) {
        ('@media', <media-list rule-list>.grep({ $media-rule{$_}:exists }).map({ $.write( $media-rule, :node($_) ) })).join: ' ';
    }

    #| hi\! := $.write-node( :name("hi\x021") )
    multi method write-node( Str :$name! ) {
        [~] $name.comb.map({
            when /<CSS::Grammar::CSS3::nmreg>/    { $_ };
            when /<CSS::Grammar::CSS3::regascii>/ { '\\' ~ $_ };
            default                               { .ord.fmt("\\%X ") }
        });
    }

    multi method write-node( Hash :$namespace-rule! ) {
        join(' ', '@namespace', <ns-prefix url>.grep({ $namespace-rule{$_}:exists }).map({ $.write( $namespace-rule, :node($_) ) })) ~ ';';
    }

    #| svg := $.write-node( :ns-prefix<svg> )
    multi method write-node( Str :$ns-prefix! ) {
        given $ns-prefix {
            when ''  {''}   # no namespace
            when '*' {'*'}  # wildcard namespace
            default  { $.write-node( :ident($_) ) }
        }
    }

    #| 42 := $.write-node( :num(42) )
    multi method write-node( Any :$num! ) {
        $.write-num( $num )
    }

    #| ~= := $.write-node( :op<~=> )
    multi method write-node( Str :$op! ) {
        $op.lc;
    }

    #| @page :first { margin: 5mm; } := $.write-node( :page-rule{ :pseudo-class<first>, :declarations[ { :ident<margin>, :expr[ :mm(5) ] } ] } )
    multi method write-node( Hash :$page-rule! ) {
        join(' ', '@page', <pseudo-class declarations>.grep({ $page-rule{$_}:exists }).map({ $.write( $page-rule, :node($_) ) }) );
    }

    #| 100% := $.write-node( :percent(100) )
    multi method write-node( :$percent! ) {
        $.write-num( $percent, '%' );
    }

    #| color: red !important; := $.write-node( :property{ :ident<color>, :expr[ :ident<red> ], :prio<important> } )
    multi method write-node( Hash :$property! ) {
        my $expr = $property<expr>:exists
            ?? ': ' ~ $.write($property, :node<expr>)
            !! '';
        my $prio = $property<prio>
            ?? ' !' ~ $property<prio>
            !! '';

        [~] $.write( $property, :node<ident> ), $expr, $prio, ';';
    }

    #| :first := $.write-node: :pseudo-class<first>
    multi method write-node( Str :$pseudo-class! ) {
        ':' ~ $.write-node( :name($pseudo-class) );
    }

    #| ::nth := $.write-node: :pseudo-elem<nth>
    multi method write-node( Str :$pseudo-elem! ) {
        '::' ~ $.write-node( :name($pseudo-elem) );
    }

    #| :lang(klingon) := $.write-node( :pseudo-func{ :ident<lang>, :args[ :ident<klingon> ] } )
    multi method write-node( Hash :$pseudo-func! ) {
        ':' ~ $.write-node( :func($pseudo-func) );
    }

    #| svg|circle := $.write-node( :qname{ :ns-prefix<svg>, :element-name<circle> } )
    multi method write-node( Hash :$qname! ) {
        my $out = $.write($qname, :node<element-name>);
        $out = [~] $.write($qname, :node<ns-prefix>), '|', $out
            if $qname<ns-prefix>:exists;
        $out;
    }

    #| 600dpi   := $.write-node( :resolution(600), :units<dpi>) or $.write-node( :dpi(600) )
    multi method write-node( Numeric :$resolution!, Any :$units? ) {
        $.write-num( $resolution, $units );
    }

    #| { h1 { margin: 5pt; } h2 { margin: 3pt; color: red; }} := $.write-node( :rule-list[ { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<h1> } ] } ] ], :declarations[ { :ident<margin>, :expr[ :pt(5) ] } ] } }, { :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<h2> } ] } ] ], :declarations[ { :ident<margin>, :expr[ :pt(3) ] }, { :ident<color>, :expr[ :ident<red> ] } ] } } ])
    multi method write-node( List :$rule-list! ) {
        '{ ' ~ $rule-list.map( { $.write($_) } ).join($.nl) ~ '}';
    }

    #| a:hover { color: green; } := $.write-node( :ruleset{ :selectors[ :selector[ { :simple-selector[ { :element-name<a> }, { :pseudo-class<hover> } ] } ] ], :declarations[ { :ident<color>, :expr[ :ident<green> ] } ] } )
    multi method write-node( Hash :$ruleset! ) {
        sprintf "%s %s", $.write($ruleset, :node<selectors>), $.write($ruleset, :node<declarations>);
    }

    #| #container * := $.write-node( :selector[ { :id<container>}, { :element-name<*> } ] )
    multi method write-node( List :$selector! ) {
        $selector.map({ $.write( $_ ) }).join(' ');
    }

    #| h1, [lang=en] := $.write-node( :selectors[ :selector[ { :simple-selector[ { :element-name<h1> } ] } ], :selector[ :simple-selector[ { :attrib[ :ident<lang>, :op<=>, :ident<en> ] } ] ] ] )
    multi method write-node( List :$selectors! ) {
        $selectors.map({ $.write( $_ ) }).join(', ');
    }

    #| .foo:bar#baz := $.write-node: :simple-selector[ :class<foo>, :pseudo-class<bar>, :id<baz> ]
    multi method write-node( List :$simple-selector! ) {
        [~] $simple-selector.map({ $.write( $_ ) })
    }

    #| 'Hi\' there\FA !' := $.write-node( :string("Hi' there\x[fa]!") )
    multi method write-node( Str :$string! ) {
        $.write-string($string);
    }

    #| h1 { color: blue; } := $.write-node( :stylesheet[ { :ruleset{ :selectors[ { :selector[ { :simple-selector[ { :qname{ :element-name<h1> } } ] } ] } ], :declarations[ { :ident<color>, :expr[ { :ident<blue> } ] } ] } } ] )
    multi method write-node( List :$stylesheet! ) {
        my $sep = $.terse ?? "\n" !! "\n\n";
        join($sep, $stylesheet.map({ $.write( $_ ) }) );
    }

    #| 20s := $.write-node( :time(20), :units<s> ) or $.write-node( :s(20) )
    multi method write-node( Numeric :$time!, Any :$units? ) {
        $.write-num( $time, $units );
    }

    #| U+A?? := $.write-node( :unicode-range[0xA00, 0xAFF] )
    multi method write-node( List :$unicode-range! ) {
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

    multi method write-node( Str :$url! ) {
        sprintf "url(%s)", $.write-string( $url );
    }

    multi method write-node( *@args, *%opts ) is default {

        die "unexpect arguments: {[@args].perl}"
            if @args;

        use CSS::AST :CSSUnits;
        for %opts.keys {
            if my $type = CSSUnits.enums{$_} {
                # e.g. redispatch $.write-node( :px(12) ) as $.write-node( :length(12), :units<px> )
                my %new-opts = $type => %opts{$_}, units => $_;
                return $.write-node( |%new-opts );
            }
        }
        
        die "unable to handle struct: {%opts.perl}"
    }

}
