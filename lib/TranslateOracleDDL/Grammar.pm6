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

    token sql-statement:sym<empty-line> {  # happens between statements
        \v+
    }

    token identifier { \w+ }
    token bigint { \d+ }
    token integer { \d+ }
    token entity-name {
        [ <identifier> '.' ]? <identifier>  # either "name" or "schema.name"
    }

    token sql-statement:sym<CREATE-SEQUENCE> {
        'CREATE SEQUENCE' <ws> <entity-name> [ <ws> <create-sequence-clause> ]* <ws>*? ';'
    }

    proto token create-sequence-clause { * }
    token create-sequence-clause:sym<START-WITH>     { 'START WITH' <ws> <bigint> }
    token create-sequence-clause:sym<INCREMENT-BY>   { 'INCREMENT BY' <ws> <bigint> }
    token create-sequence-clause:sym<MINVALUE>       { 'MINVALUE' <ws> <bigint> }
    token create-sequence-clause:sym<NOMINVALUE>     { 'NOMINVALUE' }
    token create-sequence-clause:sym<MAXVALUE>       { 'MAXVALUE' <ws> <bigint> }
    token create-sequence-clause:sym<NOMAXVALUE>     { 'NOMAXVALUE' }
    token create-sequence-clause:sym<CACHE>          { 'CACHE' <ws> <bigint> }
    token create-sequence-clause:sym<NOCACHE>        { 'NOCACHE' }
    token create-sequence-clause:sym<CYCLE>          { 'CYCLE' }
    token create-sequence-clause:sym<NOCYCLE>        { 'NOCYCLE' }
    token create-sequence-clause:sym<ORDER>          { 'ORDER' }
    token create-sequence-clause:sym<NOORDER>        { 'NOORDER' }

    rule sql-statement:sym<CREATE-TABLE> {
        'CREATE TABLE'
        <entity-name>
        '(' <create-table-column-list> ')'
        ';'
    }

    rule create-table-column-list { <create-table-column-def>+ % ',' }

    rule create-table-column-def { <identifier> <column-type> <create-table-column-constraint>* }

    proto rule column-type { * }
    rule column-type:sym<VARCHAR2>  { 'VARCHAR2'    [ '(' <integer> ')' ]? }
    rule column-type:sym<NUMBER>    { 'NUMBER'      [ '(' <integer> ')' ]? }
    rule column-type:sym<DATE>      { 'DATE' }

    proto rule create-table-column-constraint { * }
    rule create-table-column-constraint:sym<NOT-NULL> { 'NOT NULL' }
    rule create-table-column-constraint:sym<PRIMARY-KEY> { 'PRIMARY KEY' }
}

