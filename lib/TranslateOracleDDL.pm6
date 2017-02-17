use v6;

use TranslateOracleDDL::Grammar;

class TranslateOracleDDL {
    has TranslateOracleDDL::Grammar $!grammar;
    has $.translator is required;

    method parse(Str $string) {
        $!grammar.parse($string, actions => $.translator);
    }
}

