use v6;

use Test;
use File::Temp;

use TranslateOracleDDL::StateFile;

plan 1;

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
