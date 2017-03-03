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
        CREATE VIEW foo.view
            (
                view_col1
                , view_col2
            )
            AS
            SELECT col1,
            col2
            FROM foo.table;
        ORACLE
        "CREATE VIEW foo.view ( view_col1, view_col2 ) AS SELECT col1, col2 FROM foo.table;\n",
        'basic create view';
}
