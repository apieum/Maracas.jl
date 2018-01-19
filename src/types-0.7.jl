using Distributed
rm_spec_char(text) = replace(text, r"\e\[[0-9;]+m" => "")

mutable struct ResultsCount
    passes::Int
    fails::Int
    errors::Int
    broken::Int
end
"""
    MaracasTestSet
"""
mutable struct MaracasTestSet <: AbstractTestSet
    description::AbstractString
    results::Vector
    count::ResultsCount
    max_depth::Int
end
