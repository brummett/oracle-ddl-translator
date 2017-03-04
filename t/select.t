use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 6;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'basic' => {
    plan 3;

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

    is $xlate.parse(q{SELECT "col" from foo.table;}),
        qq{SELECT "col" FROM foo.table;\n},
        'case-insensitive';
}

subtest 'column AS clause' => {
    plan 2;

    is $xlate.parse(q{SELECT col1 AS alias_col1, col2 as "alias_col2" FROM foo.table;}),
        "SELECT col1 AS alias_col1, col2 AS \"alias_col2\" FROM foo.table;\n",
        'basic AS';

    is $xlate.parse(q{SELECT col1 "alias_col", col2 AS alias_col2 FROM foo.table;}),
        qq{SELECT col1 AS "alias_col", col2 AS alias_col2 FROM foo.table;\n},
        'implied AS';
}

subtest 'WHERE clause' => {
    plan 2;

    is $xlate.parse(q{SELECT col1 FROM foo.table WHERE col2=2;}),
        "SELECT col1 FROM foo.table WHERE col2 = 2;\n",
        'basic WHERE';

    is $xlate.parse(q{SELECT col1 FROM foo.t WHERE col1=1 and col2=2 AND col3=3;}),
        "SELECT col1 FROM foo.t WHERE col1 = 1 and col2 = 2 AND col3 = 3;\n",
        'WHERE with composite expr';
}

subtest 'join' => {
    plan 3;

    is $xlate.parse(q{SELECT schema.table1.col1, schema.table2.col2 FROM schema.table1, schema.table2;}),
        "SELECT schema.table1.col1, schema.table2.col2 FROM schema.table1, schema.table2;\n",
        'simple join';

    is $xlate.parse(q{SELECT col FROM foo.table JOIN other o on o.id = foo.table.id;}),
        "SELECT col FROM foo.table JOIN other AS o ON o.id = foo.table.id;\n",
        'regular join';

    is $xlate.parse(q :to<ORACLE>),
        SELECT col FROM foo.table
            JOIN other1 o1 on o1.id = foo.table.id
            JOIN other2 AS o2 on o2.id = o1.id
            JOIN other3 "o3" on o3.id = o2.id;
        ORACLE
        "SELECT col FROM foo.table JOIN other1 AS o1 ON o1.id = foo.table.id JOIN other2 AS o2 ON o2.id = o1.id JOIN other3 AS \"o3\" ON o3.id = o2.id;\n",
        'multiple joins';
}

subtest 'table AS clause' => {
    plan 2;

    is $xlate.parse(q{SELECT t.col FROM table AS t;}),
        "SELECT t.col FROM table AS t;\n",
        'basic AS';

    is $xlate.parse(q{SELECT t.col FROM table t;}),
        "SELECT t.col FROM table AS t;\n",
        'implied AS';
}
