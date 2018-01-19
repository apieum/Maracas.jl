using Maracas

import Maracas: AbstractTestSet, rm_spec_char, rpad_title
@testset "Maracas" begin
    @testset "'describe' returns a TestSet" begin
        @test isa(describe(()->nothing, "description"), AbstractTestSet)
    end

    @testset "'describe' TestSet contains description" begin
        expected = "expected description"
        ts = describe(()->nothing, expected)
        @test contains(ts.description, expected)
    end

    @testset "'describe' TestSet description is colored within 'title' env var" begin
        ts = describe(()->nothing, "description")
        @test contains(ts.description, MARACAS_SETTING[:title])
    end

    @testset "'describe' TestSet description color can be changed" begin
        title_color = MARACAS_SETTING[:title]
        set_title_style(:blue)
        ts = describe(()->nothing, "description")
        @test contains(ts.description, Base.text_colors[:blue])
        MARACAS_SETTING[:title] = title_color
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

    @testset "'it' TestSet description is colored within 'spec' env var" begin
        ts = it(()->nothing, "description")
        @test contains(ts.description, MARACAS_SETTING[:spec])
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

    @testset "'test' TestSet description is colored within 'test' env var" begin
        ts = test(()->nothing, "description")
        @test contains(ts.description, MARACAS_SETTING[:test])
    end

    @testset "padding results and descriptions" begin
        @testset "remove special chars returns empty string when special char is given" begin
            @test rm_spec_char(MARACAS_SETTING[:spec]) == ""
        end
        @testset "remove special chars returns a string with special chars removed" begin
            given = string("maracas : ", MARACAS_SETTING[:spec], "do tchik tchik tchik")
            expected = "maracas : do tchik tchik tchik"
            @test rm_spec_char(given) == expected
        end
        @testset "rpad_title of a special char returns :title_length spaces" begin
            given = MARACAS_SETTING[:test]
            expected = " "^MARACAS_SETTING[:title_length]
            @test rm_spec_char(rpad_title(given)) == expected
        end
        @testset "test title is cut when too long" begin
            given = "-"^(MARACAS_SETTING[:title_length] + 10)
            @test length(rm_spec_char(rpad_title(given))) == MARACAS_SETTING[:title_length]
        end
        @testset "test title end is replaced with ellipsis when too long" begin
            given = "-"^(MARACAS_SETTING[:title_length] + 10)
            @test rpad_title(given)[end-3:end-1] == "..."
        end

    end
end

include("doc_examples.jl")
