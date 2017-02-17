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
}
