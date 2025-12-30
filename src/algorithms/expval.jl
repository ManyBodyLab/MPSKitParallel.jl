function MPSKit.expectation_value(
        ψ::InfiniteMPS, H::MPIOperator{<:InfiniteMPOHamiltonian},
        envs::AbstractMPSEnvironments = environments(ψ, H)
    )
    res = MPSKit.expectation_value(ψ, parent(H), envs)
    return MPI.Allreduce(res, +, MPI.COMM_WORLD)
end
