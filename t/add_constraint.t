use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 6;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'primary key' => {
    plan 4;

    is $xlate.parse("ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name PRIMARY KEY ( id );"),
        "ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name PRIMARY KEY ( id );\n",
        'basic 1-column pk';

    is $xlate.parse('ALTER TABLE foo.pk ADD CONSTRAINT pk$constr_name PRIMARY KEY ( id );'),
        "ALTER TABLE foo.pk ADD CONSTRAINT pk\$constr_name PRIMARY KEY ( id );\n",
        '1-column pk where the name has a dollar sign';

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

subtest 'UNIQUE' => {
    plan 2;

    is $xlate.parse("ALTER TABLE foo.uk ADD CONSTRAINT uk_constr_name UNIQUE ( id );"),
        "ALTER TABLE foo.uk ADD CONSTRAINT uk_constr_name UNIQUE ( id );\n",
        'basic 1-col unique';

    is $xlate.parse(q :to<ORACLE>),
        ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name UNIQUE
            (
                id1
                , id2
            )
            DEFERRABLE
            INITIALLY DEFERRED
            ENABLE NOVALIDATE;
        ORACLE
        "ALTER TABLE foo.pk ADD CONSTRAINT pk_constr_name UNIQUE ( id1, id2 ) DEFERRABLE INITIALLY DEFERRED;\n",
        '2-column pk with deferrable options';
}

subtest 'CHECK' => {
    plan 10;

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ("col_name" IS NOT NULL);'),
        qq{ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( "col_name" IS NOT NULL );\n},
        '"column" is not null';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ("col_name" is null);'),
        qq{ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( "col_name" is null );\n},
        '"column" is null (lower case)';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK (col_name=1);'),
        "ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( col_name = 1 );\n",
        'column value = 1';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK (NOT(col_name=1));'),
        "ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( NOT( col_name = 1 ) );\n",
        'NOT column value = 1';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK (col_name in (0,1));'),
        "ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( col_name IN ( 0, 1 ) );\n",
        'column IN list';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK (col_name=1 and col2=3);'),
        "ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( col_name = 1 and col2 = 3 );\n",
        'AND 2 simple expressions';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK (col_name=1 or col2=3);'),
        "ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( col_name = 1 or col2 = 3 );\n",
        'OR 2 simple expressions';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ((col1=1 and col2=2) or (col3=3 and col4=4));'),
        "ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( ( col1 = 1 and col2 = 2 ) or ( col3 = 3 and col4 = 4 ) );\n",
        'OR 2 ANDed exprs';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ((col1=1 or col2=2) and (col3=3 or col4=4));'),
        "ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( ( col1 = 1 or col2 = 2 ) and ( col3 = 3 or col4 = 4 ) );\n",
        'AND 2 ORed exprs';

    is $xlate.parse('ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ((col1=1 AND col2=2) OR (col3=3 and col4=4) or (col5=5 and col6=6));'),
        "ALTER TABLE foo.check ADD CONSTRAINT ck_constr CHECK ( ( col1 = 1 AND col2 = 2 ) OR ( col3 = 3 and col4 = 4 ) or ( col5 = 5 and col6 = 6 ) );\n",
        'OR 2 ANDed exprs';
}

subtest 'FOREIGN KEY' => {
    plan 2;

    is $xlate.parse('ALTER TABLE foo.fk ADD CONSTRAINT fk_constr FOREIGN KEY ( col ) REFERENCES other.table ( other_col );'),
        "ALTER TABLE foo.fk ADD CONSTRAINT fk_constr FOREIGN KEY ( col ) REFERENCES other.table ( other_col );\n",
        'FK with one column';

    is $xlate.parse('ALTER TABLE foo.fk ADD CONSTRAINT fk_constr FOREIGN KEY ( col1, col2 ) REFERENCES other.table ( other1, other2 );'),
        "ALTER TABLE foo.fk ADD CONSTRAINT fk_constr FOREIGN KEY ( col1, col2 ) REFERENCES other.table ( other1, other2 );\n",
        'FK with one column';
}

subtest 'DISABLEd' => {
    plan 2;

    is $xlate.parse('ALTER TABLE foo.ck ADD CONSTRAINT ck_constr CHECK (col_name = 1) NOT DEFERRABLE INITIALLY IMMEDIATE DISABLE;'),
        "\n",
        'DISABLEd constraints disappear';

    is $xlate.parse(q :to<ORACLE>),
        ALTER TABLE foo. ADD CONSTRAINT bin$hwvvsoqjce/gu4ocaaqrog==$0
            CHECK ()
            (

            )

            INITIALLY
            DISABLE;
        ORACLE
        "\n",
        'broken CHECK constraint disappears';
}
