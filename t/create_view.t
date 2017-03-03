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

    is $xlate.parse('CREATE OR REPLACE VIEW foo.view ( col ) AS SELECT col FROM foo.table;'),
        "CREATE OR REPLACE VIEW foo.view ( col ) AS SELECT col FROM foo.table;\n",
        'create or replace view';
}

subtest 'read-only' => {
    plan 1;

    is $xlate.parse('CREATE VIEW foo.v ( col ) AS SELECT col FROM foo.t WITH READ ONLY;'),
        "CREATE VIEW foo.v ( col ) AS SELECT col FROM foo.t;\n",
        'WITH READ ONLY is dropped';
}
