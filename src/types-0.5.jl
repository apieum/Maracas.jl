rm_spec_char(text) = replace(text, r"\e\[[0-9;]+m", "")
type ResultsCount
    passes::Int
    fails::Int
    errors::Int
    broken::Int
end
"""
    MaracasTestSet
"""
abstract MaracasTestSet <: AbstractTestSet

macro MaracasTestSet(type_name)
    base_type = parse("""
        type $type_name <: MaracasTestSet
            description::AbstractString
            results::Vector
            count::ResultsCount
            max_depth::Int
            $type_name(desc, results, count, max_depth)=new(format_title($type_name, desc), results, count, max_depth)
        end
    """)
    constructor = parse("""
        $type_name(desc) = $type_name(desc, [], ResultsCount(0, 0, 0, 0), 0)
    """)
    esc(quote
        $base_type
        $constructor
    end)
end

Error(test_type::Symbol, orig_expr, value, backtrace, source)=Error(test_type::Symbol, orig_expr, value, backtrace)
print_with_color(args...;kwargs...) = Base.print_with_color(args...)
TestSetException(pass::Int64, fail::Int64, error::Int64, broken::Int64, errors_and_fails::Array{Any,1}) = Base.Test.TestSetException(pass, fail, error, broken)
