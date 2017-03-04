use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 11;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'NULL' => {
    plan 3;

    is $xlate.parse('SELECT col IS NULL FROM foo;'),
        "SELECT col IS NULL FROM foo;\n",
        'is null';

    is $xlate.parse('SELECT col IS NOT NULL FROM foo;'),
        "SELECT col IS NOT NULL FROM foo;\n",
        'is not null';

    is $xlate.parse('SELECT f.col IS NULL FROM foo f;'),
        "SELECT f.col IS NULL FROM foo AS f;\n",
        'NULL check accepts table.column';
}

subtest 'substr' => {
    plan 2;

    is $xlate.parse('SELECT substr(col1,1) FROM foo;'),
        "SELECT substr( col1, 1 ) FROM foo;\n",
        '2-arg form';

    is $xlate.parse('SELECT substr(col1,1,2) FROM foo;'),
        "SELECT substr( col1, 1, 2 ) FROM foo;\n",
        '3-arg form';
}

subtest 'decode' => {
    plan 2;

    is $xlate.parse(q{SELECT decode(col, -1, col1, '2', col2) FROM foo;}),
        "SELECT ( CASE col WHEN -1 THEN col1 WHEN '2' THEN col2 END ) FROM foo;\n",
        'decode';

    is $xlate.parse(q{SELECT decode(col, -1, col1, '2', col2, NULL) FROM foo;}),
        "SELECT ( CASE col WHEN -1 THEN col1 WHEN '2' THEN col2 ELSE NULL END ) FROM foo;\n",
        'with default case';
}

subtest 'urnary functions' => {
    my @tests = <trunc to_char upper lower sign count sum>;
    plan @tests.elems;

    for @tests -> $func {
        my $sql = 'SELECT %s( col ) FROM foo;'.sprintf($func);
        is $xlate.parse($sql),
            "$sql\n",
            "$func\(\)";
    }
}

subtest 'operators' => {
    plan 3;

    is $xlate.parse('SELECT col-1000 FROM foo;'),
        "SELECT col - 1000 FROM foo;\n",
        'subtraction';

    is $xlate.parse('SELECT col+1000 FROM foo;'),
        "SELECT col + 1000 FROM foo;\n",
        'addition';

    is $xlate.parse('SELECT col=1000 FROM foo;'),
        "SELECT col = 1000 FROM foo;\n",
        'equal';
}

subtest 'CASE' => {
    plan 1;

    is $xlate.parse(q{SELECT CASE WHEN col1 IS NOT NULL THEN col2 WHEN col1 = 1 THEN col3 ELSE col4 END FROM foo;}),
        "SELECT CASE WHEN col1 IS NOT NULL THEN col2 WHEN col1 = 1 THEN col3 ELSE col4 END FROM foo;\n",
        'CASE statement';
}

subtest 'IN' => {
    plan 2;

    is $xlate.parse(q{SELECT col FROM t WHERE col IN (0,1);}),
        "SELECT col FROM t WHERE col IN ( 0, 1 );\n",
        'basic';

    is $xlate.parse(q{SELECT f.col FROM foo f WHERE col IN (0,1);}),
        "SELECT f.col FROM foo AS f WHERE col IN ( 0, 1 );\n",
        'basic';
}

subtest 'and/or' => {
    plan 5;

    is $xlate.parse(q{SELECT col FROM t WHERE col1=1 and col2=2;}),
        "SELECT col FROM t WHERE col1 = 1 and col2 = 2;\n",
        'ANDed';

    is $xlate.parse(q{SELECT col FROM t WHERE col1=1 OR col2=2;}),
        "SELECT col FROM t WHERE col1 = 1 OR col2 = 2;\n",
        'ORed';

    is $xlate.parse(q{SELECT col FROM t WHERE col1=1 and col2=2 AND col3=3;}),
        "SELECT col FROM t WHERE col1 = 1 and col2 = 2 AND col3 = 3;\n",
        'multiple ANDs';

    is $xlate.parse(q{SELECT col FROM t WHERE col1=1 or col2=2 or col3=3;}),
        "SELECT col FROM t WHERE col1 = 1 or col2 = 2 or col3 = 3;\n",
        'multiple ORs';

    is $xlate.parse(q{SELECT col FROM t WHERE col1=1 or col2=2 and col3=3;}),
        "SELECT col FROM t WHERE col1 = 1 or col2 = 2 and col3 = 3;\n",
        'mix of ANDs and ORs';
}

subtest 'parens' => {
    plan 3;

    is $xlate.parse(q{SELECT col FROM t WHERE (col1=1 and col2=2) or (col3=3 and col4=4) or (col5=5 and col6=6);}),
        "SELECT col FROM t WHERE ( col1 = 1 and col2 = 2 ) or ( col3 = 3 and col4 = 4 ) or ( col5 = 5 and col6 = 6 );\n",
        'multiple paren-exprs ORed together';

    is $xlate.parse(q{SELECT col FROM t WHERE (col1=1 and col2=2) or (col3=3 and col4=4) or (col5=5 and col6=6);}),
        "SELECT col FROM t WHERE ( col1 = 1 and col2 = 2 ) or ( col3 = 3 and col4 = 4 ) or ( col5 = 5 and col6 = 6 );\n",
        'multiple paren-exprs ANDed together';

    is $xlate.parse(q{SELECT col FROM t WHERE ( col2=col3);}),
        "SELECT col FROM t WHERE ( col2 = col3 );\n",
        'single expr in parens';
}

subtest 'nested function calls' => {
    plan 2;

    is $xlate.parse(q{SELECT SUBSTR(DECODE(ANALYSIS_APPROVAL,1,FLOW_CELL_ID,NULL),1,16) FROM foo;}),
        "SELECT substr( ( CASE ANALYSIS_APPROVAL WHEN 1 THEN FLOW_CELL_ID ELSE NULL END ), 1, 16 ) FROM foo;\n",
        'substr() and decode()';

    is $xlate.parse('SELECT TO_CHAR(CASE WHEN col1 IS NOT NULL THEN col2 WHEN col1 = 1 THEN col3 ELSE col4 END) FROM foo;'),
        "SELECT to_char( CASE WHEN col1 IS NOT NULL THEN col2 WHEN col1 = 1 THEN col3 ELSE col4 END ) FROM foo;\n",
        'CASE inside to_char()';
}
