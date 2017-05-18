use v6;

use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

sub MAIN($filename) {
    my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new(:create-table-if-not-exists));
    say $xlate.parsefile($filename);
}
