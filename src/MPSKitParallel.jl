"""
Distributed computing (MPI) for MPSKit.jl
"""
module MPSKitParallel

# Public API
# ----------
# utility:

# MPOs
export MPIOperator

# Imports
# -------
using TensorKit
using MPSKit
using MPI
using MacroTools
using LinearAlgebra
using VectorInterface

using MPILargeCounts

import LinearAlgebra: norm
import VectorInterface: scale
import MPSKit: environments, AbstractMPSEnvironments, InfiniteEnvironments
import MPSKit: C_hamiltonian, AC_hamiltonian, AC2_hamiltonian, C_projection, AC_projection, AC2_projection
import MPSKit: exact_diagonalization

using MPSKit: IterativeSolver, VUMPSState, AbstractMPS, Multiline, eachsite, fixedpoint, regauge!, left_orth, left_orth!, right_orth, right_orth!, transfer_leftenv!, transfer_rightenv!, svd_trunc!
using MPSKit: AC2, _transpose_front, _transpose_tail, _mul_front, _mul_tail, AC_hamiltonian, AC2_hamiltonian, _firstspace
using MPSKit: _mul_front
using MPSKit.DynamicTols: updatetol
using Base.Threads: @spawn, @sync

include("utility/forward.jl")

include("MPIOperator/mpioperator.jl")
include("MPIOperator/derivatives.jl")
include("MPIOperator/environments.jl")
include("MPIOperator/ortho.jl")
include("MPIOperator/transfermatrix.jl")
include("algorithms/expval.jl")
include("algorithms/grassmann.jl")

include("algorithms/groundstate/vumps.jl")
include("algorithms/groundstate/idmrg.jl")

end
