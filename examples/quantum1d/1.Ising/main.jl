using MPSKit, MPSKitModels, TensorKit
using MPSKitParallel
using MPI, MPILargeCounts
using MPILargeCounts: mpi_is_root
using Test

MPI.Init()
nprocs = MPI.Comm_size(MPI.COMM_WORLD)
verbosity = 3

for sym in [TensorKit.Trivial, TensorKit.Z2Irrep]
    verbosity > 0 && (@info "Running Ising script with $nprocs MPI processes and sym = $sym")
    if sym == TensorKit.Trivial
        ψ₀ = InfiniteMPS([ℂ^2], [ℂ^10])
        H₀ = transverse_field_ising(; g = -0.5)
    elseif sym == TensorKit.Z2Irrep
        chain = InfiniteChain(1)
        H₀ = transverse_field_ising(sym, chain; g = -0.5)
        physical_space = Z2Space(0 => 1, 1 => 1)
        virtual_space_inf = Z2Space(0 => 16, 1 => 16)

        ψ₀ = InfiniteMPS([physical_space], [virtual_space_inf])
    end
    ψ₀ = MPILargeCounts.bcast(ψ₀, MPI.COMM_WORLD)

    verbosity > 0 && println("Running VUMPS:")
    ψ, envs = find_groundstate(ψ₀, H₀, VUMPS(; verbosity = verbosity))

    E = expectation_value(ψ, H₀, envs)

    H_mpi = MPIOperator(H₀)
    MPI.Barrier(MPI.COMM_WORLD)
    verbosity > 0 && println("Running VUMPS with MPI:")
    ψ_mpi, envs_mpi = find_groundstate(ψ₀, H_mpi, VUMPS(; verbosity = verbosity))

    @test abs(dot(ψ, ψ_mpi)) ≈ 1 atol = 1.0e-6

    E2 = expectation_value(ψ_mpi, H_mpi, envs_mpi)

    @test E * nprocs ≈ E2 atol = 1.0e-6
end

MPI.Finalize()
@test MPI.Finalized()
