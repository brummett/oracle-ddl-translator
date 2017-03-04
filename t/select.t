use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 10;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'basic' => {
    plan 4;

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

    is $xlate.parse(qq"SELECT col from foo\0;"),
        "SELECT col FROM foo;\n",
        'null chars are dropped';
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
    plan 6;

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

    is $xlate.parse('SELECT col FROM table OUTER JOIN other1 ON other1.id = table.id;'),
        "SELECT col FROM table OUTER JOIN other1 ON other1.id = table.id;\n",
        'outer join';

    is $xlate.parse('SELECT col FROM table LEFT JOIN other1 ON other1.id = table.id;'),
        "SELECT col FROM table LEFT JOIN other1 ON other1.id = table.id;\n",
        'left join';

    is $xlate.parse('SELECT col FROM table LEFT OUTER JOIN other1 ON other1.id = table.id;'),
        "SELECT col FROM table LEFT OUTER JOIN other1 ON other1.id = table.id;\n",
        'left outer join';
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

subtest 'DISTINCT' => {
    plan 2;

    is $xlate.parse(q{SELECT DISTINCT col FROM t;}),
        "SELECT DISTINCT col FROM t;\n",
        '1 column';

    is $xlate.parse(q{SELECT DISTINCT col1, col2, col3 FROM t;}),
        "SELECT DISTINCT col1, col2, col3 FROM t;\n",
        'multiple columns';
}

subtest 'inline view' => {
    plan 3;

    is $xlate.parse(q :to<ORACLE>),
        SELECT col
        FROM (
            SELECT inner AS col
            FROM t
        );
        ORACLE
        "SELECT col FROM ( SELECT inner AS col FROM t );\n",
        'inline view';

    is $xlate.parse(q :to<ORACLE>),
        SELECT v.col
        FROM (
            SELECT inner AS col
            FROM t
        ) AS v;
        ORACLE
        "SELECT v.col FROM ( SELECT inner AS col FROM t ) AS v;\n",
        'inline view with alias';

    is $xlate.parse(q :to<ORACLE>),
        SELECT v.col
        FROM (
            SELECT inner
            FROM (
                SELECT inner2
                FROM inner_table
            )
        ) AS v;
        ORACLE
        "SELECT v.col FROM ( SELECT inner FROM ( SELECT inner2 FROM inner_table ) ) AS v;\n",
        'nested inline view';
}

subtest 'group-by' => {
    plan 1;

    is $xlate.parse('SELECT col1, col2, sum(value) FROM t GROUP BY col1, col2;'),
        "SELECT col1, col2, sum( value ) FROM t GROUP BY col1, col2;\n",
        'group by';

}

subtest 'db link' => {
    plan 2;

    is $xlate.parse('SELECT col FROM table@dw;'),
        "SELECT col FROM table;\n",
        'db link is dropped in FROM table';

    is $xlate.parse('SELECT col FROM t JOIN other@oltp ON other.id = t.id;'),
        "SELECT col FROM t JOIN other ON other.id = t.id;\n",
        'db link is dropped from JOIN table';
}
