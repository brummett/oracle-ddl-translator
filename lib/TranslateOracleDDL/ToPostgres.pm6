use v6;

class TranslateOracleDDL::ToPostgres {
    method TOP($/) {
        make $<sql-statement>>>.made.join(";\n") ~ ";";
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

    method sql-statement:sym<CREATE-SEQUENCE> ($/) {
        if $<create-sequence-clause>.elems {
            make "CREATE SEQUENCE $<entity-name> " ~ $<create-sequence-clause>.join(' ');
        } else {
            make "CREATE SEQUENCE $<entity-name>";
        }
    }
}
