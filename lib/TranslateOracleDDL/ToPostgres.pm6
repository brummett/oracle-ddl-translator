use v6;

class TranslateOracleDDL::ToPostgres {
    method TOP($/) {
        make $<sql-statement>>>.made>>.join(";\n") ~ ";";
    }

    method sql-statement:sym<REM> ($/) {
        make "-- $<string-to-end-of-line>";
    }
}
