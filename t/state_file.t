use v6;

use Test;
use File::Temp;

use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;
use TranslateOracleDDL::StateFile;

plan 2;

subtest 'basic' => {
    plan 10;

    my ($filename, Any) = tempfile;
    ok my $original = TranslateOracleDDL::StateFile.new(:$filename), 'Create StateFile';

    my @keys = <foo bar>;
    for @keys -> $key {
        ok $original.set(type => CONSTRAINT_NAME, name => $key), "set $key";
        ok ! $original.set(type => CONSTRAINT_NAME, name => $key), "cannot set $key again";
    }
    ok $original.write(), 'write file';
    
    ok my $copy = TranslateOracleDDL::StateFile.new(:$filename), 'Create StateFile with the same file';
    for @keys -> $key {
        ok ! $copy.set(type => CONSTRAINT_NAME, name => $key), "cannot set $key from copy";
    }
    ok $copy.set(type => CONSTRAINT_NAME, name => 'baz'), 'set baz on copy';
}

subtest 'PK constraint state' => {
    my @tests = ( %( send => (  'CREATE TABLE foo ( id VARCHAR2 NOT NULL, CONSTRAINT pk_name PRIMARY KEY (id) );',
                                'ALTER TABLE foo ADD CONSTRAINT pk_name PRIMARY KEY (id);' ),
                     expect => ("CREATE TABLE foo ( id VARCHAR NOT NULL, CONSTRAINT pk_name PRIMARY KEY ( id ) );\n",
                                "\n" ),
                     label => 'table first, then add constraint',
                    ),
                );

    plan(@tests.elems * 2);

    for @tests -> % (:send(@send), :expect(@expect), :label($label) ) {
        my ($filename, Any) = tempfile;
        my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new(state-file-name => $filename));

        for @send Z @expect Z 0..* -> ($send, $expect, $i) {
            is $xlate.parse($send), $expect, "$label $i";
        }
    }
}
