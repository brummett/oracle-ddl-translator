use v6;

class TranslateOracleDDL::Remark {
    has Str $.string is required;

    method to-pg {
        "-- $.string";
    }
}
