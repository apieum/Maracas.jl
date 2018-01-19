using Maracas
if VERSION > v"0.6.9"
    using Test
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
        test("should not be executed") do
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
