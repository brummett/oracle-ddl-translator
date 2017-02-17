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
    is $output, "-- This is a test;", 'translated REM';

    is $xlate.parse("REM comment 1\nREM comment 2\nREM comment 3"),
        "-- comment 1;\n-- comment 2;\n-- comment 3;",
        'multiple REMs';

    is $xlate.parse("REM comment 1\nREM\nREM comment 3\n"),
        "-- comment 1;\n--;\n-- comment 3;",
        'multiple REMs, some with no content';
}
    
subtest 'PROMPT' => {
    plan 3;

    my $output = $xlate.parse('PROMPT This is a test');
    is $output, "\\echo This is a test;", 'translated PROMPT';

    is $xlate.parse("PROMPT comment 1\nPROMPT comment 2\nPROMPT comment 3"),
        "\\echo comment 1;\n\\echo comment 2;\n\\echo comment 3;",
        'multiple PROMPTs';

    is $xlate.parse("PROMPT comment 1\nPROMPT\nPROMPT comment 3\n"),
        "\\echo comment 1;\n\\echo;\n\\echo comment 3;",
        'multiple PROMPTs, some with no content';
}

subtest 'CREATE SEQUENCE' => {
    plan 1;

    is $xlate.parse("CREATE SEQUENCE foo.seqname;"),
        'CREATE SEQUENCE foo.seqname;',
        'basic CREATE SEQUENCE';
}
