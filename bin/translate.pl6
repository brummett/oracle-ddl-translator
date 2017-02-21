use v6;

use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

sub MAIN($filename) {
    my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new);
    say $xlate.parse($filename.IO.slurp);
}
