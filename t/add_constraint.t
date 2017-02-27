use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 2;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'primary key' => {
    plan 3;

    is $xlate.parse("ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name PRIMARY KEY ( id );"),
        "ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name PRIMARY KEY ( id );\n",
        'basic 1-column pk';

    is $xlate.parse("ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name PRIMARY KEY ( id1, id2 );"),
        "ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name PRIMARY KEY ( id1, id2 );\n",
        '2-column pk';

    is $xlate.parse(q :to<ORACLE>),
        ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name PRIMARY KEY
            (
                id1
                , id2
            )
            NOT DEFERRABLE
            INITIALLY IMMEDIATE
            ENABLE NOVALIDATE;
        ORACLE
        "ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name PRIMARY KEY ( id1, id2 ) NOT DEFERRABLE INITIALLY IMMEDIATE;\n",
        '2-column pk with deferrable options';
}
