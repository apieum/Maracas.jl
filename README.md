# Maracas
[![Build Status](https://travis-ci.org/apieum/Maracas.jl.svg?branch=master)](https://travis-ci.org/apieum/Maracas.jl)

The **Maracas** package extends julia base/test.jl to provide syntactic sugar and verbose output to tests.

## Features

- document your code with nested typed test sets
- show indented colored results, modifiable by user
- `describe(func::Function, description::String)` : group tests under the given description
- `it(func::Function, description::String)` : describe a specification
- `test(func::Function, description::String)` : describe a non regression test


## Usage

First, in your test file declare you're using the package:

```julia
using Maracas
```

Then write your testsets with 'describe', 'it', or 'test' functions with the same assertions as usual (`@test`, `@test_throws`)

You can also prefix testset functions with four underscore like '____describe', '____it', or '____test' to skip a testset: the title will be shown in test results but the testset is not executed and all contained tests are ignored.

```julia
using Maracas
if VERSION > v"0.6"
    using Test  # required only for using Test.AbstractTestSet
end
# 'describe', 'it' and 'test' return a MaracasTestSet <: Base.Test.AbstractTestSet
is_a_spec(ts::Test.AbstractTestSet)=contains(ts.description, "[Spec]")
is_a_test(ts::Test.AbstractTestSet)=contains(ts.description, "[Test]")
is_magenta(ts::Test.AbstractTestSet)=contains(ts.description, Base.text_colors[:magenta])
is_blue(ts::Test.AbstractTestSet)=contains(ts.description, Base.text_colors[:blue])
is_cyan(ts::Test.AbstractTestSet)=contains(ts.description, Base.text_colors[:cyan])

describe("it is a test suite") do
    it("has specs") do
        a_spec = it(()->nothing, "is made by calling function 'it'")
        @test is_a_spec(a_spec)
    end
    it("has tests") do
        a_test = test(()->nothing, "made by calling function 'test'")
        @test is_a_test(a_test)
    end

    test("test suite title is magenta by default") do
        nested_describe = describe(()->nothing, "you can document your code with your tests")
        @test is_magenta(nested_describe)
    end

    test("spec title is cyan by default") do
        @test is_cyan(it(()->nothing, "is cyan"))
    end
    test("test title is blue by default") do
        @test is_blue(test(()->nothing, "in blue"))
    end

    test("'it' is prepended to specs") do
        description = "had a spec description not starting with it"
        a_spec = it(()->nothing, description)
        @test contains(a_spec.description, string("it ", description))
    end

    ____describe("a whole describe can be skipped with prefix ____") do
        it("shouldn't be executed") do
            @test false
        end
        test("shouldn't be executed neither") do
            @test false
        end
    end
    ____it("can skip 'it' with prefix ____") do
            @test false
    end
    ____test("'test' can be skipped with prefix ____") do
            @test false
    end
end

```
**Changing Styles**

You can modify color and boldness with the folowing functions:

- `set_title_style(color::TextColor, bold::Bool=true)`: change the style of titles defined with `describe` (default: `:magenta`)
- `set_test_style(color::TextColor, bold::Bool=true)`:  change the style of `[test]`  (default: `:blue`)
- `set_spec_style(color::TextColor, bold::Bool=true)`: change the style of `[spec]`  (default: `:cyan`)
- `set_error_color(color::TextColor)`: set the color of error results  (default: `:red`)
- `set_warn_color(color::TextColor)`: set the color of warn results  (default: `:yellow`)
- `set_pass_color(color::TextColor)`: set the color of pass results  (default: `:green`)
- `set_info_color(color::TextColor)`: set the color of total results  (default: `:blue`)

Available colors are defined by `Base.text_colors`, which are either UInt8 between 0 and 255 inclusive or symbols you'll find inside julia REPL Help mode about `Base.text_colors`.


```
$ julia
               _
   _       _ _(_)_     |  A fresh approach to technical computing
  (_)     | (_) (_)    |  Documentation: https://docs.julialang.org
   _ _   _| |_  __ _   |  Type "?help" for help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 0.6.0 (2017-06-19 13:05 UTC)
 _/ |\__'_|_|_|\__'_|  |
|__/                   |  x86_64-redhat-linux

help?> Base.text_colors
  Dictionary of color codes for the terminal.

  Available colors are: :normal, :default, :bold, :black, :blue, :cyan, :green, :light_black, :light_blue, :light_cyan, :light_green, :light_magenta, :light_red, :light_yellow, :magenta, :nothing, :red,
  :white, or :yellow as well as the integers 0 to 255 inclusive.

  The color :default will print text in the default color while the color :normal will print text with all text properties (like boldness) reset. Printing with the color :nothing will print the string without
  modifications.

```
