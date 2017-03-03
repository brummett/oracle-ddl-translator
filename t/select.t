use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 4;

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

subtest 'AS clause' => {
    plan 1;

    is $xlate.parse(q{SELECT col1 AS alias_col1, col2 AS "alias_col2" FROM foo.table;}),
        "SELECT col1 AS alias_col1, col2 AS \"alias_col2\" FROM foo.table;\n",
        'basic AS';
}

subtest 'WHERE clause' => {
    plan 1;

    is $xlate.parse(q{SELECT col1 FROM foo.table WHERE col2=2;}),
        "SELECT col1 FROM foo.table WHERE col2 = 2;\n",
        'basic WHERE';

}
