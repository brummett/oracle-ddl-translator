use v6;

use TranslateOracleDDL::Remark;
use TranslateOracleDDL::Prompt;

grammar TranslateOracleDDL::Grammar {
    token TOP {
        <sql-statement>+
    }

    token string-to-end-of-line {
        <[\V]>*
    }

    proto rule sql-statement { * }

    rule sql-statement:sym<REM> {
        'REM ' <string-to-end-of-line> \v?
    }
}

