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
    plan 1;

    is $xlate.parse('CREATE INDEX foo.i ON foo.table ( col1 ) COMPRESS 1;'),
        "CREATE INDEX foo.i ON foo.table ( col1 );\n",
        'COMPRESS option is dropped';
}

subtest 'functional index' => {
    plan 1;

    is $xlate.parse('CREATE INDEX foo.fi ON foo.table ( substr(col, 1), substr(col2, 2, 3) );'),
        "CREATE INDEX foo.fi ON foo.table ( substr( col, 1 ), substr( col2, 2, 3 ) );\n",
        'substr functional index';
}
