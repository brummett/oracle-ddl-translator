use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 2;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'basic' => {
    plan 1;

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.table1
            (
                col1 VARCHAR2 (10)
                , col2 NUMBER
                , when DATE
            );
        ORACLE
        "CREATE TABLE foo.table1 ( col1 VARCHAR(10), col2 INT, when TIMESTAMP(0) );\n",
        'table1';
}
