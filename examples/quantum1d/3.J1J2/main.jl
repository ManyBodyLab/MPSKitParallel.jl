using MPSKit, MPSKitModels, TensorKit
using MPSKitParallel
using MPI, MPILargeCounts
using MPILargeCounts: mpi_is_root
using Test

MPI.Init(; threadlevel = :multiple)
nprocs = MPI.Comm_size(MPI.COMM_WORLD)
mpi_rank = MPI.Comm_rank(MPI.COMM_WORLD)
verbosity = mpi_is_root() ? 1 : 0

verbosity = 3
verbosity > 0 && (@info "Running J1-J2 script with $nprocs MPI processes")

j2 = 0.4
for N in [2, 4, 6]
    nprocs == 1 && break

    H_J1 = @mpoham sum(S_exchange(; spin = 1 // 2){i, j} for (i, j) in nearest_neighbours(InfiniteChain(N)))
    H_J2 = @mpoham sum(rmul!(S_exchange(; spin = 1 // 2){i, j}, j2) for (i, j) in next_nearest_neighbours(InfiniteChain(N)))

    H_J1J2 = H_J1 + H_J2
    state = InfiniteMPS(fill(2, N), fill(20, N))
    state_init = copy(state)
    state = MPILargeCounts.bcast(state, MPI.COMM_WORLD)

    verbosity > 0 && println("Running VUMPS & Gradient Grassmann:")
    ψ_inf, envs, delta = find_groundstate(
        state, H_J1J2, verbosity = verbosity
    )

    verbosity > 0 && println("Running IDMRG2:")
    ψ_inf_idmrg2, envs_idmrg2, delta_idmrg2 = find_groundstate(
        state, H_J1J2, IDMRG2(; maxiter = 20, tol = 1.0e-12, verbosity = verbosity, trscheme = truncrank(50))
    )

    E = expectation_value(ψ_inf, H_J1J2, envs)
    E_idmrg2 = expectation_value(ψ_inf_idmrg2, H_J1J2, envs_idmrg2)

    ## Now, we run MPI:
    J2 = j2 / (nprocs - 1)
    if mpi_rank == 0
        H_mpi = @mpoham sum(S_exchange(; spin = 1 // 2){i, j} for (i, j) in nearest_neighbours(InfiniteChain(N)))
    else
        H_mpi = @mpoham sum(rmul!(S_exchange(; spin = 1 // 2){i, j}, J2) for (i, j) in next_nearest_neighbours(InfiniteChain(N)))
    end
    H_mpi = MPIOperator(H_mpi)

    verbosity > 0 && println("Running VUMPS & Gradient Grassmann with MPI:")
    ψ_infmpi, envs_infmpi, delta_infmpi = find_groundstate(state, H_mpi, verbosity = verbosity)   ## This tests VUMPS and GradientGrassmann
    E_mpi = expectation_value(ψ_infmpi, H_mpi, envs_infmpi)
    @test E ≈ E_mpi atol = 1.0e-6
    @test abs(dot(ψ_inf, ψ_infmpi)) ≈ 1 atol = 1.0e-6

    MPSKit.Defaults.set_scheduler!(:dynamic)
    verbosity > 0 && println("Running VUMPS & Gradient Grassmann with MPI & unit cell parallelization:")
    ψ_infmpi, envs_infmpi, delta_infmpi = find_groundstate(state, H_mpi, verbosity = verbosity)   ## This tests VUMPS and GradientGrassmann with unit cell parallelization
    E_mpi = expectation_value(ψ_infmpi, H_mpi, envs_infmpi)
    @test E ≈ E_mpi atol = 1.0e-6
    @test abs(dot(ψ_inf, ψ_infmpi)) ≈ 1 atol = 1.0e-6

    verbosity > 0 && println("Running IDMRG with MPI:")
    ψ_infmpi, envs_infmpi, delta_infmpi = find_groundstate(state, H_mpi, IDMRG(; maxiter = 20, tol = 1.0e-12, verbosity = verbosity))
    E_mpi = expectation_value(ψ_infmpi, H_mpi, envs_infmpi)
    @test E ≈ E_mpi atol = 1.0e-6
    @test abs(dot(ψ_inf, ψ_infmpi)) ≈ 1 atol = 1.0e-6

    verbosity > 0 && println("Running IDMRG2 with MPI:")
    ψ_infmpi, envs_infmpi, delta_infmpi = find_groundstate(state, H_mpi, IDMRG2(; maxiter = 20, tol = 1.0e-12, verbosity = verbosity, trscheme = truncrank(50)))
    E_mpi = expectation_value(ψ_infmpi, H_mpi, envs_infmpi)
    @test E_idmrg2 ≈ E_mpi atol = 1.0e-6
    @test abs(dot(ψ_inf_idmrg2, ψ_infmpi)) ≈ 1 atol = 1.0e-6
end

MPI.Finalize()
@test MPI.Finalized()
