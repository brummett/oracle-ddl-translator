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

subtest 'constraint state' => {
    my @tests = ( %( send => (  'CREATE TABLE foo ( id VARCHAR2 NOT NULL, CONSTRAINT pk_name PRIMARY KEY (id) );',
                                'ALTER TABLE foo ADD CONSTRAINT pk_name PRIMARY KEY (id);' ),
                     expect => ("CREATE TABLE foo ( id VARCHAR NOT NULL, CONSTRAINT pk_name PRIMARY KEY ( id ) );\n",
                                "\n" ),
                     label => 'table first, then add constraint',
                    ),
                  %( send => (  'ALTER TABLE foo ADD CONSTRAINT uk UNIQUE (name);',
                                'CREATE UNIQUE INDEX uk ON foo(name);' ),
                     expect => ("ALTER TABLE foo ADD CONSTRAINT uk UNIQUE ( name );\n",
                                "\n" ),
                     label => 'add constraint then unique index',
                    ),
                  %( send => (  'CREATE UNIQUE INDEX uk ON foo(name);',
                                'ALTER TABLE foo ADD CONSTRAINT uk UNIQUE (name);' ),
                     expect => ("CREATE UNIQUE INDEX uk ON foo ( name );\n",
                                "\n" ),
                     label => 'add constraint then unique index',
                    ),
                  %( send => (  'ALTER TABLE foo ADD CONSTRAINT blah PRIMARY KEY ( id );',
                                'ALTER TABLE foo ADD CONSTRAINT blah PRIMARY KEY ( id );' ),
                     expect => ("ALTER TABLE foo ADD CONSTRAINT blah PRIMARY KEY ( id );\n",
                                "\n" ),
                     label => 'add the same constraint twice',
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
