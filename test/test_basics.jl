using MPSKit, MPSKitParallel
using TensorKit
using TensorKit: ℙ
using MPI
using Test
using TestExtras

MPI.Init()
nprocs = MPI.Comm_size(MPI.COMM_WORLD)

pspaces = (ℙ^4, Rep[U₁](0 => 2), Rep[SU₂](1 => 1))
vspaces = (ℙ^10, Rep[U₁]((0 => 20)), Rep[SU₂](1 // 2 => 10, 3 // 2 => 5, 5 // 2 => 1))

@testset "test basics" begin
    @testset "MPI operator fields" begin
        mat = reshape(collect(1:16), 4, 4)
        function op(x::S)::S where {S}
            return mat * x
        end
        mpi_op = MPIOperator(op)
        @test parent(mpi_op) == op
        @test mpi_op.reduction == Base.:+
        @test mpi_op.comm == MPI.COMM_WORLD

        v = [1.0, 2, 3, 4]
        @test mpi_op(v) ≈ mpi_op * v ≈ nprocs * mat * v
        @constinferred mpi_op(v)
    end

    @testset "Styles" begin
        @testset "FiniteMPO" begin
            L = 4
            T = ComplexF64
            for V in (ℂ^2, U1Space(0 => 1, 1 => 1))
                O₁ = rand(T, V^L, V^L)

                mpo₁ = MPIOperator(FiniteMPO(O₁))

                @test @constinferred MPSKit.OperatorStyle(mpo₁) == MPSKit.MPOStyle()
                @test @constinferred MPSKit.GeometryStyle(mpo₁) == MPSKit.FiniteChainStyle()
            end
        end

        @testset "InfiniteMPO" begin
            P = ℂ^2
            T = Float64

            H1 = randn(T, P ← P)
            H1 += H1'
            H = MPIOperator(InfiniteMPO([H1]))

            @test @constinferred MPSKit.OperatorStyle(H) == MPSKit.MPOStyle()
            @test @constinferred MPSKit.GeometryStyle(H) == MPSKit.InfiniteChainStyle()
        end

        @testset "Finite MPOHamiltonian" begin
            L = 3
            T = ComplexF64
            for T in (Float64, ComplexF64), V in (ℂ^2, U1Space(-1 => 1, 0 => 1, 1 => 1))
                lattice = fill(V, L)
                O₁ = randn(T, V, V)
                O₁ += O₁'

                H1 = MPIOperator(FiniteMPOHamiltonian(lattice, i => O₁ for i in 1:L))
                @test @constinferred MPSKit.OperatorStyle(H1) == MPSKit.HamiltonianStyle()
                @test @constinferred MPSKit.GeometryStyle(H1) == MPSKit.FiniteChainStyle()

                @test parent(H1) == FiniteMPOHamiltonian(lattice, i => O₁ for i in 1:L)
            end
        end

        @testset "Infinite MPOHamiltonian" begin
            for (pspace, Dspace) in zip(pspaces, vspaces)
                # generate a 1-2-3 body interaction
                operators = ntuple(3) do i
                    O = rand(ComplexF64, pspace^i, pspace^i)
                    return O += O'
                end

                H1 = InfiniteMPOHamiltonian(operators[1])
                @test parent(MPIOperator(H1)) == H1
                @test @constinferred MPSKit.OperatorStyle(MPIOperator(H1)) == MPSKit.HamiltonianStyle()
                @test @constinferred MPSKit.GeometryStyle(MPIOperator(H1)) == MPSKit.InfiniteChainStyle()
            end
        end
    end

    @testset "Finalize MPI" begin
        MPI.Finalize()
        @test MPI.Finalized()
    end
end
