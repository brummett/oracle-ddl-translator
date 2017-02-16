use v6;

use TranslateOracleDDL::Remark;
use Test;

plan 4;

dies-ok { TranslateOracleDDL::Remark.new() },
        'new() with no args dies';

my $string = 'this is a comment';
my $rem = TranslateOracleDDL::Remark.new(string => $string);

ok $rem, 'Created Remark';
is $rem.string, $string, 'string matches';

is $rem.to-pg, "-- $string", 'to-pg';
