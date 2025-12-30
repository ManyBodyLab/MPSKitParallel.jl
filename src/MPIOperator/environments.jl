# Overload MPSKit
@forward_1 MPIOperator.parent MPSKit.environments, MPSKit.initialize_environments, MPSKit.environment_alg
@forward_2 MPIOperator.parent MPSKit.recalculate!, MPSKit.issamespace, MPSKit.compute_leftenvs!, MPSKit.compute_rightenvs!

function TensorKit.normalize!(
        envs::AbstractMPSEnvironments, below, operator::MPIOperator, above; kwargs...
    )
    return TensorKit.normalize!(envs, below, parent(operator), above; kwargs...)
end
# TODO: Use styles when released
# This function improves the normalization, as it only requires the communication of a scalar instead of the output tensor
function TensorKit.normalize!(
        envs::InfiniteEnvironments, below::InfiniteMPS, operator::MPIOperator{InfiniteMPO},
        above::InfiniteMPS
    )
    for i in 1:length(operator)
        normalize!(envs.GRs[i])
        Hc = C_hamiltonian(i, below, parent(operator), above, envs)
        λ = dot(below.C[i], Hc * above.C[i])
        λ = MPI.Allreduce(λ, +, MPI.COMM_WORLD)
        scale!(envs.GLs[i + 1], inv(λ))
    end
    return envs
end
