using Maracas

# abstract MaracasTestSet <: Base.Test.AbstractTestSet
is_magenta(ts::MaracasTestSet)=contains(ts.description, Base.text_colors[:magenta])
is_blue(ts::MaracasTestSet)=contains(ts.description, Base.text_colors[:blue])
is_cyan(ts::MaracasTestSet)=contains(ts.description, Base.text_colors[:cyan])

@describe "it is a test suite" begin
    @it "has specs" begin
        a_spec = @it("is made with macro '@it'", begin end)
        @test contains(a_spec.description, "[Spec]")
    end
    @it "has tests" begin
        a_test = @unit("made with macro '@unit'", begin end)
        @test contains(a_test.description, "[Test]")
    end

    @unit "test suite title is magenta by default" begin
        nested_describe = @describe("you can document your code with your tests", begin end)
        @test is_magenta(nested_describe)
    end

    @unit "spec title is cyan by default" begin
        @test is_cyan(@it("is cyan", begin end))
    end
    @unit "test title is blue by default" begin
        @test is_blue(@unit("in blue", begin end))
    end

    @unit "'it' is prepended to specs" begin
        description = "had a spec description not starting with it"
        a_spec = @it("had a spec description not starting with it", begin end)
        @test contains(a_spec.description, string("it ", description))
    end

    @skip @describe "a whole describe can be skipped" begin
        @it "should not be executed" begin
            @test false
        end
    end
    @skip @it "can skip '@it' with @skip" begin
        @test false
    end
    @skip @unit "'@unit' can be skipped with @skip" begin
        @test false
    end
    @skip @testset "@skip works with default testset but it's not shown in results" begin
        @test false
    end
    @unit "@skip can also skip @test assertions" begin
        @skip @test false
        @skip @test_throws false
        @skip @test_skip false
        @skip @test_broken false
    end
end
