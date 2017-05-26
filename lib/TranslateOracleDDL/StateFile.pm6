use YAMLish;

enum CacheKey < CONSTRAINT_NAME >;

class TranslateOracleDDL::StateFile {
    has $.filename;
    has %!cache;  # %cache{CacheKey}{name} = 1;

    submethod BUILD(Str :$filename) {
        $!filename = $filename;

        if $filename.IO.e and $filename.IO.s > 0 {
            %!cache = load-yaml($filename.IO.slurp);
        }
    }

    method set(CacheKey :$type, Str :$name where .chars > 0) {
        return Nil if %!cache{$type}{$name}:exists;

        %!cache{$type}{$name}=1;
    }

    method write {
        $!filename.IO.spurt(save-yaml %!cache);
    }
}
