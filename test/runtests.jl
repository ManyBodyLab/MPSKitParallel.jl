using SafeTestsets: @safetestset
using Suppressor: Suppressor
using MPI
using Test: @test

# check for filtered groups
# either via `--group=ALL` or through ENV["GROUP"]
const pat = r"(?:--group=)(\w+)"
arg_id = findfirst(contains(pat), ARGS)
const GROUP = uppercase(
    if isnothing(arg_id)
        arg = get(ENV, "GROUP", "ALL")
        # For some reason `ENV["GROUP"]` is set to `""`
        # when running via GitHub Actions, so handle that case:
        arg == "" ? "ALL" : arg
    else
        only(match(pat, ARGS[arg_id]).captures)
    end,
)

"match files of the form `test_*.jl`, but exclude `*setup*.jl`"
function istestfile(path)
    fn = basename(path)
    return endswith(fn, ".jl") && startswith(basename(fn), "test_") && !contains(fn, "setup")
end
"match files of the form `*.jl`, but exclude `*_notest.jl` and `*setup*.jl`"
function isexamplefile(path)
    fn = basename(path)
    return endswith(fn, ".jl") && !endswith(fn, "_notest.jl") && !contains(fn, "setup")
end

@time begin
    # tests in groups based on folder structure
    for testgroup in filter(isdir, readdir(@__DIR__; join = true))
        if GROUP == "ALL" || GROUP == uppercase(basename(testgroup))
            for filename in filter(istestfile, readdir(testgroup; join = true))
                if endswith(filename, "_mpi.jl")
                    for n in (1, 2, 4)
                        C = addenv(
                            `$(MPI.mpiexec()) -n $n $(Base.julia_cmd()) --startup-file=no $(filename)`,
                            "JULIA_MPI_TEST_NUM_PROCESSES" => string(n)
                        )
                        run(C)
                        @test true
                    end
                else
                    @eval @safetestset $(basename(filename)) begin
                        include($filename)
                    end
                end
            end
        end
    end

    # single files in top folder
    for file in filter(istestfile, readdir(@__DIR__; join = true))
        (basename(file) == basename(@__FILE__)) && continue # exclude this file to avoid infinite recursion
        if endswith(file, "_mpi.jl")
            for n in (1, 2, 4)
                C = addenv(
                    `$(MPI.mpiexec()) -n $n $(Base.julia_cmd()) --startup-file=no $(file)`,
                    "JULIA_MPI_TEST_NUM_PROCESSES" => string(n)
                )
                run(C)
                @test true
            end
        else
            @eval @safetestset $(basename(file)) begin
                include($file)
            end
        end
    end

    # test examples
    examplepath = joinpath(@__DIR__, "..", "examples")
    for (root, _, files) in walkdir(examplepath)
        contains(chopprefix(root, @__DIR__), "setup") && continue
        for file in filter(isexamplefile, files)
            filename = joinpath(root, file)
            for n in (1, 2, 4)
                C = addenv(
                    `$(MPI.mpiexec()) -n $n $(Base.julia_cmd()) --startup-file=no $(filename)`,
                    "JULIA_MPI_TEST_NUM_PROCESSES" => string(n)
                )
                run(C)
                @test true
            end
        end
    end
end
