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
        SELECT col1,
            col2
            FROM foo.table;
        ORACLE
        "SELECT col1, col2 FROM foo.table;\n",
        'basic select';
}
