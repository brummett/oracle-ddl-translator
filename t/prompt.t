use v6;

use TranslateOracleDDL::Prompt;
use Test;

plan 4;

dies-ok { TranslateOracleDDL::Prompt.new() },
        'new() with no args dies';

my $string = 'this is a comment';
my $prompt = TranslateOracleDDL::Prompt.new(string => $string);

ok $prompt, 'Created Prompt';
is $prompt.string, $string, 'string matches';

is $prompt.to-pg, "\\echo $string", 'to-pg';
