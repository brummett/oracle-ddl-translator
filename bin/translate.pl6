use v6;

use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

sub MAIN($filename) {
    my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new(:create-table-if-not-exists, :create-index-if-not-exists, :omit-quotes-in-identifiers));
    say $xlate.parsefile($filename);
}
