function MPSKit.TransferMatrix(a, b::MPIOperator, c, isflipped = false)
    return MPSKit.TransferMatrix(a, parent(b), c, isflipped)
end
