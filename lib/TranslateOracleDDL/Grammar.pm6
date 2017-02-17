use v6;

use TranslateOracleDDL::Remark;
use TranslateOracleDDL::Prompt;

grammar TranslateOracleDDL::Grammar {
    token TOP {
        <sql-statement>+
    }

    token string-to-end-of-line {
        \V+
    }

    proto rule sql-statement { * }

    token sql-statement:sym<REM> {
        'REM' [ \h+ <string-to-end-of-line> ]? \v?
    }

    token sql-statement:sym<PROMPT> {
        'PROMPT' [ \h+ <string-to-end-of-line> ]? \v?
    }

    token identifier { \w+ }
    token integer { \d+ }
    token entity-name {
        [ <identifier> '.' ]? <identifier>  # either "name" or "schema.name"
    }

    token sql-statement:sym<CREATE-SEQUENCE> {
        'CREATE SEQUENCE' <ws> <entity-name> [ <ws> <create-sequence-clause> ]* <ws>*? ';'
    }

    proto rule create-sequence-clause { * }
}

