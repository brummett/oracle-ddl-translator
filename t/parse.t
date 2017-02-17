use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 4;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'REM' => {
    plan 3;

    my $output = $xlate.parse('REM This is a test');
    is $output, "-- This is a test;\n", 'translated REM';

    is $xlate.parse("REM comment 1\nREM comment 2\nREM comment 3"),
        "-- comment 1;\n-- comment 2;\n-- comment 3;\n",
        'multiple REMs';

    is $xlate.parse("REM comment 1\nREM\nREM comment 3\n"),
        "-- comment 1;\n--;\n-- comment 3;\n",
        'multiple REMs, some with no content';
}
    
subtest 'PROMPT' => {
    plan 3;

    my $output = $xlate.parse('PROMPT This is a test');
    is $output, "\\echo This is a test;\n", 'translated PROMPT';

    is $xlate.parse("PROMPT comment 1\nPROMPT comment 2\nPROMPT comment 3"),
        "\\echo comment 1;\n\\echo comment 2;\n\\echo comment 3;\n",
        'multiple PROMPTs';

    is $xlate.parse("PROMPT comment 1\nPROMPT\nPROMPT comment 3\n"),
        "\\echo comment 1;\n\\echo;\n\\echo comment 3;\n",
        'multiple PROMPTs, some with no content';
}

subtest 'CREATE SEQUENCE' => {
    plan 3;

    is $xlate.parse("CREATE SEQUENCE foo.seqname;"),
        "CREATE SEQUENCE foo.seqname;\n",
        'basic CREATE SEQUENCE';

    is $xlate.parse("CREATE SEQUENCE foo.seqname\nSTART WITH 123 INCREMENT BY 2 MINVALUE 3 NOMAXVALUE;"),
        "CREATE SEQUENCE foo.seqname START WITH 123 INCREMENT BY 2 MINVALUE 3 NO MAXVALUE;\n",
        'CREATE SEQUENCE with some add-ons';

    is $xlate.parse("CREATE SEQUENCE foo.seqname\nSTART WITH 1\n  INCREMENT BY 2\n  NOMINVALUE\n  MAXVALUE 9999999999999999999999999999\n  ORDER;"),
        "CREATE SEQUENCE foo.seqname START WITH 1 INCREMENT BY 2 NO MINVALUE MAXVALUE 9223372036854775807;\n",
        'CREATE SEQUENCE with leading spaces and large number';
}
