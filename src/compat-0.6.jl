using Base.Test
import Base.Test: AbstractTestSet, record, finish, get_testset_depth, get_testset, Broken, Pass, Fail, Error, TestSetException
import Base.replace
const __source__ = LineNumberNode(0)
const stdout = Base.STDOUT
Error(test_type::Symbol, orig_expr, value, backtrace, source)=Error(test_type::Symbol, orig_expr, value, backtrace)
replace(text::String, pattern::Pair{Regex,String})=replace(text, first(pattern), last(pattern))
if VERSION <= v"0.5.9"
    print_with_color(args...;kwargs...) = Base.print_with_color(args...)
    TestSetException(pass::Int64, fail::Int64, error::Int64, broken::Int64, errors_and_fails::Array{Any,1}) = Base.Test.TestSetException(pass, fail, error, broken)
end
printstyled(args...;color=:default, bold=false) = print_with_color(color, args...; bold=bold)
