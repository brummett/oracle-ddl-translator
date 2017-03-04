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
    plan 2;

    is $xlate.parse('CREATE INDEX foo.fi ON foo.table ( substr(col, 1), substr(col2, 2, 3) );'),
        "CREATE INDEX foo.fi ON foo.table ( substr( col, 1 ), substr( col2, 2, 3 ) );\n",
        'substr functional index';

    is $xlate.parse(q{CREATE INDEX foo.decode ON foo.table ( DECODE(col, -1, col1, '2', col2, NULL) );}),
        "CREATE INDEX foo.decode ON foo.table ( ( CASE col WHEN -1 THEN col1 WHEN '2' THEN col2 ELSE NULL END ) );\n",
        'decode functional index';
}
