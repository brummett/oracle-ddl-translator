use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 2;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'VIEW' => {
    plan 1;

    is $xlate.parse(q:to<ORACLE>,
CREATE OR REPLACE VIEW SCHEMA_USER.foo ( foo_name ) AS
SELECT "FOO" from SCHEMA_USER.foo
ORACLE
                    ),
                    'CREATE OR REPLACE VIEW SCHEMA_USER.foo ( foo_name ) AS SELECT "FOO" from SCHEMA_USER.foo'~"\n;\n",
                    'basic view';
        

}
