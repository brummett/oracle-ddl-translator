use v6;

use Test;
use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

plan 3;

my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
ok $xlate, 'created translator';

subtest 'CREATE SEQUENCE' => {
    plan 3;

    is $xlate.parse("CREATE SEQUENCE foo.seqname;"),
        "CREATE SEQUENCE foo.seqname;\n",
        'basic CREATE SEQUENCE';

    is $xlate.parse("CREATE SEQUENCE foo.seqname\nSTART WITH 123 INCREMENT BY 2 MINVALUE 3 NOMAXVALUE;"),
        "CREATE SEQUENCE foo.seqname START WITH 123 INCREMENT BY 2 MINVALUE 3 NO MAXVALUE;\n",
        'CREATE SEQUENCE with some add-ons';

    is $xlate.parse("CREATE SEQUENCE foo.seqname\nSTART WITH 1\n  INCREMENT BY 2\n  NOMINVALUE\n  MAXVALUE 9999999999999999999999999999\n  ORDER;"),
        "CREATE SEQUENCE foo.seqname START WITH 1 INCREMENT BY 2 NO MINVALUE MAXVALUE 9223372036854775807;\n",
        'CREATE SEQUENCE with leading spaces and large number';
}

subtest 'mixed stuff' => {
    plan 1;

    is $xlate.parse( q :to<ORACLE> ),
            REM     SCHEMA_USER.TP_SEQ
            REM     GSCUSER.ASP_SEQ

            PROMPT CREATE SEQUENCE SCHEMA_USER.acct_seq

            CREATE SEQUENCE SCHEMA_USER.acct_seq
               START WITH       956
               INCREMENT BY     1
               MINVALUE         1
               NOMAXVALUE
               NOCACHE
               NOCYCLE
               NOORDER;
            ORACLE
        q :to<POSTGRES>,
            -- SCHEMA_USER.TP_SEQ;
            -- GSCUSER.ASP_SEQ;
            \echo CREATE SEQUENCE SCHEMA_USER.acct_seq;
            CREATE SEQUENCE SCHEMA_USER.acct_seq START WITH 956 INCREMENT BY 1 MINVALUE 1 NO MAXVALUE NO CYCLE;
            POSTGRES
        'example 1';
}
