# # MPSKitParallel.jl

# Scale your quantum many-body simulations with `MPSKitParallel.jl`. By leveraging [`MPI.jl`](https://github.com/JuliaParallel/MPI.jl) for distributed computing, this package removes the memory limitations of single-node execution for [`MPSKit.jl`](https://github.com/QuantumKitHub/MPSKit.jl) workflows with large `MPO`s.

# Features:
# - Distributed Computing: Run MPS/MPO algorithms across multiple MPI ranks.
# - Infinite Systems: Primary support for infinite boundary conditions (thermodynamic limit).
# - Active Development: Growing support for finite algorithms and performance optimizations.

# Note: This is an independent project not affiliated with [QuantumKitHub](https://github.com/QuantumKitHub). We gratefully acknowledge helpful discussions with [Lukas Devos](https://github.com/lkdvos) and his work on related projects.

# ## Installation

# The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

# ```julia-repl
# pkg> add git@github.com:ManyBodyLab/MPSKitParallel.jl.git
# ```

# ## Code Samples

# ```julia
# julia> using MPSKit, MPSKitParallel
# ```

# ## License

# MPSKitParallel.jl is licensed under the [APL2 License](LICENSE). By using or interacting with this software in any way, you agree to the license of this software.
