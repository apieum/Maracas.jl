module Maracas
export describe, test, it, @test, @test_throws
# import Compat.Test.
import Compat.Test: AbstractTestSet, record, finish, get_testset_depth, get_testset, Broken, Pass, Fail, Error
using Compat.Test
if VERSION < v"0.6"
    print_with_color(args...;kwargs...) = Base.print_with_color(args...)
end

"""
    MaracasTestSet
"""
type MaracasTestSet <: AbstractTestSet
    description::AbstractString
    results::Vector
    n_passed::Int
    anynonpass::Bool
end
MaracasTestSet(desc) = MaracasTestSet(desc, [], 0, false)

# For a broken result, simply store the result
record(ts::MaracasTestSet, t::Broken) = (push!(ts.results, t); t)
# For a passed result, do not store the result since it uses a lot of memory
record(ts::MaracasTestSet, t::Pass) = (ts.n_passed += 1; t)
# For the other result types, immediately print the error message
# but do not terminate. Print a backtrace.
function record(ts::MaracasTestSet, t::Union{Fail, Error})
    if myid() == 1
        print_with_color(:white, ts.description, ": ")
        print(t)
        # don't print the backtrace for Errors because it gets printed in the show
        # method
        isa(t, Error) || Base.show_backtrace(STDOUT, Compat.Test.scrub_backtrace(backtrace()))
        println()
    end
    push!(ts.results, t)
    t, isa(t, Error) || backtrace()
end

record(ts::MaracasTestSet, t::AbstractTestSet) = push!(ts.results, t)

function print_test_errors(ts::MaracasTestSet)
    for t in ts.results
        if (isa(t, Error) || isa(t, Fail)) && myid() == 1
            println("Error in testset $(ts.description):")
            Base.show(STDOUT,t)
            println()
        elseif isa(t, MaracasTestSet)
            print_test_errors(t)
        end
    end
end

function print_test_results(ts::MaracasTestSet, depth_pad=0)
    # Calculate the overall number for each type so each of
    # the test result types are aligned
    passes, fails, errors, broken, c_passes, c_fails, c_errors, c_broken = get_test_counts(ts)
    total_pass   = passes + c_passes
    total_fail   = fails  + c_fails
    total_error  = errors + c_errors
    total_broken = broken + c_broken
    dig_pass   = total_pass   > 0 ? ndigits(total_pass)   : 0
    dig_fail   = total_fail   > 0 ? ndigits(total_fail)   : 0
    dig_error  = total_error  > 0 ? ndigits(total_error)  : 0
    dig_broken = total_broken > 0 ? ndigits(total_broken) : 0
    total = total_pass + total_fail + total_error + total_broken
    dig_total = total > 0 ? ndigits(total) : 0
    # For each category, take max of digits and header width if there are
    # tests of that type
    pass_width   = dig_pass   > 0 ? max(length("Pass"),   dig_pass)   : 0
    fail_width   = dig_fail   > 0 ? max(length("Fail"),   dig_fail)   : 0
    error_width  = dig_error  > 0 ? max(length("Error"),  dig_error)  : 0
    broken_width = dig_broken > 0 ? max(length("Broken"), dig_broken) : 0
    total_width  = dig_total  > 0 ? max(length("Total"),  dig_total)  : 0
    # Calculate the alignment of the test result counts by
    # recursively walking the tree of test sets
    align = max(get_alignment(ts, 0), length("Test Summary:"))
    # Print the outer test set header once
    pad = total == 0 ? "" : " "
    print_with_color(:white, rpad("Test Summary:",align-10," "), " |", pad; bold = true)
    if pass_width > 0
        print_with_color(:green, lpad("Pass",pass_width," "), "  "; bold = true)
    end
    if fail_width > 0
        print_with_color(Base.error_color(), lpad("Fail",fail_width," "), "  "; bold = true)
    end
    if error_width > 0
        print_with_color(Base.error_color(), lpad("Error",error_width," "), "  "; bold = true)
    end
    if broken_width > 0
        print_with_color(Base.warn_color(), lpad("Broken",broken_width," "), "  "; bold = true)
    end
    if total_width > 0
        print_with_color(Base.info_color(), lpad("Total",total_width, " "); bold = true)
    end
    println()
    # Recursively print a summary at every level
    print_counts(ts, depth_pad, align, pass_width, fail_width, error_width, broken_width, total_width)
end


const TESTSET_PRINT_ENABLE = Ref(true)

# Called at the end of a @testset, behaviour depends on whether
# this is a child of another testset, or the "root" testset
function finish(ts::MaracasTestSet)
    # If we are a nested test set, do not print a full summary
    # now - let the parent test set do the printing
    if get_testset_depth() != 0
        # Attach this test set to the parent test set
        parent_ts = get_testset()
        record(parent_ts, ts)
        return ts
    end
    passes, fails, errors, broken, c_passes, c_fails, c_errors, c_broken = get_test_counts(ts)
    total_pass   = passes + c_passes
    total_fail   = fails  + c_fails
    total_error  = errors + c_errors
    total_broken = broken + c_broken
    total = total_pass + total_fail + total_error + total_broken

    if TESTSET_PRINT_ENABLE[]
        print_test_results(ts)
    end

    # Finally throw an error as we are the outermost test set
    if total != total_pass + total_broken
        # Get all the error/failures and bring them along for the ride
        efs = filter_errors(ts)
        throw(Compat.Test.TestSetException(total_pass,total_fail,total_error, total_broken, efs))
    end

    # return the testset so it is returned from the @testset macro
    ts
end

# Recursive function that finds the column that the result counts
# can begin at by taking into account the width of the descriptions
# and the amount of indentation. If a test set had no failures, and
# no failures in child test sets, there is no need to include those
# in calculating the alignment
function get_alignment(ts::MaracasTestSet, depth::Int)
    # The minimum width at this depth is
    ts_width = 2*depth + length(ts.description)
    # Return the maximum of this width and the minimum width
    # for all children (if they exist)
    isempty(ts.results) && return ts_width
    child_widths = map(t->get_alignment(t, depth+1), ts.results)
    return max(ts_width, maximum(child_widths))
end
get_alignment(ts, depth::Int) = 0

# Recursive function that fetches backtraces for any and all errors
# or failures the testset and its children encountered
function filter_errors(ts::MaracasTestSet)
    efs = []
    for t in ts.results
        if isa(t, MaracasTestSet)
            append!(efs, filter_errors(t))
        elseif isa(t, Union{Fail, Error})
            append!(efs, [t])
        end
    end
    efs
end

# Recursive function that counts the number of test results of each
# type directly in the testset, and totals across the child testsets
function get_test_counts(ts::MaracasTestSet)
    passes, fails, errors, broken = ts.n_passed, 0, 0, 0
    c_passes, c_fails, c_errors, c_broken = 0, 0, 0, 0
    for t in ts.results
        isa(t, Fail)   && (fails  += 1)
        isa(t, Error)  && (errors += 1)
        isa(t, Broken) && (broken += 1)
        if isa(t, MaracasTestSet)
            np, nf, ne, nb, ncp, ncf, nce , ncb = get_test_counts(t)
            c_passes += np + ncp
            c_fails  += nf + ncf
            c_errors += ne + nce
            c_broken += nb + ncb
        end
    end
    ts.anynonpass = (fails + errors + c_fails + c_errors > 0)
    return passes, fails, errors, broken, c_passes, c_fails, c_errors, c_broken
end
function print_result_column(color, result, width)
    if result > 0
        print_with_color(color, lpad(string(result), width, " "), "  ")
    elseif width > 0
        print(lpad(" ", width), "  ")
    end
end
# Recursive function that prints out the results at each level of
# the tree of test sets
function print_counts(ts::MaracasTestSet, depth, align,
                      pass_width, fail_width, error_width, broken_width, total_width)
    # Count results by each type at this level, and recursively
    # through any child test sets
    passes, fails, errors, broken, c_passes, c_fails, c_errors, c_broken = get_test_counts(ts)
    subtotal = passes + fails + errors + broken + c_passes + c_fails + c_errors + c_broken
    # Print test set header, with an alignment that ensures all
    # the test results appear above each other
    print(rpad(string("  "^depth, ts.description), align, " "), " | ")

    print_result_column(:green, passes + c_passes, pass_width)
    print_result_column(Base.error_color(), fails + c_fails, fail_width)
    print_result_column(Base.error_color(), errors + c_errors, error_width)
    print_result_column(Base.warn_color(), broken + c_broken, broken_width)

    if subtotal == 0
        print_with_color(Base.info_color(), "No tests")
    else
        print_with_color(Base.info_color(), lpad(string(subtotal), total_width, " "))
    end
    println()

    # Only print results at lower levels if we had failures
    # if np + nb != subtotal
        for t in ts.results
            if isa(t, MaracasTestSet)
                print_counts(t, depth + 1, align,
                    pass_width, fail_width, error_width, broken_width, total_width)
            end
        end
    # end
end

const default_color = Base.text_colors[:normal]
function describe(fn::Function, text)
    text = string(Base.text_colors[:yellow], Base.text_colors[:bold], text, default_color, )
    @testset MaracasTestSet "$text" begin
        fn()
    end
end
function it(fn::Function, text)
    text = string(Base.text_colors[:cyan], Base.text_colors[:bold], "[Spec] ", default_color, "it ", text)
    @testset MaracasTestSet "$text" begin
        fn()
    end
end
function test(fn::Function, text)
    text = string(Base.text_colors[:blue], Base.text_colors[:bold], "[Test] ", default_color, text)
    @testset MaracasTestSet "$text" begin
        fn()
    end
end


end
