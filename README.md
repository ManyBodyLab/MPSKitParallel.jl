# MPSKitParallel.jl

| **Documentation** | **Downloads** |
|:-----------------:|:-------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![Downloads][downloads-img]][downloads-url]

| **Build Status** | **Coverage** | **Style Guide** | **Quality assurance** |
|:----------------:|:------------:|:---------------:|:---------------------:|
| [![CI][ci-img]][ci-url] | [![Codecov][codecov-img]][codecov-url] | [![code style: runic][codestyle-img]][codestyle-url] | [![Aqua QA][aqua-img]][aqua-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://manybodylab.github.io/MPSKitParallel.jl/stable

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://manybodylab.github.io/MPSKitParallel.jl/dev

[doi-img]: https://zenodo.org/badge/DOI/
[doi-url]: https://doi.org/

[downloads-img]: https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Ftotal_downloads%2FMPILarge&query=total_requests&label=Downloads
[downloads-url]: http://juliapkgstats.com/pkg/MPSKitParallel

[ci-img]: https://github.com/ManyBodyLab/MPSKitParallel.jl/actions/workflows/Tests.yml/badge.svg
[ci-url]: https://github.com/ManyBodyLab/MPSKitParallel.jl/actions/workflows/Tests.yml

[pkgeval-img]: https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/M/MPSKitParallel.svg
[pkgeval-url]: https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/M/MPSKitParallel.html

[codecov-img]: https://codecov.io/gh/ManyBodyLab/MPSKitParallel.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/ManyBodyLab/MPSKitParallel.jl

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl

[codestyle-img]: https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black
[codestyle-url]: https://github.com/fredrikekre/Runic.jl

Scale your quantum many-body simulations with `MPSKitParallel.jl`. By leveraging [`MPI.jl`](https://github.com/JuliaParallel/MPI.jl) for distributed computing, this package removes the memory limitations of single-node execution for [`MPSKit.jl`](https://github.com/QuantumKitHub/MPSKit.jl) workflows with large `MPO`s.

Features:
- Distributed Computing: Run MPS/MPO algorithms across multiple MPI ranks.
- Infinite Systems: Primary support for infinite boundary conditions (thermodynamic limit).
- Active Development: Growing support for finite algorithms and performance optimizations.

Note: This is an independent project not affiliated with [QuantumKitHub](https://github.com/QuantumKitHub). We gratefully acknowledge helpful discussions with [Lukas Devos](https://github.com/lkdvos) and his work on related projects.

## Installation

The package is not yet registered in the Julia general registry. It can be installed trough the package manager with the following command:

```julia-repl
pkg> add git@github.com:ManyBodyLab/MPSKitParallel.jl.git
```

## Code Samples

```julia
julia> using MPSKit, MPSKitParallel
```

## License

MPSKitParallel.jl is licensed under the [APL2 License](LICENSE). By using or interacting with this software in any way, you agree to the license of this software.
