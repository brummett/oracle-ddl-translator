use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 2;

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
    
