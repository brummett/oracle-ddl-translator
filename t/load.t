use v6;

use TranslateOracleDDL;
use Test;

plan 1;

my $xlate = TranslateOracleDDL.new();

ok $xlate, 'Created translator';
