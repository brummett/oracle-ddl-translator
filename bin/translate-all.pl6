use v6;

use TranslateOracleDDL;
use TranslateOracleDDL::ToPostgres;

subset ExistingDirectoryPath of Str where *.IO.d;
subset ExistingFilePath of IO::Path where *.f;

constant translation-state-file = 'translation-state.yaml';
constant @files-to-translate = < table.sql view.sql index.sql constraint.sql sequence.sql >;

multi MAIN(ExistingDirectoryPath :$source, ExistingDirectoryPath :$dest) {
    translation-state-file.IO.unlink;

    my $xlate = TranslateOracleDDL.new(translator => TranslateOracleDDL::ToPostgres.new(:create-table-if-not-exists,
                                                                                        :create-index-if-not-exists,
                                                                                        :omit-quotes-in-identifiers,
                                                                                        :not-valid-constraints,
                                                                                        :omit-tables(['freezer_content']), # This is a materialized view
                                                                                        :state-file-name(translation-state-file)));
    for @files-to-translate -> $file {
        my ExistingFilePath $source-file = $source.IO.add($file);
        my $dest-file = $dest.IO.add($file);

        say "Translating $source-file to $dest-file...";

        $dest-file.spurt( $xlate.parsefile($source-file.Str) );
    }

    $xlate.translator.save-state;
    exit 0;
}

multi MAIN(Str :$source, Str :$dest) {
    unless $source.IO.d {
        say "source '$source' must be an existing directory";
    }
    unless $dest.IO.d {
        say "dest '$dest' must be an existing directory";
    }
    exit 1;
}
