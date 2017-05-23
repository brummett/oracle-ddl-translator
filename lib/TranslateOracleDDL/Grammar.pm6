use v6;

grammar TranslateOracleDDL::Grammar {
    my Str $last-statement-type;
    my Str $last-element-name;
    my Int $last-pos;

    method last-parse-location {
        "Last parsed { $last-statement-type } on { $last-element-name } at { $last-pos }";
    }

    rule TOP {
        { $last-statement-type = $last-element-name = ''; $last-pos = 0; }

        <input-line>+
    }

    token string-to-end-of-line {
        \V+
    }

    proto rule input-line { * }
    rule input-line:sym<sqlplus-directive> { <sqlplus-directive> }
    rule input-line:sym<sql-statement> { <sql-statement> \0* ';' }

    proto rule sqlplus-directive { * }
    rule sqlplus-directive:sym<REM>     { ['REM'<?before \v>]    | ['REM'<string-to-end-of-line>] } 
    rule sqlplus-directive:sym<PROMPT>  { ['PROMPT'<?before \v>] | ['PROMPT' <string-to-end-of-line>] }

    proto token identifier { * }
    token identifier:sym<bareword> { <[$\w]>+ }
    token identifier:sym<qq> {
        '"'
        $<name>=(
            [ <-["]>+:
                | '""'
            ]*
        )
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

    proto token expr-operator     { * }
    token expr-operator:sym<eq>   { '=' }
    token expr-operator:sym<sub>  { '-' }
    token expr-operator:sym<add>  { '+' }
    token expr-operator:sym<concat> { '||' }
    token expr-operator:sym<like> { :ignorecase 'LIKE' }
    token and-or-keyword { :ignorecase 'and' | 'or' }
    token expr-operator:sym<conjunction> { <and-or-keyword> }

    proto rule expr { * }
    rule expr:sym<recurse-and-or>       { [ '(' <expr> ')' ]+ % <and-or-keyword> }
    rule expr:sym<infix-operator>       { <left=expr-simple> <expr-operator> <right=expr> }
    rule expr:sym<simple>               { <expr-simple> }

    proto rule expr-simple          { * }
    rule expr-simple:sym<NULL>      { :ignorecase <entity-name> $<null-test-operator>=('IS' ['NOT']? 'NULL') }
    rule expr-simple:sym<IN>        { :ignorecase <entity-name> 'IN' '(' [ <value> + % ',' ] ')' }
        rule case-when-clause           { :ignorecase 'WHEN' <case=expr> 'THEN' <then=expr> }
        rule else-clause                { :ignorecase 'ELSE' <expr> }
    rule expr-simple:sym<CASE>      { :ignorecase 'CASE' <when-clause=case-when-clause>* <else-clause>? 'END' }
    rule expr-simple:sym<not-f>     { :ignorecase 'NOT' '(' <expr> ')' }
    rule expr-simple:sym<substr-f>  { :ignorecase 'substr' '(' <expr>**2..3 % ',' ')' }
    rule expr-simple:sym<decode-f>  { :ignorecase 'decode' '(' <topic=expr> ',' [ [ <case=value> ',' <result=expr> ]+? % ',' ] [ ',' <default=expr> ]? ')' }
    rule expr-simple:sym<trunc-f>   { :ignorecase 'trunc' '(' <expr> ')' }
    rule expr-simple:sym<to_char-1> { :ignorecase 'to_char' '(' <expr> ')' }
    rule expr-simple:sym<to_char-f> { :ignorecase 'to_char' '(' <expr>**2 % ',' ')' }   # Maybe parse the format specially?
    rule expr-simple:sym<upper-f>   { :ignorecase 'upper' '(' <expr> ')' }
    rule expr-simple:sym<lower-f>   { :ignorecase 'lower' '(' <expr> ')' }
    rule expr-simple:sym<sign-f>    { :ignorecase 'sign' '(' <expr> ')' }
    rule expr-simple:sym<count-f>   { :ignorecase 'count' '(' <expr> ')' }
    rule expr-simple:sym<sum-f>     { :ignorecase 'sum' '(' <expr> ')' }
    rule expr-simple:sym<atom>      { <identifier-or-value> }

    proto token entity-type { * }
    token entity-type:sym<TABLE> { <sym> }
    token entity-type:sym<COLUMN> { <sym> }

    proto rule sql-statement { * }
    rule sql-statement:sym<COMMENT-ON> {
        'COMMENT' 'ON'
            { $last-statement-type = 'COMMENT ON'; $last-pos = self.pos }
        <entity-type> <entity-name>
            { $last-element-name = ~$<entity-name> }
        'IS' <value>
    }

    rule sql-statement:sym<CREATE-SEQUENCE> {
        'CREATE' 'SEQUENCE'
            { $last-statement-type = 'CREATE SEQUENCE'; $last-pos = self.pos }
        <entity-name>
            { $last-element-name = ~$<entity-name> }
        <create-sequence-clause>*
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
            { $last-statement-type = 'CREATE TABLE'; $last-pos = self.pos }
        <entity-name>
            { $last-element-name = ~$<entity-name>.made }
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
            { $last-statement-type = 'broken ALTER TABLE ... ADD CONSTRAINT'; $last-element-name = ''; $last-pos = self.pos }
    }
    rule sql-statement:sym<ALTER-TABLE> {
        'ALTER' 'TABLE'
            { $last-statement-type = 'ALTER TABLE'; $last-pos = self.pos }
        <entity-name>
            { $last-element-name = ~$<entity-name> }
        <alter-table-action>
    }

    proto rule alter-table-action { * }
    rule alter-table-action:sym<ADD> { 'ADD' <alter-table-action-add> }

    proto rule alter-table-action-add { * }
    rule alter-table-action-add:sym<CONSTRAINT> { <table-constraint-def> }

    token unique-keyword { 'UNIQUE' }
    rule sql-statement:sym<CREATE-INDEX> {
        'CREATE' <unique=unique-keyword>? 'INDEX'
            { $last-statement-type = 'CREATE [unique] INDEX'; $last-pos = self.pos }
        <index-name=entity-name>
            { $last-element-name = ~$<index-name> }
        'ON'
        <table-name=entity-name>
        '(' [ [ <columns=expr> ]+ % ',' ] ')'
        <index-option>*
    }
    rule sql-statement:sym<broken-CREATE-INDEX> {
        'CREATE' <unique=unique-keyword>? 'INDEX'
            { $last-statement-type = 'CREATE [unique] INDEX'; $last-pos = self.pos }
        <index-name=entity-name>
            { $last-element-name = ~$<index-name> }
        'ON'
        <table-name=entity-name>
        '(' [ [ <columns=expr> ]* %% ',' ]
    }

    proto rule index-option { * }
    rule index-option:sym<COMPRESS> { 'COMPRESS' \d+ }
    rule index-option:sym<GLOBAL-PARTITION> {
        'GLOBAL' 'PARTITION' 'BY' 'RANGE'
        '(' <identifier>+ % ',' ')'
        '(' <partition-clause>+ % ',' ')'
    }

    rule partition-clause { 'PARTITION' <identifier> VALUES LESS THAN '(' <expr> ')' }

    rule sql-statement:sym<special-CREATE-VIEW> {
        'CREATE' 'OR' 'REPLACE' 'VIEW' 'SCHEMA_USER.plate_locations' '(' <-[;]>+
    }

    rule create-or-replace { 'CREATE' ['OR' 'REPLACE']? }
    rule sql-statement:sym<CREATE-VIEW> { :ignorecase
        <create-or-replace> 'VIEW'
            { $last-statement-type = 'CREATE [or replace] VIEW'; $last-pos = self.pos }
        <view-name=entity-name>
            { $last-element-name = ~$<view-name> }
        '(' <columns=expr> + % ',' ')'
        'AS'
        <select-statement>
        [ 'WITH' 'READ' 'ONLY']?
    }

    my $illegal-as-alias = 'FROM' | 'WHERE' | 'WITH' | 'JOIN' | 'LEFT' | 'OUTER' | 'ON' | 'GROUP';
    rule table-or-column-alias { :ignorecase [ 'AS'? <alias=identifier> <?{ $<alias>.uc ne $illegal-as-alias }>] }
    rule select-column { <expr> <alias=table-or-column-alias>? }

    rule select-from-clause { <from=select-from-table> <alias=table-or-column-alias>? }
    proto rule select-from-table { * }
    token select-from-table:sym<name>        { <table-name=entity-name> [ '@' <dblink=identifier> ]? }
    rule select-from-table:sym<inline-view> { '(' <select-statement> ')' }

    rule sql-statement:sym<SELECT> { <select-statement> }
    rule select-statement {
        :ignorecase
        'SELECT'
        [ $<distinct>=('DISTINCT') ]?
        <columns=select-column>+ % ','
        'FROM'
        <select-from-clause> + % ','
        <join-clause>*
        <where-clause>?
        <group-by-clause>?
    }

    rule where-clause { :ignorecase 'WHERE' <expr> }
    rule group-by-clause { :ignorecase 'GROUP' 'BY' <identifier> + % ',' }
    rule join-clause {
        :ignorecase
        [ $<left>=('LEFT') ]?
        [ $<outer>=('OUTER') ]?
        'JOIN' <source=select-from-clause>
        'ON' <expr>
    }
}

