using Compat
import Compat.Test: AbstractTestSet, record, finish, get_testset_depth, get_testset, Broken, Pass, Fail, Error, TestSetException
import Base.+
include(ifelse(VERSION > v"0.6", "types-0.7.jl", "types-0.5.jl"))

ResultsCount(ts) = ResultsCount(0, 0, 0, 0)
total(count::ResultsCount)  = count.passes + count.fails + count.errors + count.broken
+(a::ResultsCount, b::ResultsCount) = ResultsCount(a.passes + b.passes, a.fails + b.fails, a.errors + b.errors, a.broken + b.broken)
+(a::ResultsCount, b::Pass) = ResultsCount(a.passes + 1, a.fails, a.errors, a.broken)
+(a::ResultsCount, b::Fail) = ResultsCount(a.passes, a.fails + 1, a.errors, a.broken)
+(a::ResultsCount, b::Error) = ResultsCount(a.passes, a.fails, a.errors + 1, a.broken)
+(a::ResultsCount, b::Broken) = ResultsCount(a.passes, a.fails, a.errors, a.broken + 1)
+(a::ResultsCount, b::AbstractTestSet) = (a + ResultsCount(b))

passes(count::Dict) = get(count, :passes, 0)
fails(count::Dict)  = get(count, :fails, 0)
errors(count::Dict) = get(count, :errors, 0)
broken(count::Dict) = get(count, :broken, 0)
total(count::Dict)  = passes(count) + fails(count) + errors(count) + broken(count)
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

MaracasTestSet(desc) = MaracasTestSet(desc, [], ResultsCount(0, 0, 0, 0), 0)
ResultsCount(ts::MaracasTestSet) = ts.count

passes(ts::MaracasTestSet) = ts.count.passes
fails(ts::MaracasTestSet)  = ts.count.fails
errors(ts::MaracasTestSet) = ts.count.errors
broken(ts::MaracasTestSet) = ts.count.broken
total(ts::MaracasTestSet)  = ts.count.passes + ts.count.fails + ts.count.errors + ts.count.broken

failed(ts::MaracasTestSet) = (errors(ts) > 0 || fails(ts) > 0 )

function hwidth(ts::MaracasTestSet)
    return Dict(
    :passes => passes(ts) > 0 ? 8 : 0,
    :fails => fails(ts) > 0 ? 8 : 0,
    :errors => errors(ts) > 0 ? 8 : 0,
    :broken => broken(ts) > 0 ? 8 : 0,
    :total => total(ts) > 0 ? 8 : length("No Tests")
    )
end

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

function print_col_header(color::Symbol, title::AbstractString, result::Int)
    result == 0 && return
    print_with_color(color, lpad(title, 8); bold = true)
end


function print_test_results(ts::MaracasTestSet)
    print_summary()
    print_col_header(MARACAS_SETTING[:pass], "Pass", passes(ts))
    print_col_header(MARACAS_SETTING[:error], "Fail", fails(ts))
    print_col_header(MARACAS_SETTING[:error], "Error", errors(ts))
    print_col_header(MARACAS_SETTING[:warn], "Broken", broken(ts))
    print_col_header(MARACAS_SETTING[:info], "Total", total(ts))
    println()
    # Recursively print a summary at every level
    print_counts(ts, 0, hwidth(ts))
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

    # Finally throw an error as we are the outermost test set
    if failed(ts)
        # Get all the error/failures and bring them along for the ride
        throw(TestSetException(passes(ts), fails(ts), errors(ts), broken(ts), filter_errors(ts)))
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
function print_counts(ts::MaracasTestSet, depth, headers_width)
    print_title(ts.description, depth)
    print_result_column(MARACAS_SETTING[:pass], passes(ts), passes(headers_width))
    print_result_column(MARACAS_SETTING[:error], fails(ts), fails(headers_width))
    print_result_column(MARACAS_SETTING[:error], errors(ts), errors(headers_width))
    print_result_column(MARACAS_SETTING[:warn], broken(ts), broken(headers_width))

    subtotal = total(ts)
    result = subtotal == 0 ? "No tests" : string(subtotal)
    print_with_color(MARACAS_SETTING[:info], lpad(result, total(headers_width), " "); bold = true)
    println()

    for t in ts.results
        print_counts(t, depth + 1, headers_width)
    end
end
print_counts(args...) = nothing

caesura(text, quantity) = string(text[1:(end + quantity - 4)], Base.text_colors[:red], "... ")
function rpad_title(text)
    space_repeat = MARACAS_SETTING[:title_length] - length(rm_spec_char(text))
    return space_repeat > 0 ? string(text, " "^space_repeat) : caesura(text, space_repeat)
end

print_title(text, depth=0) = print(rpad_title(string("  "^depth, text)), "$(MARACAS_SETTING[:default])|")
print_summary() = print_title("$(MARACAS_SETTING[:bold])Test Summary:")
