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
}
