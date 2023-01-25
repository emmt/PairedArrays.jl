module TestingPairedArrays

using PairedArrays
using Test

@testset "PairedArrays.jl" begin
    # First try with linear indices.
    keys = [:a, :b, :c]
    vals = -1:2:3
    @inferred PairedArray(keys, vals)
    A = PairedArray(keys, vals)
    @test length(A) == length(keys)
    @test size(A) == size(keys)
    @test axes(A) == axes(keys)
    @test IndexStyle(A) === IndexStyle(keys, vals)
    @test A.keys === keys
    @test A.vals === vals
    @test first.(A) === keys
    @test last.(A) === vals
    @test map(first, A) === keys
    @test map(last, A) === vals
    B = [key => val for (key, val) in zip(keys, vals)]
    @test A == B
    @test length(resize!(A, length(A))) == length(B)
    # Values (a range) are not writable, and so should be A. However, since
    # setting A[i] may only be partial (the keys are writable, not the values),
    # we set the same value to avoid differences later.
    @test_throws Exception A[1] = A[1]
    # Resizing should fail because values are a range. Do not test that by
    # shrinking A as it would result in indefined entries (because A.keys and
    # keys are the same object).
    @test_throws Exception resize!(A, length(A) + 1)
    A = sizehint!(PairedArray(keys, collect(vals)), 20)
    @test_throws ArgumentError resize!(A, -1)
    @test length(resize!(A, length(A) + 1)) == length(B) + 1
    @test !isdefined(A, lastindex(A))
    @test length(resize!(A, length(A) - 1)) == length(B)
    @test A == B
    @test length(push!(A, :x => 15)) == length(B) + 1
    @test push!(B, A[end]) == A
    A[2] = (:z => 42)
    @test A[2] == (:z => 42)
    push!(A, :w => 0x0ff) # push so as to force conversion
    @test A[end] == (:w => 255)
    # Now try with Cartesian indices. We use views to make sure that Cartesian
    # indexing is used.
    keys = view(rand(Int16, 2,3,4), :, 2, :)
    @test IndexStyle(keys) === IndexCartesian()
    vals = reshape(collect(1:length(keys)), size(keys))
    @inferred PairedArray(keys, vals)
    A = PairedArray(keys, vals)
    @test ndims(A) == ndims(keys) == 2
    @test length(A) == length(keys)
    @test size(A) == size(keys)
    @test axes(A) == axes(keys)
    @test IndexStyle(A) === IndexCartesian()
    @test A.keys === keys
    @test A.vals === vals
    @test first.(A) === keys
    @test last.(A) === vals
    @test map(first, A) === keys
    @test map(last, A) === vals
    B = [key => val for (key, val) in zip(keys, vals)]
    @test A == B # not same shape but same contents
    I, J = axes(A)
    for i in I, j in J
        A[i,j] = (i => j)
        @test A[i,j] == (i => j)
    end
end

end # module
