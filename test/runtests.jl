using Maracas
using Base.Test
import Maracas.AbstractTestSet
@testset "Maracas" begin
    @testset "'describe' returns a TestSet" begin
        @test isa(describe(()->nothing, "description"), AbstractTestSet)
    end

    @testset "'describe' TestSet contains description" begin
        expected = "expected description"
        ts = describe(()->nothing, expected)
        @test contains(ts.description, expected)
    end

    @testset "'describe' TestSet description is colored in yellow" begin
        ts = describe(()->nothing, "description")
        @test contains(ts.description, Base.text_colors[:yellow])
    end

    @testset "'it' returns a TestSet" begin
        @test isa(it(()->nothing, "description"), AbstractTestSet)
    end

    @testset "'it' TestSet contains description" begin
        expected = "expected description for it"
        ts = it(()->nothing, expected)
        @test contains(ts.description, expected)
    end

    @testset "'it' TestSet contains [Spec]" begin
        ts = it(()->nothing, "description")
        @test contains(ts.description, "[Spec]")
    end

    @testset "'it' TestSet description is colored in cyan" begin
        ts = it(()->nothing, "description")
        @test contains(ts.description, Base.text_colors[:cyan])
    end

    @testset "'test' returns a TestSet" begin
        @test isa(test(()->nothing, "description"), AbstractTestSet)
    end

    @testset "'test' TestSet contains description" begin
        expected = "expected description for it"
        ts = test(()->nothing, expected)
        @test contains(ts.description, expected)
    end

    @testset "'test' TestSet contains [Test]" begin
        ts = test(()->nothing, "description")
        @test contains(ts.description, "[Test]")
    end

    @testset "'test' TestSet description is colored in blue" begin
        ts = test(()->nothing, "description")
        @test contains(ts.description, Base.text_colors[:blue])

    end
end
