using FastBroadcast
using SparseArrays
using PerformanceTestTools, Test

@testset "FastBroadcast" begin
    x, y = [1,2,3,4], [5,6,7,8]
    dst = zeros(Int, 4)
    bc = Broadcast.Broadcasted(+, (Broadcast.Broadcasted(*, (x, y)), x, y, x, y, x, y))
    bcref = copy(bc)
    @test FastBroadcast.fast_materialize!(dst, bc) == bcref
    dest = similar(bcref);
    @test (@.. dest = (x*y) + x + y + x + y + x + y) == bcref
    @test (@.. (x*y) + x + y + x + y + x + y) == bcref
    @test (@.. dest += (x*y) + x + y + x + y + x + y) ≈ 2bcref
    @test (@.. dest -= (x*y) + x + y + x + y + x + y) ≈ bcref
    @test (@.. dest *= (x*y) + x + y + x + y + x + y) ≈ abs2.(bcref)
    @test (@.. (x*y) + x + y + x*(3,4,5,6) + y + x * (1,) + y + 3) ≈ (@. (x*y) + x + y + x*(3,4,5,6) + y + x * (1,) + y + 3)
    A = rand(4,4);
    @test (@.. A * y' + x) ≈ (@. A * y' + x)
    @test (@.. A * transpose(y) + x) ≈ (@. A * transpose(y) + x)
    Ashim = A[1:1,:];
    @test (@.. Ashim * y' + x) ≈ (@. Ashim * y' + x) # test fallback
    Av = view(A,1,:);
    @test (@.. Av * y' + A) ≈ (@. Av * y' + A)
    B = similar(A);
    @.. B = A
    @test B == A
    @.. A = 3
    @test all(==(3), A)

    x = sparse([1, 2, 0, 4])
    y = sparse([1, 0, 0, 4])
    res = @.. x + y
    @test res isa SparseVector
    @test res == (@. x + y)
    res = @.. y = x + y
    @test res isa SparseVector
    @test res == [2, 2, 0, 8]
    res = @.. x = x + y
    @test res isa SparseVector
    @test res == [3, 4, 0, 12]
end

VERSION >= v"1.6" && PerformanceTestTools.@include("vectorization_tests.jl")
