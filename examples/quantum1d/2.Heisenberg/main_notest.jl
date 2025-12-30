using MPSKit, MPSKitModels, TensorKit
using MPSKitParallel
using MPI, MPILargeCounts
using MPILargeCounts: mpi_is_root
using Test

MPI.Init(; threadlevel = :multiple)
nprocs = MPI.Comm_size(MPI.COMM_WORLD)
verbosity = 3

spin = 1 // 2
J = 1.0
for sym in [TensorKit.Trivial, TensorKit.U1Irrep, TensorKit.SU2Irrep]
    verbosity > 0 && (@info "Running Heisenberg script with $nprocs MPI processes and sym = $sym")
    chain = InfiniteChain(2)
    H₀ = heisenberg_XXX(ComplexF64, sym, chain; J, spin)
    if sym == TensorKit.Trivial
        ψ₀ = InfiniteMPS([ℂ^2, ℂ^2], [ℂ^10, ℂ^10])
    elseif sym == TensorKit.U1Irrep
        physical_space = U1Space(-1 // 2 => 1, 1 // 2 => 1)
        V1 = U1Space(-1 => 2, 0 => 5, 1 => 2)
        V2 = U1Space(-3 // 2 => 2, -1 // 2 => 5, 1 // 2 => 5, 3 // 2 => 2)
        ψ₀ = InfiniteMPS([physical_space, physical_space], [V1, V2])
    elseif sym == TensorKit.SU2Irrep
        P = Rep[SU₂](1 // 2 => 1)
        V1 = Rep[SU₂](1 // 2 => 10, 3 // 2 => 5, 5 // 2 => 2)
        V2 = Rep[SU₂](0 => 15, 1 => 10, 2 => 5)
        ψ₀ = InfiniteMPS([P, P], [V1, V2])
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
