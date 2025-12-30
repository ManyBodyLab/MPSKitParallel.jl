using Literate: Literate
using MPILargeCounts

Literate.markdown(
    joinpath(pkgdir(MPILargeCounts), "docs", "files", "README.jl"),
    joinpath(pkgdir(MPILargeCounts), "docs", "src");
    flavor = Literate.DocumenterFlavor(),
    name = "index",
)
