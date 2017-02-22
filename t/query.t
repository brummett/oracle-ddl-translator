use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 2;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'SELECT' => {
    plan 1;

    is $xlate.parse('SELECT "COLUMN_NAME" from SCHEMA.TABLE_NAME'),
        'SELECT "COLUMN_NAME" FROM SCHEMA.TABLE_NAME;' ~ "\n",
        'basic SELECT';
        

}
