use v6;

class TranslateOracleDDL::ToPostgres {
    method TOP($/) {
        my Str $string = $<sql-statement>>>.made.grep({ $_ }).join(";\n");
        $string ~= ";\n" if $string.chars;
        make $string;
    }

    method sql-statement:sym<REM> ($/) {
        if $<string-to-end-of-line> {
            make "-- $<string-to-end-of-line>";
        } else {
            make '--';
        }
    }

    method sql-statement:sym<PROMPT> ($/) {
        if $<string-to-end-of-line> {
            make "\\echo $<string-to-end-of-line>";
        } else {
            make "\\echo";
        }
    }

    method sql-statement:sym<empty-line> ($/) { return Any; }

    method bigint ($/) {
        make $/ > 9223372036854775807
            ?? make "9223372036854775807"
            !! make ~ $/;
    }

    method sql-statement:sym<CREATE-SEQUENCE> ($/) {
        if $<create-sequence-clause>.elems {
            my @clauses = $<create-sequence-clause>.map({ .made // ~ $_ }).grep({ $_ });
            make "CREATE SEQUENCE $<entity-name> " ~ @clauses.join(' ');
        } else {
            make "CREATE SEQUENCE $<entity-name>";
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

    method value:sym<number-value> ($/)             { make "$/" }
    method value:sym<string-value> ($/)             { make "$/" }
    method value:sym<systimestamp-function> ($/)    { make 'LOCALTIMESTAMP' }

    method expr:sym<simple>              ($/)       { make $<expr-comparison>.made }
    method expr:sym<atom>                ($/)       { make "$<identifier-or-value>" }
    method expr:sym<and-or>              ($/)       { make "{ @<expr-comparison>[0].made } $<and-or-keyword> { @<expr-comparison>[1].made }" }
    method expr:sym<recurse-and-or>      ($/)       {
        my Str $str = "( { @<expr>.shift.made } )";
        for @<and-or-keyword> Z @<expr> -> ( $and-or, $expr ) {
            $str ~= " $and-or ( { $expr.made } )";
        }
        make $str;
    }

    method expr-comparison:sym<operator> ($/)       { make "@<identifier-or-value>[0] $<comparison-operator> @<identifier-or-value>[1]" }
    method expr-comparison:sym<NULL>     ($/)       { make "$<identifier> $<null-test-operator>" }
    method expr-comparison:sym<IN>       ($/)       { make "$<identifier> IN ( { @<value>>>.made.join(', ') } )" }
    method expr-comparison:sym<not-f>    ($/)       { make "NOT( { $<expr>.made } )" }
    method expr-comparison:sym<trunc-f>  ($/)       { make "trunc( { $<expr>.made } )" }
    method expr-comparison:sym<to_char-f>($/)       { make "to_char( { $<expr>.made } )" }
    method expr-comparison:sym<upper-f>  ($/)       { make "upper( { $<expr>.made } )" }
    method expr-comparison:sym<lower-f>  ($/)       { make "lower( { $<expr>.made } )" }
    method expr-comparison:sym<substr-f> ($/)       { make 'substr( ' ~ @<expr>>>.made.join(', ') ~ ' )' }
    method expr-comparison:sym<decode-f> ($/)       {
        my @cases;
        for @<case> Z @<result> -> ($case, $result) {
            @cases.push("WHEN $case THEN { $result.made }");
        }
        make "( CASE { $<topic>.made } "
                ~ @cases.join(' ')
                ~ " ELSE { $<default>.made } END )";
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
        make "COMMENT ON $<entity-type> $<entity-name> IS { $<value>.made }"
    }

    method sql-statement:sym<CREATE-TABLE> ($/) {
        my @columns = $<create-table-column-def>>>.made;
        my @constraints = $<table-constraint-def>>>.made;
        make "CREATE TABLE $<entity-name> ( " ~ (|@columns, |@constraints).join(', ') ~ " )"
    }

    method create-table-column-def ($/) {
        my @parts = ( $<identifier>, $<column-type>.made );
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
        my @parts = ('CONSTRAINT', $<identifier>, $<table-constraint>.made);
        if @<constraint-deferrables>.elems {
            @parts.push: @<constraint-deferrables>>>.made.grep({ $_ });
        }
        make @parts.join(' ');
    }

    method table-constraint:sym<PRIMARY-KEY> ($/) { make "PRIMARY KEY ( { $<identifier>.join(', ') } )" }
    method table-constraint:sym<UNIQUE> ($/)      { make "UNIQUE ( { $<identifier>.join(', ') } )" }
    method table-constraint:sym<CHECK> ($/)       { make "CHECK ( { $<expr>.made } )" }
    method table-constraint:sym<FOREIGN-KEY> ($/) {
        make "FOREIGN KEY ( { @<table-columns>.join(', ') } ) REFERENCES $<entity-name> ( { @<fk-columns>.join(', ') } )";
    }

    method constraint-deferrables:sym<DEFERRABLE> ($/) { make $/ }
    method constraint-deferrables:sym<INITIALLY> ($/)  { make $/ }

    method sql-statement:sym<ALTER-TABLE> ($/) {
        make "ALTER TABLE $<entity-name> " ~ $<alter-table-action>.made;
    }
    method sql-statement:sym<ALTER-TABLE-ADD-CONSTRAINT-DISABLE> ($/) { make Str }

    method alter-table-action:sym<ADD> ($/)             { make 'ADD ' ~ $<alter-table-action-add>.made }
    method alter-table-action-add:sym<CONSTRAINT> ($/)  { make $<table-constraint-def>.made }


    method index-option:sym<COMPRESS> ($/) { make Str }
    method index-option:sym<GLOBAL-PARTITION> ($/) { make Str }
    method sql-statement:sym<CREATE-INDEX> ($/) {
        my Str @parts = <CREATE>;
        @parts.push('UNIQUE') if $<unique>;
        @parts.push('INDEX', "$<index-name>", 'ON', "$<table-name>");
        @parts.push('(', @<columns>>>.made.join(', '), ')');
        @parts.push( | @<index-option>>>.made.grep({ $_ })>>.Str );
        make @parts.join(' ');
    }
}

