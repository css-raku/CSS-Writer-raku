use v6;

use CSS::Writer;
use Test;

plan 6;

my CSS::Writer $writer .= new( :ast( :string('Hello World!' ) ) );
my CSS::Writer $writer2 .= new;
lives-ok { ~$writer }, 'writer stringification';
is ~$writer, q<'Hello World!'>,'writer stringification';
is $writer.write( :keyw<Hi> ), 'hi', 'write keyw';
is $writer2.write( :int(42) ), '42', 'write int';
dies-ok { $writer2.write() }, "can't write nothing";
ok ~$writer2 ~~ /^'CSS::Writer'/, "can stringify nothing"
    or diag "stringifed to: $writer2";


