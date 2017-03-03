use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 2;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'basic' => {
    plan 2;

    is $xlate.parse( q :to<ORACLE> ),
        SELECT col1,
            col2
            FROM foo.table;
        ORACLE
        "SELECT col1, col2 FROM foo.table;\n",
        'basic select';

    is $xlate.parse(q{SELECT col1, decode(sign(col2), -1, 'foo', NULL) FROM foo.table;}),
        "SELECT col1, ( CASE sign( col2 ) WHEN -1 THEN 'foo' ELSE NULL END ) FROM foo.table;\n",
        'function in place of column';
}
