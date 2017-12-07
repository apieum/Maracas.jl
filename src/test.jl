import Compat.Test: AbstractTestSet, record, finish, get_testset_depth, get_testset, Broken, Pass, Fail, Error, TestSetException
import Base.+

hwidth(header, total) = total > 0 ? max(length(header), ndigits(total)) : 0

type ResultsCount
    passes::Int
    fails::Int
    errors::Int
    broken::Int
end
type HeadersWidth
    passes::Int
    fails::Int
    errors::Int
    broken::Int
    total::Int
    function HeadersWidth(results::ResultsCount)
        pass_width   = hwidth("Pass", results.passes)
        fail_width   = hwidth("Fail", results.fails)
        error_width  = hwidth("Error", results.errors)
        broken_width = hwidth("Broken", results.broken)
        total_width  = hwidth("Total", total(results))
        new(pass_width, fail_width, error_width, broken_width, total_width)
    end
end
passes(count::ResultsCount) = count.passes
fails(count::ResultsCount)  = count.fails
errors(count::ResultsCount) = count.errors
broken(count::ResultsCount) = count.broken
total(count::ResultsCount)  = count.passes + count.fails + count.errors + count.broken
+(a::ResultsCount, b::ResultsCount) = ResultsCount(a.passes + b.passes, a.fails + b.fails, a.errors + b.errors, a.broken + b.broken)
+(a::ResultsCount, b::Pass) = ResultsCount(a.passes + 1, a.fails, a.errors, a.broken)
+(a::ResultsCount, b::Fail) = ResultsCount(a.passes, a.fails + 1, a.errors, a.broken)
+(a::ResultsCount, b::Error) = ResultsCount(a.passes, a.fails, a.errors + 1, a.broken)
+(a::ResultsCount, b::Broken) = ResultsCount(a.passes, a.fails, a.errors, a.broken + 1)
+(a::ResultsCount, b::AbstractTestSet) = (a + ResultsCount(b))
tuple(results_count::ResultsCount) = (results_count.passes, results_count.fails, results_count.errors, results_count.broken, total(results_count))

ResultsCount(ts) = nothing

# Backtrace utility functions copied from test.jl because VERSION < v"0.6" haven't it
function ip_matches_func_and_name(ip, func::Symbol, dir::String, file::String)
    for fr in StackTraces.lookup(ip)
        if fr === StackTraces.UNKNOWN || fr.from_c
            return false
        end
        path = string(fr.file)
        fr.func == func && dirname(path) == dir && basename(path) == file && return true
    end
    return false
end

function scrub_backtrace(bt)
    do_test_ind = findfirst(addr->ip_matches_func_and_name(addr, :do_test, ".", "test.jl"), bt)
    if do_test_ind != 0 && length(bt) > do_test_ind
        bt = bt[do_test_ind + 1:end]
    end
    name_ind = findfirst(addr->ip_matches_func_and_name(addr, Symbol("macro expansion"), ".", "test.jl"), bt)
    if name_ind != 0 && length(bt) != 0
        bt = bt[1:name_ind]
    end
    return bt
end

"""
    MaracasTestSet
"""
type MaracasTestSet <: AbstractTestSet
    description::AbstractString
    results::Vector
    count::ResultsCount
    max_depth::Int
end
MaracasTestSet(desc) = MaracasTestSet(desc, [], ResultsCount(0, 0, 0, 0), 0)
ResultsCount(ts::MaracasTestSet) = ts.count

# For a broken result, simply store the result
function record(ts::MaracasTestSet, t::Broken)
    ts.count += t;
    push!(ts.results, t)
    return t
end
# For a passed result, do not store the result since it uses a lot of memory
function record(ts::MaracasTestSet, t::Pass)
    ts.count += t;
    return t
end
# For the other result types, immediately print the error message
# but do not terminate. Print a backtrace.
function record(ts::MaracasTestSet, t::Union{Fail, Error})
    ts.count += t;
    if myid() == 1
        print_with_color(:bold, ts.description, ": ")
        print(t)
        # don't print the backtrace for Errors because it gets printed in the show
        # method
        isa(t, Error) || Base.show_backtrace(STDOUT, scrub_backtrace(backtrace()))
        println()
    end
    push!(ts.results, t)
    t, isa(t, Error) || backtrace()
end

function record(ts::MaracasTestSet, t::MaracasTestSet)
    ts.count += t;
    ts.max_depth = t.max_depth + 1
    push!(ts.results, t)
end

print_test_errors(ts::MaracasTestSet) = map(print_test_errors, ts.results)
function print_test_errors(t::Union{Fail, Error})
    if myid() == 1
        println("Error in testset $(ts.description):")
        Base.show(STDOUT,t)
        println()
    end
end
print_test_errors(t) = nothing

function print_result(color::Symbol, title::AbstractString, result::Int)
    if result > 0
        print_with_color(color, lpad(title, max(length(title), ndigits(result))," "), "  "; bold = true)
    end
end


function print_test_results(ts::MaracasTestSet)
    align = max(2 * ts.max_depth + ts.max_width, length("Test Summary:")) + Int(round(MARACAS_SETTING[:padding]/2))
    # Print the outer test set header once
    pad = total(ts.count) == 0 ? "" : " "
    print_with_color(:bold, rpad("Test Summary:", align - MARACAS_SETTING[:padding], " "), "$(MARACAS_SETTING[:default]) |", pad; bold=true)

    print_result(MARACAS_SETTING[:pass], "Pass", passes(ts.count))
    print_result(MARACAS_SETTING[:error], "Fail", fails(ts.count))
    print_result(MARACAS_SETTING[:error], "Error", errors(ts.count))
    print_result(MARACAS_SETTING[:warn], "Broken", broken(ts.count))
    print_result(MARACAS_SETTING[:info], "Total", total(ts.count))
    println()
    # Recursively print a summary at every level
    print_counts(ts, 0, align, HeadersWidth(ts.count))
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

    if TESTSET_PRINT_ENABLE[]
        print_test_results(ts)
    end

    total_pass, total_fail, total_error, total_broken, subtotal = tuple(ts.count)
    # Finally throw an error as we are the outermost test set
    if subtotal != total_pass + total_broken
        # Get all the error/failures and bring them along for the ride
        efs = filter_errors(ts)
        throw(TestSetException(total_pass, total_fail, total_error, total_broken, efs))
    end

    # return the testset so it is returned from the @testset macro
    ts
end


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


function print_result_column(color, result, width)
    if result > 0
        print_with_color(color, lpad(string(result), width, " "), "  "; bold = true)
    elseif width > 0
        print(lpad(" ", width), "  ")
    end
end
# Recursive function that prints out the results at each level of
# the tree of test sets
function print_counts(ts::MaracasTestSet, depth, align, headers_width)
    print(rpad(string("  "^depth, ts.description), align, " "), " | ")
    print_result_column(MARACAS_SETTING[:pass], ts.count.passes, headers_width.passes)
    print_result_column(MARACAS_SETTING[:error], ts.count.fails, headers_width.fails)
    print_result_column(MARACAS_SETTING[:error], ts.count.errors, headers_width.errors)
    print_result_column(MARACAS_SETTING[:warn], ts.count.broken, headers_width.broken)

    subtotal = total(ts.count)
    if subtotal == 0
        print_with_color(MARACAS_SETTING[:info], "No tests")
    else
        print_with_color(MARACAS_SETTING[:info], lpad(string(subtotal), headers_width.total, " "); bold = true)
    end
    println()

    for t in ts.results
        print_counts(t, depth + 1, align, headers_width)
    end
end
print_counts(args...) = nothing
