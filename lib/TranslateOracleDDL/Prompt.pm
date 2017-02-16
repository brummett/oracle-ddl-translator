use v6;

class TranslateOracleDDL::Prompt {
    has Str $.string is required;

    method to-pg {
        "\\echo $.string";
    }
}
