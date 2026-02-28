"""
    MPIOperator{O, F, C}

A wrapper type for MPI-based linear operators.
It wraps another operator of type `parent::O` and applies an MPI-based reduction using
the binary function `reduction::F` across the communicator `comm::C`, whenever the
operator is applied via `f(x)` or `f * x`.

The communicator can be a single `MPI.Comm` or a collection of communicators 
(e.g., `AbstractVector{<:MPI.Comm}` or `MPSKit.PeriodicVector`).
"""
struct MPIOperator{O, F, C}
    parent::O
    reduction::F
    comm::C
    MPIOperator{O, F, C}(parent::O, reduction::F = Base.:+, comm::C = MPI.COMM_WORLD) where {O, F, C} = new{O, F, C}(parent, reduction, comm)
    MPIOperator{O, F}(parent::O, reduction::F = Base.:+, comm::C = MPI.COMM_WORLD) where {O, F, C} = new{O, F, C}(parent, reduction, comm)
    MPIOperator{O}(parent::O, reduction::F = Base.:+, comm::C = MPI.COMM_WORLD) where {O, F, C} = new{O, F, C}(parent, reduction, comm)
    MPIOperator(parent::O, reduction::F = Base.:+, comm::C = MPI.COMM_WORLD) where {O, F, C} = new{O, F, C}(parent, reduction, comm)
end

Base.parent(op::MPIOperator) = op.parent

function (Op::MPIOperator{O, F})(x::S)::S where {O, F, S}
    y_per_rank = parent(Op)(x)::S
    return MPILargeCounts.allreduce!(y_per_rank, Op.reduction, Op.comm)
end

Base.:*(Op::MPIOperator, v) = Op(v)
(Op::MPIOperator)(x, ::Number) = Op(x)

function Base.show(io::IO, mime::MIME"text/plain", op::MPIOperator)
    print(io, "MPIOperator with communicator $(op.comm) and reduction $(op.reduction) wrapping:\n")
    return show(io, mime, parent(op))
end
Base.show(io::IO, op::MPIOperator) = show(convert(IOContext, io), op)
function Base.show(io::IOContext, op::MPIOperator)
    print(io, "MPIOperator with communicator $(op.comm) and reduction $(op.reduction) wrapping:\n")
    return show(io, parent(op))
end

# Overload base functions
@forward MPIOperator.parent Base.getindex, Base.size, Base.length, Base.iterate, Base.eltype, Base.axes, Base.similar, Base.eachindex, Base.lastindex, Base.setindex!
@forward_astype MPIOperator.parent Base.:+, Base.:-, Base.:*, Base.:/, Base.:\, Base.:(^), Base.conj!, Base.conj, Base.copy, Base.deepcopy
@forward_1_astype MPIOperator.parent Base.:*

# Overload LinearAlgebra functions
@forward MPIOperator.parent LinearAlgebra.norm

# Overload VectorInterface functions
@forward_astype MPIOperator.parent VectorInterface.scale, VectorInterface.scalartype

# Overload TensorKit functions
@forward MPIOperator.parent TensorKit.spacetype, TensorKit.sectortype, TensorKit.storagetype

# Overload MPSKit functions
@forward MPIOperator.parent MPSKit.eachsite, MPSKit.left_virtualspace, MPSKit.right_virtualspace, MPSKit.physicalspace
@forward_astype MPIOperator.parent MPSKit.remove_orphans!
@forward_1 MPIOperator.parent MPSKit._fuse_mpo_mpo

if isdefined(MPSKit, :OperatorStyle)
    MPSKit.OperatorStyle(::MPIOperator{O}) where {O} = MPSKit.OperatorStyle(O)
end
if isdefined(MPSKit, :GeometryStyle)
    MPSKit.GeometryStyle(::MPIOperator{O}) where {O} = MPSKit.GeometryStyle(O)
end

# ---------------------- MPSKit MPO constructor ------------------------
function MPIOperator(
        parent::O, reduction::F = Base.:+,
        comm::C = MPSKit.PeriodicVector([MPI.Comm_dup(MPI.COMM_WORLD) for _ in eachsite(parent)])
    ) where {O <: MPSKit.AbstractMPO, F, C}
    return MPIOperator{O, F, C}(parent, reduction, comm)
end
