use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 3;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'basic' => {
    plan 2;

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

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.table2
            (
                id          VARCHAR2(10)    NOT NULL PRIMARY KEY,
                name        VARCHAR2(20)    NOT NULL
            );
        ORACLE
        "CREATE TABLE foo.table2 ( id VARCHAR(10) NOT NULL PRIMARY KEY, name VARCHAR(20) NOT NULL );\n",
        'with NOT NULL constraint';
}

subtest 'NUMBER' => {
    plan 2;

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.table3 (
            id      NUMBER NOT NULL
            , num1  NUMBER  (1)
            , num3  NUMBER  (3)
            , num5  NUMBER  (5)
            , num9  NUMBER  (9)
            , num19 NUMBER  (19)
            , numAB NUMBER  (10,2)
            );
        ORACLE
        "CREATE TABLE foo.table3 ( id INT NOT NULL, num1 SMALLINT, num3 SMALLINT, num5 INT, num9 BIGINT, num19 DECIMAL(19), numAB DECIMAL(10,2) );\n",
        'NUMBER type conversions';

    throws-like { $xlate.parse( 'CREATE TABLE foo ( id NUMBER(39));' ) },
        Exception, message => /'Out of range'/;
}
