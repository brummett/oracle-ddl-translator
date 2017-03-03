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
        CREATE INDEX foo.idx1 ON foo.table1
            (
                col1
                , col2
            );
        ORACLE
        "CREATE INDEX foo.idx1 ON foo.table1 ( col1, col2 );\n",
        'index';

    is $xlate.parse('CREATE UNIQUE INDEX foo.uniq ON foo.table ( col1 );'),
        "CREATE UNIQUE INDEX foo.uniq ON foo.table ( col1 );\n",
        'unique index';
}

subtest 'index options' => {
    plan 2;

    is $xlate.parse('CREATE INDEX foo.i ON foo.table ( col1 ) COMPRESS 1;'),
        "CREATE INDEX foo.i ON foo.table ( col1 );\n",
        'COMPRESS option is dropped';

    is $xlate.parse(q :to<ORACLE> ),
        CREATE INDEX foo.part ON foo.table
            (
                col
            )
            GLOBAL PARTITION BY RANGE
            (
                col
            )
            (
                PARTITION part1 VALUES LESS THAN
                    (
                        '1'
                    )
                , PARTITION part2 VALUES LESS THAN
                    (
                        '2'
                    )
                , PARTITION part3 VALUES LESS THAN
                    (
                        '3'
                    )
            );
        ORACLE
        "CREATE INDEX foo.part ON foo.table ( col );\n",
        'GLOBAL PARTITION BY RANGE is dropped';
}

subtest 'functional index' => {
    plan 9;

    is $xlate.parse('CREATE INDEX foo.fi ON foo.table ( substr(col, 1), substr(col2, 2, 3) );'),
        "CREATE INDEX foo.fi ON foo.table ( substr( col, 1 ), substr( col2, 2, 3 ) );\n",
        'substr functional index';

    is $xlate.parse(q{CREATE INDEX foo.decode ON foo.table ( DECODE(col, 1, col1, '2', col2, NULL) );}),
        "CREATE INDEX foo.decode ON foo.table ( ( CASE col WHEN 1 THEN col1 WHEN '2' THEN col2 ELSE NULL END ) );\n",
        'decode functional index';

    is $xlate.parse(q :to<ORACLE> ),
        CREATE INDEX foo.bar ON foo.table
            (
                SUBSTR(DECODE(ANALYSIS_APPROVAL,1,FLOW_CELL_ID,NULL),1,16)
            );
        ORACLE
        "CREATE INDEX foo.bar ON foo.table ( substr( ( CASE ANALYSIS_APPROVAL WHEN 1 THEN FLOW_CELL_ID ELSE NULL END ), 1, 16 ) );\n",
        'real example with nested function calls';

    is $xlate.parse('CREATE INDEX foo.idx ON foo.table ( TRUNC(column_name) );'),
        "CREATE INDEX foo.idx ON foo.table ( trunc( column_name ) );\n",
        'trunc function';

    is $xlate.parse('CREATE INDEX foo.idx ON foo.table ( TO_CHAR(column_name) );'),
        "CREATE INDEX foo.idx ON foo.table ( to_char( column_name ) );\n",
        'to_char function';

    is $xlate.parse('CREATE INDEX foo.idx ON foo.table ( TO_CHAR(CASE WHEN col1 IS NOT NULL THEN col2 WHEN col1 = 1 THEN col3 ELSE col4 END));'),
        "CREATE INDEX foo.idx ON foo.table ( to_char( CASE WHEN col1 IS NOT NULL THEN col2 WHEN col1 = 1 THEN col3 ELSE col4 END ) );\n",
        'CASE inside to_char()';

    is $xlate.parse('CREATE INDEX foo.upper ON foo.table ( UPPER(BARCODE) );'),
        "CREATE INDEX foo.upper ON foo.table ( upper( BARCODE ) );\n",
        'upper function';

    is $xlate.parse('CREATE INDEX foo.lower ON foo.table ( LOWER(BARCODE) );'),
        "CREATE INDEX foo.lower ON foo.table ( lower( BARCODE ) );\n",
        'lower function';

    is $xlate.parse('CREATE INDEX foo.sign ON foo.table ( sign(col) );'),
        "CREATE INDEX foo.sign ON foo.table ( sign( col ) );\n",
        'sign function';
}
