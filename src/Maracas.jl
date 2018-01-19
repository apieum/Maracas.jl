module Maracas
include("test.jl")
export @test, @test_throws, @test_broken, @test_skip, @test_warn, @test_nowarn
export @testset
export describe, test, it, ____describe, ____test, ____it, MARACAS_SETTING
export set_test_style, set_title_style, set_spec_style, set_error_color, set_warn_color, set_pass_color, set_info_color

using Compat.Test
const MARACAS_SETTING = Dict(
    :error => Symbol(get(ENV, "MARACAS_ERROR", :red)),
    :warn =>  Symbol(get(ENV, "MARACAS_WARN", :yellow)),
    :pass =>  Symbol(get(ENV, "MARACAS_PASS", :green)),
    :info =>  Symbol(get(ENV, "MARACAS_INFO", :blue)),
    :default => Base.text_colors[:normal],
    :bold => Base.text_colors[Symbol(get(ENV, "MARACAS_BOLD", :bold))],
    :title_length => 80,
    :test =>  "",
    :title =>  "",
    :spec =>  "",
)
MARACAS_SETTING[:test] =  get(ENV, "MARACAS_TEST", string(Base.text_colors[:blue], MARACAS_SETTING[:bold]))
MARACAS_SETTING[:title] =  get(ENV, "MARACAS_TITLE", string(Base.text_colors[:magenta], MARACAS_SETTING[:bold]))
MARACAS_SETTING[:spec] =  get(ENV, "MARACAS_SPEC", string(Base.text_colors[:cyan], MARACAS_SETTING[:bold]))

function set_text_style(key::Symbol, color::Symbol, style::Symbol=:bold)
    MARACAS_SETTING[key] = string(Base.text_colors[style], Base.text_colors[color])
end

const TextColor = Union{Symbol, UInt8}

set_test_style(color::TextColor, bold::Bool=true) = set_text_style(:test, color, bold ? :bold : :normal)
set_title_style(color::TextColor, bold::Bool=true) = set_text_style(:title, color, bold ? :bold : :normal)
set_spec_style(color::TextColor, bold::Bool=true) = set_text_style(:spec, color, bold ? :bold : :normal)
set_error_color(color::TextColor) = (MARACAS_SETTING[:error] = color)
set_warn_color(color::TextColor) = (MARACAS_SETTING[:warn] = color)
set_pass_color(color::TextColor) = (MARACAS_SETTING[:pass] = color)
set_info_color(color::TextColor) = (MARACAS_SETTING[:info] = color)

if VERSION <= v"0.6.9"
    print_with_color(args...;kwargs...) = Base.print_with_color(args...)
    TestSetException(pass::Int64, fail::Int64, error::Int64, broken::Int64, errors_and_fails::Array{Any,1}) = Base.Test.TestSetException(pass, fail, error, broken)
end

function maracas(tests, desc, skip::Bool=false)
    ts = MaracasTestSet(desc)
    if skip
        record(ts, Broken(:skipped, ts))
    else
        Test.push_testset(ts)
        try
            tests()
        catch err
            record(ts, Error(:nontest_error, :(), err, catch_backtrace()))
        end
        Test.pop_testset()
    end
    finish(ts)
end
function describe(tests::Function, desc, skip::Bool=false)
    desc = string(MARACAS_SETTING[:title], desc, MARACAS_SETTING[:default], )
    maracas(tests, desc, skip)
end
function it(tests::Function, desc, skip::Bool=false)
    desc = string(MARACAS_SETTING[:spec], "[Spec] ", MARACAS_SETTING[:default], "it ", desc)
    maracas(tests, desc, skip)
end
function test(tests::Function, desc, skip::Bool=false)
    desc = string(MARACAS_SETTING[:test], "[Test] ", MARACAS_SETTING[:default], desc)
    maracas(tests, desc, skip)
end
____describe(tests::Function, desc)=describe(tests, desc, true)
____it(tests::Function, desc)=it(tests, desc, true)
____test(tests::Function, desc)=test(tests, desc, true)
end
