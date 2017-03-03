use v6;

grammar TranslateOracleDDL::Grammar {
    rule TOP {
        <input-line>+
    }

    token string-to-end-of-line {
        \V+
    }

    proto rule input-line { * }
    rule input-line:sym<sqlplus-directive> { <sqlplus-directive> }
    rule input-line:sym<sql-statement> { <sql-statement> ';' }

    proto rule sqlplus-directive { * }
    rule sqlplus-directive:sym<REM>     { ['REM'<?before \v>]    | ['REM'<string-to-end-of-line>] } 
    rule sqlplus-directive:sym<PROMPT>  { ['PROMPT'<?before \v>] | ['PROMPT' <string-to-end-of-line>] }

    proto token identifier { * }
    token identifier:sym<bareword> { <[$\w]>+ }
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
    token value:sym<number-value> { '-'? \d+ }
    token value:sym<string-value> {
        "'"
        [ <-[']>+:
            | "''"
        ]*
        "'"
    }
    token value:sym<systimestamp-function> { 'systimestamp' }

    token identifier-or-value           { <entity-name> | <value> }

    token and-or-keyword                { :ignorecase 'and' | 'or' }
    proto rule expr { * }
    rule expr:sym<recurse-and-or>       { [ '(' <expr> ')' ]**2..* % <and-or-keyword> }
    rule expr:sym<and-or>               { <expr-comparison> <and-or-keyword> <expr-comparison> }
    rule expr:sym<simple>               { <expr-comparison> }
    rule expr:sym<atom>                 { <identifier-or-value> }
    token comparison-operator           { '=' }
    proto rule expr-comparison          { * }
    rule expr-comparison:sym<operator>  { <identifier-or-value> <comparison-operator> <identifier-or-value> }
    rule expr-comparison:sym<NULL>      { :ignorecase <identifier> $<null-test-operator>=('IS' ['NOT']? 'NULL') }
    rule expr-comparison:sym<IN>        { :ignorecase <identifier> 'IN' '(' [ <value> + % ',' ] ')' }
        rule case-when-clause           { :ignorecase 'WHEN' <case=expr> 'THEN' <then=expr> }
        rule else-clause                { :ignorecase 'ELSE' <expr> }
    rule expr-comparison:sym<CASE>      { :ignorecase 'CASE' <when-clause=case-when-clause>* <else-clause>? 'END' }
    rule expr-comparison:sym<not-f>     { :ignorecase 'NOT' '(' <expr> ')' }
    rule expr-comparison:sym<substr-f>  { :ignorecase 'substr' '(' <expr>**2..3 % ',' ')' }
    rule expr-comparison:sym<decode-f>  { :ignorecase 'decode' '(' <topic=expr> ',' [ [ <case=value> ',' <result=expr> ]+? % ',' ] ',' <default=expr> ')' }
    rule expr-comparison:sym<trunc-f>   { :ignorecase 'trunc' '(' <expr> ')' }
    rule expr-comparison:sym<to_char-f> { :ignorecase 'to_char' '(' <expr> ')' }
    rule expr-comparison:sym<upper-f>   { :ignorecase 'upper' '(' <expr> ')' }
    rule expr-comparison:sym<lower-f>   { :ignorecase 'lower' '(' <expr> ')' }
    rule expr-comparison:sym<sign-f>    { :ignorecase 'sign' '(' <expr> ')' }

    proto token entity-type { * }
    token entity-type:sym<TABLE> { <sym> }
    token entity-type:sym<COLUMN> { <sym> }

    proto rule sql-statement { * }
    rule sql-statement:sym<COMMENT-ON> {
        'COMMENT' 'ON' <entity-type> <entity-name> 'IS' <value>
    }

    rule sql-statement:sym<CREATE-SEQUENCE> {
        'CREATE' 'SEQUENCE' <entity-name> <create-sequence-clause>*
    }

    proto rule create-sequence-clause { * }
    rule create-sequence-clause:sym<START-WITH>     { 'START' 'WITH' <bigint> }
    rule create-sequence-clause:sym<INCREMENT-BY>   { 'INCREMENT' 'BY' <bigint> }
    rule create-sequence-clause:sym<MINVALUE>       { 'MINVALUE' <bigint> }
    rule create-sequence-clause:sym<NOMINVALUE>     { 'NOMINVALUE' }
    rule create-sequence-clause:sym<MAXVALUE>       { 'MAXVALUE' <bigint> }
    rule create-sequence-clause:sym<NOMAXVALUE>     { 'NOMAXVALUE' }
    rule create-sequence-clause:sym<CACHE>          { 'CACHE' <bigint> }
    rule create-sequence-clause:sym<NOCACHE>        { 'NOCACHE' }
    rule create-sequence-clause:sym<CYCLE>          { 'CYCLE' }
    rule create-sequence-clause:sym<NOCYCLE>        { 'NOCYCLE' }
    rule create-sequence-clause:sym<ORDER>          { 'ORDER' }
    rule create-sequence-clause:sym<NOORDER>        { 'NOORDER' }

    rule sql-statement:sym<CREATE-TABLE> {
        'CREATE TABLE'
        <entity-name>
        '('
            <create-table-column-def>+? % ','
            [ ',' <table-constraint-def> ]*
        ')'
        <create-table-extra-oracle-stuff>*
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

    rule table-constraint-def { 'CONSTRAINT' <identifier> <table-constraint> <constraint-options> * }

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

    proto token constraint-options { * }
    token constraint-options:sym<DEFERRABLE> { ['NOT' <ws>]? 'DEFERRABLE' }
    token constraint-options:sym<INITIALLY>  { 'INITIALLY' <ws> ['IMMEDIATE'|'DEFERRED'] }
    token constraint-options:sym<ENABLE-NOVALIDATE> { 'ENABLE' <ws> 'NOVALIDATE' }    # Postgres doesn't handle this
    token constraint-options:sym<DISABLE>    { 'DISABLE' }

    rule sql-statement:sym<ALTER-TABLE-BROKEN-CONSTRAINT> {
        'ALTER' 'TABLE'
        \S+
        'ADD' 'CONSTRAINT'
        \S+
        'CHECK' '(' ')' '(' ')'
        \w+ 'DISABLE'
    }
    rule sql-statement:sym<ALTER-TABLE> {
        'ALTER' 'TABLE'
        <entity-name>
        <alter-table-action>
    }

    proto rule alter-table-action { * }
    rule alter-table-action:sym<ADD> { 'ADD' <alter-table-action-add> }

    proto rule alter-table-action-add { * }
    rule alter-table-action-add:sym<CONSTRAINT> { <table-constraint-def> }

    token unique-keyword { 'UNIQUE' }
    rule sql-statement:sym<CREATE-INDEX> {
        'CREATE' <unique=unique-keyword>? 'INDEX'
        <index-name=entity-name>
        'ON'
        <table-name=entity-name>
        '(' [ [ <columns=expr> ]+ % ',' ] ')'
        <index-option>*
    }
    proto rule index-option { * }
    rule index-option:sym<COMPRESS> { 'COMPRESS' \d+ }
    rule index-option:sym<GLOBAL-PARTITION> {
        'GLOBAL' 'PARTITION' 'BY' 'RANGE'
        '(' <identifier>+ % ',' ')'
        '(' <partition-clause>+ % ',' ')'
    }

    rule partition-clause { 'PARTITION' <identifier> VALUES LESS THAN '(' <expr> ')' }

    rule create-or-replace { 'CREATE' ['OR' 'REPLACE']? }
    rule sql-statement:sym<CREATE-VIEW> {
        <create-or-replace> 'VIEW'
        <view-name=entity-name>
        '(' <columns=expr> + % ',' ')'
        'AS'
        <select-statement=sql-statement:sym<SELECT>>
        [ 'WITH' 'READ' 'ONLY']?
    }

    rule select-column { <expr> [ 'AS'? <alias=identifier> <?{ $<identifier>.uc ne 'FROM' }>]? }
    rule sql-statement:sym<SELECT> {
        :ignorecase
        'SELECT'
        <columns=select-column>+ % ','
        'FROM'
        <table-name=entity-name>
        <where-clause>?
    }

    rule where-clause { 'WHERE' <expr> }
}

