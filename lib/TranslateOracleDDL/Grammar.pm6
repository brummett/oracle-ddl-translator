use v6;

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

    proto token identifier { * }
    token identifier:sym<bareword> { \w+ }
    token identifier:sym<qq> {
        '"'
        [ <-["]>+:
            | '""'
        ]*
        '"'
    }
    token bigint { \d+ }
    token integer { \d+ }
    token entity-name {
        <identifier>** 1..3 % '.' # accepts "name" or "table.name" or "schema.table.name"
    }

    proto token value { * }
    token value:sym<number-value> { \d+ }
    token value:sym<string-value> {
        "'"
        [ <-[']>+:
            | "''"
        ]*
        "'"
    }
    token value:sym<systimestamp-function> { 'systimestamp' }

    token identifier-or-value           { <identifier> | <value> }

    token and-or-keyword                { :ignorecase 'and' | 'or' }
    proto rule expr { * }
    rule expr:sym<recurse-and-or>       { [ '(' <expr> ')' ]**2..* % <and-or-keyword> }
    rule expr:sym<and-or>               { <expr-comparison> <and-or-keyword> <expr-comparison> }
    rule expr:sym<simple>               { <expr-comparison> }
    token comparison-operator           { '=' }
    proto rule expr-comparison          { * }
    rule expr-comparison:sym<operator>  { <identifier-or-value> <comparison-operator> <identifier-or-value> }
    rule expr-comparison:sym<NULL>      { :ignorecase <identifier> $<null-test-operator>=('IS' ['NOT']? 'NULL') }
    rule expr-comparison:sym<IN>        { :ignorecase <identifier> 'IN' '(' [ <value> + % ',' ] ')' }

    proto token entity-type { * }
    token entity-type:sym<TABLE> { <sym> }
    token entity-type:sym<COLUMN> { <sym> }

    rule sql-statement:sym<COMMENT-ON> {
        'COMMENT' 'ON' <entity-type> <entity-name> 'IS' <value> ';'
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
        '('
            <create-table-column-def>+? % ','
            [ ',' <table-constraint-def> ]*
        ')'
        <create-table-extra-oracle-stuff>*
        ';'
    }

    rule create-table-column-def { <identifier> <column-type> <create-table-column-constraint>* }

    rule create-table-extra-oracle-stuff {
        [ 'ORGANIZATION' [ 'HEAP' | 'INDEX' ]? ]
        | 'MONITORING'
        | 'OVERFLOW'
    }

    proto rule column-type { * }
    rule column-type:sym<VARCHAR2>          { 'VARCHAR2'    [ '(' <integer> ')' ]? }
    rule column-type:sym<NUMBER-with-scale> { 'NUMBER' '(' <integer> ',' <integer> ')' }
    rule column-type:sym<NUMBER-with-prec>  { 'NUMBER' '(' <integer> ')' }
    rule column-type:sym<NUMBER>            { 'NUMBER' }
    rule column-type:sym<FLOAT>             { 'FLOAT' }
    rule column-type:sym<INTEGER>           { 'INTEGER' }
    rule column-type:sym<DATE>              { 'DATE' }
    rule column-type:sym<TIMESTAMP>         { 'TIMESTAMP' '(' <integer> ')' }
    rule column-type:sym<CHAR>              { 'CHAR' '(' <integer> ')' }
    rule column-type:sym<BLOB>              { 'BLOB' }
    rule column-type:sym<CLOB>              { 'CLOB' }
    rule column-type:sym<LONG>              { 'LONG' }
    rule column-type:sym<RAW>               { 'RAW' '(' <integer> ')' }

    proto rule create-table-column-constraint { * }
    rule create-table-column-constraint:sym<NOT-NULL> { 'NOT NULL' }
    rule create-table-column-constraint:sym<PRIMARY-KEY> { 'PRIMARY KEY' }
    rule create-table-column-constraint:sym<DEFAULT> { 'DEFAULT' <value> }

    rule table-constraint-def { 'CONSTRAINT' <identifier> <table-constraint> <constraint-deferrables> * }

    proto rule table-constraint { * }
    rule table-constraint:sym<PRIMARY-KEY> { 'PRIMARY' 'KEY' '(' [ <identifier> + % ',' ] ')' }
    rule table-constraint:sym<UNIQUE>      { 'UNIQUE' '(' [ <identifier> + % ',' ] ')' }
    rule table-constraint:sym<CHECK>       { 'CHECK' '(' <expr> ')' }
    rule table-constraint:sym<FOREIGN-KEY> {
        'FOREIGN' 'KEY'
        '(' [ <table-columns=identifier> + % ',' ] ')'
        REFERENCES <entity-name>
        '(' [ <fk-columns=identifier> + % ',' ] ')'
    }

    proto token constraint-deferrables { * }
    token constraint-deferrables:sym<DEFERRABLE> { ['NOT' <ws>]? 'DEFERRABLE' }
    token constraint-deferrables:sym<INITIALLY>  { 'INITIALLY' <ws> ['IMMEDIATE'|'DEFERRED'] }
    token constraint-deferrables:sym<ENABLE-NOVALIDATE> { 'ENABLE' <ws> 'NOVALIDATE' }    # Postgres doesn't handle this

    rule sql-statement:sym<ALTER-TABLE> {
        'ALTER' 'TABLE'
        <entity-name>
        <alter-table-action>
        ';'
    }

    proto rule alter-table-action { * }
    rule alter-table-action:sym<ADD> { 'ADD' <alter-table-action-add> }

    proto rule alter-table-action-add { * }
    rule alter-table-action-add:sym<CONSTRAINT> { <table-constraint-def> }
}

