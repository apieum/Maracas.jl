module Maracas
include("test.jl")
export @test, @test_throws, @test_broken, @test_skip, @test_warn, @test_nowarn
export @testset
export describe, test, it, MARACAS_SETTING

using Compat.Test
const MARACAS_SETTING = Dict(
    "error" => Symbol(get(ENV, "MARARAS_ERROR", :red)),
    "warn" =>  Symbol(get(ENV, "MARARAS_WARN", :yellow)),
    "pass" =>  Symbol(get(ENV, "MARARAS_PASS", :green)),
    "info" =>  Symbol(get(ENV, "MARARAS_INFO", :blue)),
    "default" => Base.text_colors[Symbol(get(ENV, "MARARAS_DEFAULT", :normal))],
    "bold" => Base.text_colors[Symbol(get(ENV, "MARARAS_BOLD", :bold))],
    "margin" => UInt(get(ENV, "MARARAS_MARGIN", 10)),
    "title" =>  Base.text_colors[Symbol(get(ENV, "MARARAS_TITLE", :yellow))],
    "spec" =>  Base.text_colors[Symbol(get(ENV, "MARARAS_SPEC", :cyan))],
    "test" =>  Base.text_colors[Symbol(get(ENV, "MARARAS_TEST", :blue))],

)
if VERSION < v"0.6"
    print_with_color(args...;kwargs...) = Base.print_with_color(args...)
    TestSetException(pass::Int64, fail::Int64, error::Int64, broken::Int64, errors_and_fails::Array{Any,1}) = Base.Test.TestSetException(pass, fail, error, broken)
    MARACAS_SETTING["margin"] += 3
end

function maracas(tests, desc)
    ts = MaracasTestSet(desc)
    Base.Test.push_testset(ts)
    try
        tests()
    catch err
        record(ts, Error(:nontest_error, :(), err, catch_backtrace()))
    end
    Base.Test.pop_testset()
    finish(ts)
end
function describe(tests::Function, desc)
    desc = string(MARACAS_SETTING["title"], MARACAS_SETTING["bold"], desc, MARACAS_SETTING["default"], )
    maracas(tests, desc)
end
function it(tests::Function, desc)
    desc = string(MARACAS_SETTING["spec"], MARACAS_SETTING["bold"], "[Spec] ", MARACAS_SETTING["default"], "it ", desc)
    maracas(tests, desc)
end
function test(tests::Function, desc)
    desc = string(MARACAS_SETTING["test"], MARACAS_SETTING["bold"], "[Test] ", MARACAS_SETTING["default"], desc)
    maracas(tests, desc)
end

end
