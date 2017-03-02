use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 2;

subtest 'no schema change' => {
    plan 2;

    my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
    ok $xlate, 'created translator';

    is $xlate.parse('CREATE SEQUENCE foo.seqname;'),
        "CREATE SEQUENCE foo.seqname;\n",
        'translated';
}

subtest 'change schema name' => {
    plan 3;

    my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new(schema => 'bar'));
    ok $xlate, 'created translator';

    is $xlate.parse('CREATE SEQUENCE foo.seqname;'),
        "CREATE SEQUENCE bar.seqname;\n",
        'changed schema.table';

    is $xlate.parse("COMMENT ON COLUMN foo.table.column IS 'hi there';"),
        "COMMENT ON COLUMN bar.table.column IS 'hi there';\n",
        'changed schema.table.column';
}
