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
