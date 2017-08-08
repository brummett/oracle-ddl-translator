use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 3;

for (False, True) -> $create-table-if-not-exists {
    subtest "with create-table-if-not-exists flag $create-table-if-not-exists" => {
        plan 9;

        my $create-table = $create-table-if-not-exists ?? 'CREATE TABLE IF NOT EXISTS' !! 'CREATE TABLE';

        my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new(:$create-table-if-not-exists));
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
                "$create-table foo.table1 ( col1 VARCHAR(10), col2 NUMERIC );\n",
                'table1';

            is $xlate.parse( q :to<ORACLE> ),
                CREATE TABLE foo.table2
                    (
                        id          VARCHAR2(10)    NOT NULL PRIMARY KEY,
                        name        VARCHAR2(20)    NOT NULL,
                        num         VARCHAR2        DEFAULT 123,
                        str         VARCHAR2        DEFAULT 'a string',
                        ts          TIMESTAMP(6)    DEFAULT systimestamp
                    );
                ORACLE
                "$create-table foo.table2 ( id VARCHAR(10) NOT NULL PRIMARY KEY, name VARCHAR(20) NOT NULL, num VARCHAR DEFAULT 123, str VARCHAR DEFAULT 'a string', ts TIMESTAMP(6) DEFAULT LOCALTIMESTAMP );\n",
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
                "$create-table foo.table3 ( id NUMERIC NOT NULL, num1 SMALLINT, num3 SMALLINT, num5 INT, num9 BIGINT, num19 DECIMAL(19), numAB DECIMAL(10,2) );\n",
                'NUMBER type conversions';

            is $xlate.parse( 'CREATE TABLE foo.ints ( col_a INTEGER );'),
                             "$create-table foo.ints ( col_a DECIMAL(38) );\n",
                'INTEGER';

            is $xlate.parse( 'CREATE TABLE foo.floats ( col_a FLOAT );'),
                             "$create-table foo.floats ( col_a DOUBLE PRECISION );\n",
                'FLOAT becomes DOUBLE PRECISION';

            throws-like { $xlate.parse( 'CREATE TABLE foo ( id NUMBER(39));' ) },
                Exception, message => /'Out of range'/;

            throws-like { $xlate.parse( 'CREATE TABLE foo ( id NUMBER(39,2));' ) },
                Exception, message => /'Out of range'/;
        }

        subtest 'characters' => {
            plan 1;

            is $xlate.parse( 'CREATE TABLE foo.chartable ( id CHAR(1), thing CHAR(2), blah LONG );'),
                             "$create-table foo.chartable ( id CHAR(1), thing CHAR(2), blah TEXT );\n",
                'create table';
        }

        subtest 'LOB' => {
            plan 1;

            is $xlate.parse('CREATE TABLE foo.lobs ( col_a BLOB,  col_b CLOB, col_c RAW(32) );'),
                            "$create-table foo.lobs ( col_a BYTEA, col_b TEXT, col_c BYTEA );\n",
                'create table';
        }

        subtest 'time and date' => {
            plan 1;

            is $xlate.parse('CREATE TABLE foo.dates ( a_date DATE,         a_time TIMESTAMP(6) );'),
                            "$create-table foo.dates ( a_date TIMESTAMP(0), a_time TIMESTAMP(6) );\n",
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
                "$create-table foo.table_constr ( col_a VARCHAR, col_b VARCHAR, CONSTRAINT constr_name PRIMARY KEY ( col_a ) );\n",
                'PRIMARY KEY';

            is $xlate.parse( q :to<ORACLE> ),
                CREATE TABLE foo.table_constr (
                    col_a VARCHAR2
                    , col_b VARCHAR2
                    , CONSTRAINT constr_name2 PRIMARY KEY
                        (
                            col_a
                            , col_b
                        )
                );
                ORACLE
                "$create-table foo.table_constr ( col_a VARCHAR, col_b VARCHAR, CONSTRAINT constr_name2 PRIMARY KEY ( col_a, col_b ) );\n",
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
                "$create-table foo.addon1 ( col_a VARCHAR );\n",
                'ORGANIZATION INDEX';

            is $xlate.parse( q :to<ORACLE> ),
                CREATE TABLE foo.addon2
                (
                    col_a VARCHAR2
                )
                ORGANIZATION    HEAP
                ORGANIZATION
                MONITORING
                PCTTHRESHOLD 50
                OVERFLOW;
                ORACLE
                "$create-table foo.addon2 ( col_a VARCHAR );\n",
                'more add-ons';
        }

        subtest 'COMMENT ON' => {
            plan 3;

            is $xlate.parse("COMMENT ON TABLE foo.comment IS 'hi there';"),
                "COMMENT ON TABLE foo.comment IS 'hi there';\n",
                'table';

            is $xlate.parse("COMMENT ON COLUMN schema.foo.comment IS 'hi there';"),
                "COMMENT ON COLUMN schema.foo.comment IS 'hi there';\n",
                'column';

            is $xlate.parse("COMMENT ON COLUMN a.b.c IS 'this string''s funky';"),
                "COMMENT ON COLUMN a.b.c IS 'this string''s funky';\n",
                'string with embedded quote';
        }
    }
}

subtest 'omit tables' => {
    plan 4;

    my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new(:omit-tables('foo','baz')));
    ok $xlate, 'created translator';

    is $xlate.parse( q :to<ORACLE> ),
        CREATE TABLE schema.foo (col1 VARCHAR2);
        ALTER TABLE schema.foo ADD CONSTRAINT schema_foo_ck CHECK ( col1 IS NOT NULL );
        CREATE INDEX foo_idx ON schema.foo (col1);
        ORACLE
        "\n",
        'Table/constraint/index foo was skipped';

    is $xlate.parse('CREATE TABLE schema.bar (col1 VARCHAR2);'),
        "CREATE TABLE schema.bar ( col1 VARCHAR );\n",
        'Table bar was translated';

    is $xlate.parse('CREATE TABLE schema.baz (col1 VARCHAR2);'),
        "\n",
        'Table baz was skipped';
}
