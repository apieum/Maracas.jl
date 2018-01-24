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
type MaracasTestSet <: AbstractTestSet
    description::AbstractString
    results::Vector
    count::ResultsCount
    max_depth::Int
end

Error(test_type::Symbol, orig_expr, value, backtrace, source)=Error(test_type::Symbol, orig_expr, value, backtrace)
