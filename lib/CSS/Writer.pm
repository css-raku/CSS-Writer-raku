use v6;

use CSS::Writer::Node;

class CSS::Writer
    is CSS::Writer::Node {

    use CSS::AST;
    has Str $.indent is rw = '';
    has Bool $.terse is rw = False;

    method nl {
        $.terse ?? ' ' !! "\n";
    }

    method write($ast, :$node, :$indent?) {

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
                .subst(/':'.*/, '').subst(/\@/, 'at-keyw') => $ast{$_};
            }

            %params = $node => %params{$node}
                if $node.defined;

            $sp ~ $.write-node( |%params );
        }
        else {
            warn "dunno how to dispatch: {$ast.perl}";
        }

    }

}
