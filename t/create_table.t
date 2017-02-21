use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 8;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'basic' => {
    plan 2;

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.table1
            (
                col1 VARCHAR2 (10)
                , col2 NUMBER
            );
        ORACLE
        "CREATE TABLE foo.table1 ( col1 VARCHAR(10), col2 DOUBLE PRECISION );\n",
        'table1';

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.table2
            (
                id          VARCHAR2(10)    NOT NULL PRIMARY KEY,
                name        VARCHAR2(20)    NOT NULL,
                num         VARCHAR2        DEFAULT 123,
                str         VARCHAR2        DEFAULT 'a string'
            );
        ORACLE
        "CREATE TABLE foo.table2 ( id VARCHAR(10) NOT NULL PRIMARY KEY, name VARCHAR(20) NOT NULL, num VARCHAR DEFAULT 123, str VARCHAR DEFAULT 'a string' );\n",
        'column constraints';
}

subtest 'numbers' => {
    plan 5;

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
        "CREATE TABLE foo.table3 ( id DOUBLE PRECISION NOT NULL, num1 SMALLINT, num3 SMALLINT, num5 INT, num9 BIGINT, num19 DECIMAL(19), numAB DECIMAL(10,2) );\n",
        'NUMBER type conversions';

    is $xlate.parse( 'CREATE TABLE foo.ints ( col_a INTEGER );'),
                     "CREATE TABLE foo.ints ( col_a DECIMAL(38) );\n",
        'INTEGER';

    is $xlate.parse( 'CREATE TABLE foo.floats ( col_a FLOAT );'),
                     "CREATE TABLE foo.floats ( col_a DOUBLE PRECISION );\n",
        'FLOAT becomes DOUBLE PRECISION';

    throws-like { $xlate.parse( 'CREATE TABLE foo ( id NUMBER(39,2));' ) },
        Exception, message => /'Out of range'/;
}

subtest 'characters' => {
    plan 1;

    is $xlate.parse( 'CREATE TABLE foo.chartable ( id CHAR(1), thing CHAR(2), blah LONG );'),
                     "CREATE TABLE foo.chartable ( id CHAR(1), thing CHAR(2), blah TEXT );\n",
        'create table';
}

subtest 'LOB' => {
    plan 1;

    is $xlate.parse('CREATE TABLE foo.lobs ( col_a BLOB,  col_b CLOB, col_c RAW(32) );'),
                    "CREATE TABLE foo.lobs ( col_a BYTEA, col_b TEXT, col_c BYTEA );\n",
        'create table';
}

subtest 'time and date' => {
    plan 1;

    is $xlate.parse('CREATE TABLE foo.dates ( a_date DATE,         a_time TIMESTAMP(6) );'),
                    "CREATE TABLE foo.dates ( a_date TIMESTAMP(0), a_time TIMESTAMP(6) );\n",
        'create table';
}

subtest 'table constraints' => {
    plan 2;

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.table_constr (
            col_a VARCHAR2,
            col_b VARCHAR2,
            CONSTRAINT constr_name PRIMARY KEY
                (
                    col_a
                )
        );
        ORACLE
        "CREATE TABLE foo.table_constr ( col_a VARCHAR, col_b VARCHAR, CONSTRAINT constr_name PRIMARY KEY ( col_a ) );\n",
        'PRIMARY KEY';

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.table_constr (
            col_a VARCHAR2
            , col_b VARCHAR2
            , CONSTRAINT constr_name PRIMARY KEY
                (
                    col_a
                    , col_b
                )
        );
        ORACLE
        "CREATE TABLE foo.table_constr ( col_a VARCHAR, col_b VARCHAR, CONSTRAINT constr_name PRIMARY KEY ( col_a, col_b ) );\n",
        '2-column PRIMARY KEY';
}

subtest 'oracle-only add-ons' => {
    plan 2;

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.addon1
        (
            col_a VARCHAR2
        )
        ORGANIZATION    INDEX;
        ORACLE
        "CREATE TABLE foo.addon1 ( col_a VARCHAR );\n",
        'ORGANIZATION INDEX';

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE foo.addon2
        (
            col_a VARCHAR2
        )
        ORGANIZATION    HEAP
        MONITORING
        OVERFLOW;
        ORACLE
        "CREATE TABLE foo.addon2 ( col_a VARCHAR );\n",
        '3 add-ons';
}
