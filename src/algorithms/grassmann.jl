## Here, we overload some functions of the GrassmannMPS local module in MPSKit.jl
# TODO: With the style rewrite, this will become obsolete!

using MPSKit: AbstractMPSEnvironments, InfiniteEnvironments, MultilineEnvironments, AC_hamiltonian, recalculate!
using TensorKit
using OhMyThreads
import TensorKitManifolds.Grassmann
import MPSKit.GrassmannMPS: rmul
function MPSKit.GrassmannMPS.fg(
        state::FiniteMPS, operator::MPIOperator{O},
        envs::AbstractMPSEnvironments = environments(state, operator)
    ) where {O <: FiniteMPOHamiltonian}
    f = expectation_value(state, operator, envs)
    isapprox(imag(f), 0; atol = eps(abs(f))^(3 / 4)) || @warn "MPO might not be Hermitian: $f"
    gs = map(1:length(state)) do i
        AC′ = AC_hamiltonian(i, state, operator, state, envs) * state.AC[i]
        g = Grassmann.project(AC′, state.AL[i])
        return rmul(g, state.C[i]')
    end
    return real(f), gs
end
function MPSKit.GrassmannMPS.fg(
        state::InfiniteMPS, operator::MPIOperator{O},
        envs::AbstractMPSEnvironments = environments(state, operator)
    ) where {O <: InfiniteMPOHamiltonian}
    recalculate!(envs, state, operator, state)
    f = expectation_value(state, operator, envs)
    isapprox(imag(f), 0; atol = eps(abs(f))^(3 / 4)) || @warn "MPO might not be Hermitian: $f"

    A = Core.Compiler.return_type(Grassmann.project, Tuple{eltype(state), eltype(state)})
    gs = Vector{A}(undef, length(state))
    tmap!(gs, 1:length(state); scheduler = MPSKit.Defaults.scheduler[]) do i
        AC′ = AC_hamiltonian(i, state, operator, state, envs) * state.AC[i]
        g = Grassmann.project(AC′, state.AL[i])
        return rmul(g, state.C[i]')
    end
    return real(f), gs
end
function MPSKit.GrassmannMPS.fg(
        state::InfiniteMPS, operator::MPIOperator{O},
        envs::AbstractMPSEnvironments = environments(state, operator)
    ) where {O <: InfiniteMPO}
    recalculate!(envs, state, operator, state)
    f = expectation_value(state, operator, envs)
    isapprox(imag(f), 0; atol = eps(abs(f))^(3 / 4)) || @warn "MPO might not be Hermitian: $f"

    A = Core.Compiler.return_type(Grassmann.project, Tuple{eltype(state), eltype(state)})
    gs = Vector{A}(undef, length(state))
    tmap!(gs, eachindex(state); scheduler = MPSKit.Defaults.scheduler[]) do i
        AC′ = AC_hamiltonian(i, state, operator, state, envs) * state.AC[i]
        g = rmul!(Grassmann.project(AC′, state.AL[i]), -inv(f))
        return rmul(g, state.C[i]')
    end
    return -log(real(f)), gs
end
# function MPSKit.GrassmannMPS.fg(
#         state::MultilineMPS, operator::MultilineMPO,
#         envs::MultilineEnvironments = environments(state, operator)
#     )
#     @assert length(state) == 1 "not implemented"
#     recalculate!(envs, state, operator, state)
#     f = expectation_value(state, operator, envs)
#     isapprox(imag(f), 0; atol = eps(abs(f))^(3 / 4)) || @warn "MPO might not be Hermitian: $f"

#     A = Core.Compiler.return_type(Grassmann.project, Tuple{eltype(state), eltype(state)})
#     gs = Matrix{A}(undef, size(state))
#     tforeach(eachindex(state); scheduler = MPSKit.Defaults.scheduler[]) do i
#         AC′ = AC_hamiltonian(i, state, operator, state, envs) * state.AC[i]
#         g = rmul!(Grassmann.project(AC′, state.AL[i]), -inv(f))
#         gs[i] = rmul(g, state.C[i]')
#         return nothing
#     end
#     return -log(real(f)), gs
# end
