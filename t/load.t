use v6;

use TranslateOracleDDL;
use Test;

plan 1;

class DummyTranslator { }

my $xlate = TranslateOracleDDL.new(translator => DummyTranslator.new);

ok $xlate, 'Created translator';
