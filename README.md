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

```julia
using Maracas
# 'describe', 'it' and 'test' return a MaracasTestSet <: Base.Test.AbstractTestSet
is_a_spec(ts::Base.Test.AbstractTestSet)=contains(ts.description, "[Spec]")
is_a_test(ts::Base.Test.AbstractTestSet)=contains(ts.description, "[Test]")
is_yellow(ts::Base.Test.AbstractTestSet)=contains(ts.description, Base.text_colors[:yellow])
is_blue(ts::Base.Test.AbstractTestSet)=contains(ts.description, Base.text_colors[:blue])
is_cyan(ts::Base.Test.AbstractTestSet)=contains(ts.description, Base.text_colors[:cyan])

describe("it is a test suite") do
    it("has specs") do
        a_spec = it(()->nothing, "is made by calling function 'it'")
        @test is_a_spec(a_spec)
    end
    it("has tests") do
        a_test = test(()->nothing, "made by calling function 'test'")
        @test is_a_test(a_test)
    end

    test("test suite title is yellow by default") do
        nested_describe = describe(()->nothing, "you can document your code with your tests")
        @test is_yellow(nested_describe)
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
end

```
