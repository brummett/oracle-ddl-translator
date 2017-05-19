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

subtest 'quoted identifiers' => {
    plan 5;

    is $xlate.parse('CREATE VIEW foo.quotes ( col ) AS SELECT "col" from foo.t;'),
        qq{CREATE VIEW foo.quotes ( col ) AS SELECT "col" FROM foo.t;\n},
        'pass-through with quoted column name';

    is $xlate.parse('CREATE VIEW foo.v ( col ) AS SELECT "col" AS col_name from foo.t;'),
        qq{CREATE VIEW foo.v ( col ) AS SELECT "col" AS col_name FROM foo.t;\n},
        'pass-through with quoted column name and alias';

    my $no-quotes = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new(:omit-quotes-in-identifiers));
    ok $no-quotes, 'Create translator to remove quotes';

    is $no-quotes.parse('CREATE VIEW foo.v ( col ) AS SELECT "col" from foo.t;'),
        qq{CREATE VIEW foo.v ( col ) AS SELECT col FROM foo.t;\n},
        'remove quotes with quoted column name';

    is $no-quotes.parse('CREATE VIEW foo.v ( col ) AS SELECT "col" AS col_name from foo.t;'),
        qq{CREATE VIEW foo.v ( col ) AS SELECT col AS col_name FROM foo.t;\n},
        'remove-quotes with quoted column name and alias';
}
