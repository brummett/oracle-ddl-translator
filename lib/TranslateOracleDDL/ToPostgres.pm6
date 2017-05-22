use v6;

class TranslateOracleDDL::ToPostgres {
    has $.schema;
    has Bool $.create-table-if-not-exists = False;
    has Bool $.create-index-if-not-exists = False;
    has Bool $.omit-quotes-in-identifiers = False;

    method TOP($/) {
        make $<input-line>>>.made.grep({ $_ }).join("\n") ~ "\n";
    }

    method input-line:sym<sqlplus-directive>    ($/) { make $<sqlplus-directive>.made }
    method input-line:sym<sql-statement>        ($/) { make $<sql-statement>.made ?? "{$<sql-statement>.made};" !! Str }

    method sqlplus-directive:sym<REM>   ($/) { make '--' ~ ($<string-to-end-of-line> || '') }
    method sqlplus-directive:sym<PROMPT>($/) { make "\\echo" ~ ($<string-to-end-of-line> ?? " $<string-to-end-of-line>" !! '') }

    method bigint ($/) {
        make $/ > 9223372036854775807
            ?? make "9223372036854775807"
            !! make ~ $/;
    }

    method entity-name ($/) {
        my @parts = @<identifier>>>.made;
        if @parts.elems > 1 and self.schema {
            @parts[0] = self.schema;  # rewrite the schema if we're configured to
        }
        make join('.', @parts);
    }

    method sql-statement:sym<CREATE-SEQUENCE> ($/) {
        if $<create-sequence-clause>.elems {
            my @clauses = $<create-sequence-clause>.map({ .made // ~ $_ }).grep({ $_ });
            make 'CREATE SEQUENCE ' ~ $<entity-name>.made ~ ' ' ~ @clauses.join(' ');
        } else {
            make 'CREATE SEQUENCE ' ~ $<entity-name>.made;
        }
    }

    method create-sequence-clause:sym<START-WITH> ($/)  { make 'START WITH ' ~ $<bigint>.made }
    method create-sequence-clause:sym<INCREMENT-BY> ($/)  { make 'INCREMENT BY ' ~ $<bigint>.made }
    method create-sequence-clause:sym<MINVALUE> ($/)    { make 'MINVALUE ' ~ $<bigint>.made }
    method create-sequence-clause:sym<MAXVALUE> ($/)    { make 'MAXVALUE ' ~ $<bigint>.made }
    method create-sequence-clause:sym<CACHE> ($/)       { make 'CACHE ' ~ $<bigint>.made }
    method create-sequence-clause:sym<NOMINVALUE> ($/)  { make 'NO MINVALUE' }
    method create-sequence-clause:sym<NOMAXVALUE> ($/)  { make 'NO MAXVALUE' }
    method create-sequence-clause:sym<NOCYCLE> ($/)     { make 'NO CYCLE' }
    method create-sequence-clause:sym<NOCACHE> ($/)     { make '' }
    method create-sequence-clause:sym<ORDER> ($/)       { make '' }
    method create-sequence-clause:sym<NOORDER> ($/)     { make '' }

    method identifier-or-value ($/) { make $<entity-name> ?? $<entity-name>.made !! $<value> }

    method identifier:sym<bareword>($/) { make ~ $/ }
    method identifier:sym<qq>($/) { make $!omit-quotes-in-identifiers ?? ~ $<name> !! ~ $/ }

    method value:sym<number-value> ($/)             { make "$/" }
    method value:sym<string-value> ($/)             { make "$/" }
    method value:sym<systimestamp-function> ($/)    { make 'LOCALTIMESTAMP' }

    method expr:sym<simple>              ($/)       { make $<expr-comparison>.made }
    method expr:sym<atom>                ($/)       { make $<identifier-or-value>.made }
    method expr:sym<and-or>              ($/)       { make "{ $<expr-comparison>.made } $<and-or-keyword> { $<expr>.made }" }
    method expr:sym<recurse-and-or>      ($/)       {
        my Str $str = "( { @<expr>.shift.made } )";
        for @<and-or-keyword> Z @<expr> -> ( $and-or, $expr ) {
            $str ~= " $and-or ( { $expr.made } )";
        }
        make $str;
    }

    method expr-comparison:sym<operator> ($/)       { make "{$<left>.made} $<expr-operator> {$<right>.made}" }
    method expr-comparison:sym<NULL>     ($/)       { make "{ $<entity-name>.made } $<null-test-operator>" }
    method expr-comparison:sym<IN>       ($/)       { make "{ $<entity-name>.made } IN ( { @<value>>>.made.join(', ') } )" }
    method expr-comparison:sym<not-f>    ($/)       { make "NOT( { $<expr>.made } )" }
    method expr-comparison:sym<trunc-f>  ($/)       { make "trunc( { $<expr>.made } )" }
    method expr-comparison:sym<to_char-1>($/)       { make "cast( ( { $<expr>.made } ) AS text )" }
    method expr-comparison:sym<to_char-f>($/)       { make "to_char( { $<expr>>>.made.join(', ') } )" }
    method expr-comparison:sym<upper-f>  ($/)       { make "upper( { $<expr>.made } )" }
    method expr-comparison:sym<lower-f>  ($/)       { make "lower( { $<expr>.made } )" }
    method expr-comparison:sym<sign-f>   ($/)       { make "sign( { $<expr>.made } )" }
    method expr-comparison:sym<count-f>  ($/)       { make "count( { $<expr>.made } )" }
    method expr-comparison:sym<sum-f>    ($/)       { make "sum( { $<expr>.made } )" }
    method expr-comparison:sym<substr-f> ($/)       { make 'substr( ' ~ @<expr>>>.made.join(', ') ~ ' )' }
    method expr-comparison:sym<decode-f> ($/)       {
        my @cases;
        for @<case> Z @<result> -> ($case, $result) {
            @cases.push("WHEN $case THEN { $result.made }");
        }
        make "( CASE { $<topic>.made } "
                ~ @cases.join(' ')
                ~ ( $<default> ?? " ELSE { $<default>.made }" !! '' )
                ~ ' END )';
    }

    method case-when-clause         ($/)    { make "WHEN { $<case>.made } THEN { $<then>.made }" }
    method else-clause              ($/)    { make "ELSE { $<expr>.made }" }
    method expr-comparison:sym<CASE>($/)    {
        make "CASE "
                ~ $<when-clause>>>.made.join(' ')
                ~ ( $<else-clause> ?? " { $<else-clause>.made }" !! '' )
                ~ ' END';
    }

    method sql-statement:sym<COMMENT-ON> ($/) {
        make "COMMENT ON $<entity-type> { $<entity-name>.made } IS { $<value>.made }"
    }

    method sql-statement:sym<CREATE-TABLE> ($/) {
        my @columns = $<create-table-column-def>>>.made;
        my @constraints = $<table-constraint-def>>>.made;
        my $if-not-exists = $!create-table-if-not-exists ?? ' IF NOT EXISTS' !! '';
        make "CREATE TABLE{ $if-not-exists } { $<entity-name>.made } ( " ~ (|@columns, |@constraints).join(', ') ~ " )"
    }

    method create-table-column-def ($/) {
        my @parts = ( $<identifier>.made, $<column-type>.made );
        @parts.push( $<create-table-column-constraint>>>.made ) if $<create-table-column-constraint>;
        make join(' ', @parts);
    }

    # data types
    method column-type:sym<VARCHAR2> ($/)   { make $<integer> ?? "VARCHAR($<integer>)" !! "VARCHAR" }

    my subset out-of-range of Int where { $_ < 0 or $_ > 38 };
    method column-type:sym<NUMBER-with-prec> ($/)     {
        given $<integer>.Int {
            when 1 ..^ 3    { make 'SMALLINT' }
            when 3 ..^ 5    { make 'SMALLINT' }
            when 5 ..^ 9    { make 'INT' }
            when 9 ..^ 19   { make 'BIGINT' }
            when 19 .. 38   { make "DECIMAL($<integer>)" }
            when out-of-range { die "Can't handle NUMBER($<integer>): Out of range 1..38" }
            default         { make 'INT' }
        }
    }
    method column-type:sym<NUMBER-with-scale> ($/) {
        my ($precision, $scale) = $<integer>;
        die "Can't handle NUMBER($precision): Out of range 1..38" if $precision.Int ~~ out-of-range;

        make "DECIMAL($precision,$scale)";
    }
    method column-type:sym<NUMBER> ($/)     { make 'DOUBLE PRECISION' }

    method column-type:sym<DATE> ($/)       { make "TIMESTAMP(0)" }
    method column-type:sym<TIMESTAMP> ($/)  { make "TIMESTAMP($<integer>)"; }
    method column-type:sym<CHAR> ($/)       { make "CHAR($<integer>)" }
    method column-type:sym<BLOB> ($/)       { make 'BYTEA' }
    method column-type:sym<RAW> ($/)        { make 'BYTEA' }
    method column-type:sym<CLOB> ($/)       { make 'TEXT' }
    method column-type:sym<LONG> ($/)       { make 'TEXT' }
    method column-type:sym<FLOAT> ($/)      { make 'DOUBLE PRECISION' }
    method column-type:sym<INTEGER> ($/)    { make 'DECIMAL(38)' }

    method create-table-column-constraint:sym<NOT-NULL> ($/) { make 'NOT NULL' }
    method create-table-column-constraint:sym<PRIMARY-KEY> ($/) { make 'PRIMARY KEY' }
    method create-table-column-constraint:sym<DEFAULT> ($/) { make "DEFAULT { $<value>.made }" }

    method table-constraint-def ($/)        {
        my @parts = ('CONSTRAINT', $<identifier>.made, $<table-constraint>.made);
        if @<constraint-options>.elems {
            @parts.push: @<constraint-options>>>.made.grep({ $_ });
        }
        make @parts.join(' ');
    }

    method table-constraint:sym<PRIMARY-KEY> ($/) { make "PRIMARY KEY ( { @<identifier>>>.made.join(', ') } )" }
    method table-constraint:sym<UNIQUE> ($/)      { make "UNIQUE ( { @<identifier>>>.made.join(', ') } )" }
    method table-constraint:sym<CHECK> ($/)       { make "CHECK ( { $<expr>.made } )" }
    method table-constraint:sym<FOREIGN-KEY> ($/) {
        make "FOREIGN KEY ( { @<table-columns>.join(', ') } ) REFERENCES { $<entity-name>.made } ( { @<fk-columns>.join(', ') } )";
    }

    method constraint-options:sym<DEFERRABLE> ($/) { make $/ }
    method constraint-options:sym<INITIALLY> ($/)  { make $/ }
    method constraint-options:sym<DISABLE> ($/)    { make Str }

    method sql-statement:sym<ALTER-TABLE> ($/) {
        if ($<alter-table-action><alter-table-action-add>
            && $<alter-table-action><alter-table-action-add><table-constraint-def>
            && $<alter-table-action><alter-table-action-add><table-constraint-def><constraint-options>.contains('DISABLE')
        ) {
            make Str;  # Postgres doesn't support disabled constraints, remove them
        } else {
            make 'ALTER TABLE ' ~ $<entity-name>.made ~ ' ' ~ $<alter-table-action>.made;
        }
    }
    method sql-statement:sym<ALTER-TABLE-BROKEN-CONSTRAINT> ($/) { make Str }

    method alter-table-action:sym<ADD> ($/)             { make 'ADD ' ~ $<alter-table-action-add>.made }
    method alter-table-action-add:sym<CONSTRAINT> ($/)  { make $<table-constraint-def>.made }

    method index-option:sym<COMPRESS> ($/) { make Str }
    method index-option:sym<GLOBAL-PARTITION> ($/) { make Str }
    method sql-statement:sym<CREATE-INDEX> ($/) {
        my Str @parts = <CREATE>;
        @parts.push('UNIQUE') if $<unique>;
        @parts.push('INDEX');
        @parts.push('IF NOT EXISTS') if $!create-index-if-not-exists;

        my $index-name = $<index-name><identifier>[*-1].made;
        @parts.push("$index-name", 'ON', "$<table-name>");
        @parts.push('(', @<columns>>>.made.join(', '), ')');
        @parts.push( | @<index-option>>>.made.grep({ $_ })>>.Str );
        make @parts.join(' ');
    }

    method sql-statement:sym<broken-CREATE-INDEX> ($/) { make Str }

    method table-or-column-alias    ($/) { make "AS $<alias>" }
    method where-clause             ($/) { make "WHERE { $<expr>.made }" }
    method group-by-clause          ($/) { make "GROUP BY { @<identifier>>>.made.join(', ') }" }
    method select-column            ($/) { make $<expr>.made ~ ( $<alias> ?? " { $<alias>.made }" !! '' ) }
    method select-from-clause       ($/) { make $<from>.made ~ ( $<alias> ?? " { $<alias>.made }" !! '' ) }
    method select-from-table:sym<name>          ($/) { make $<table-name>.made }
    method select-from-table:sym<inline-view>   ($/) { make "( { $<select-statement>.made } )" }

    method join-clause      ($/)    {
        make
            ( $<left> ?? 'LEFT ' !! '')
            ~ ( $<outer> ?? 'OUTER ' !! '')
            ~ "JOIN { $<source>.made } ON { $<expr>.made }"
    }

    method sql-statement:sym<SELECT> ($/) { make $<select-statement>.made }
    method select-statement ($/) {
        make 'SELECT '
                ~ ( $<distinct> ?? 'DISTINCT ' !!  '' )
                ~ $<columns>>>.made.join(', ')
                ~ " FROM { @<select-from-clause>>>.made.join(', ') }"
                ~ ( @<join-clause>.elems ?? " { @<join-clause>>>.made.join(' ') }" !! '' )
                ~ ( $<where-clause> ?? " { $<where-clause>.made }" !! '' )
                ~ ( $<group-by-clause> ?? " { $<group-by-clause>.made }" !! '' );
    }

    method sql-statement:sym<CREATE-VIEW> ($/) {
        make "$<create-or-replace>VIEW { $<view-name>.made } ( "
            ~ @<columns>>>.made.join(', ')
            ~ ' ) AS '
            ~ $<select-statement>.made;
    }

    method sql-statement:sym<special-CREATE-VIEW> ($/) {
        make ~$/;
    }
}

