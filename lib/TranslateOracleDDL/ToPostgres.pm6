use v6;

class TranslateOracleDDL::ToPostgres {
    method TOP($/) {
        make $<sql-statement>>>.made.grep({ $_ }).join(";\n") ~ ";\n";
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

    method sql-statement:sym<CREATE-TABLE> ($/) {
        make "CREATE TABLE $<entity-name> ( " ~ $<create-table-column-list>.made ~ " )"
    }

    method create-table-column-list ($/) { make $<create-table-column-def>>>.made.join(', ') }
    method create-table-column-def ($/) {
        my @parts = ( $<identifier>, $<column-type>.made );
        @parts.push( $<create-table-column-constraint>>>.made ) if $<create-table-column-constraint>;
        make join(' ', @parts);
    }

    # data types
    method column-type:sym<VARCHAR2> ($/)   { make $<integer> ?? "VARCHAR($<integer>)" !! "VARCHAR" }
    method column-type:sym<NUMBER> ($/)     { make $<integer> ?? "INT($<integer>)" !! "INT" }
    method column-type:sym<DATE> ($/)       { make "TIMESTAMP(0)" }

    method create-table-column-constraint:sym<NOT-NULL> ($/) { make 'NOT NULL' }
    method create-table-column-constraint:sym<PRIMARY-KEY> ($/) { make 'PRIMARY KEY' }


    method sql-statement:sym<SELECT> ($/) {
        make "SELECT $<select-column-list>FROM $<rest-of-select>"
    }        
    #rule sql-statement:sym<SELECT> {
    #    'SELECT'
    #    <select-column-list>
    #    ['FROM'|'from'] <rest-of-select>
    #}

    
    #method select-column-def:sym<COLUMN-NAME>        ($/) { make $<identifier> }
    #method select-column-def:sym<QUOTED-COLUMN-NAME> ($/) { make $<identifier> }

}
