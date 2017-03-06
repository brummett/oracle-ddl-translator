use v6;

use TranslateOracleDDL::Grammar;

class TranslateOracleDDL {
    has TranslateOracleDDL::Grammar $!grammar;
    has $.translator is required;

    method parse(Str $string) returns Str {
        my $parsed = $!grammar.parse($string, actions => $.translator);

        die "Didn't parse: { $!grammar.last-parse-location }" unless $parsed;
        return $parsed.made;
    }
}

