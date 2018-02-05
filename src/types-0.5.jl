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
