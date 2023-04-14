module TestingPairedArrays

using PairedArrays
using Test

struct MyPair{K,V}
    key::K
    val::V
end
PairedArrays.pair(::Type{K}, ::Type{V}, x::MyPair) where {K,V} =
    Pair{K,V}(x.key, x.val)

_keytype(x::Pair) = _keytype(typeof(x))
_valtype(x::Pair) = _valtype(typeof(x))
_keytype(::Type{Pair{K,V}}) where {K,V} = K
_valtype(::Type{Pair{K,V}}) where {K,V} = V

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

    # Check pushing and setting argument that is not directly a Pair.
    A = PairedArray(Symbol[], Int[])
    @test A isa PairedVector{Symbol,Int}
    @test length(A) == 0
    push!(A, MyPair(:x,1))
    @test length(A) == 1
    @test A[1] == (:x => 1)
    push!(A, MyPair(:y,2))
    @test length(A) == 2
    push!(A, MyPair(:z,3))
    @test length(A) == 3
    @test A[1] === (:x => 1)
    @test A[2] === (:y => 2)
    @test A[3] === (:z => 3)
    A[1] = MyPair(:a,11)
    A[2]     = MyPair(:b,12)
    A[end]   = MyPair(:c,13)
    @test A[1] === (:a => 11)
    @test A[2] === (:b => 12)
    @test A[3] === (:c => 13)

    # Now try with Cartesian indices. We use views to make sure that Cartesian
    # indexing is used.
    keys = view(rand(Int16, 2,3,4), :, 2, :)
    @test IndexStyle(keys) === IndexCartesian()
    vals = reshape(collect(1:length(keys)), size(keys))
    @inferred PairedArray(keys, vals)
    A = PairedArray(keys, vals)
    @test A isa PairedMatrix{Int16,Int}
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
    # Idem with non-standard pairs.
    for i in I, j in J
        A[i,j] = MyPair(-i, -j)
        @test A[i,j] == (-i => -j)
    end

    # Conversions.
    @test convert(PairedArray, A) === A
    B = convert(PairedArray{Int}, A)
    @test B isa PairedArray{Int,_valtype(eltype(A)),ndims(A)}
    @test B.keys !== A.keys && B.vals !== A.vals
    @test B == A
    B = convert(PairedArray{_keytype(eltype(A)),Int16}, A)
    @test B isa PairedArray{_keytype(eltype(A)),Int16,ndims(A)}
    @test B.keys !== A.keys && B.vals !== A.vals
    @test B == A

    # Copy constructor yields an independent copy.
    B = copy(A)
    @test B isa PairedArray{_keytype(eltype(A)),_valtype(eltype(A)),ndims(A)}
    @test B == A
    @test B.keys !== A.keys && B.vals !== A.vals
    x = A[firstindex(A)]
    @test B[firstindex(B)] == x
    B[firstindex(B)] = (first(x) => (iszero(last(x)) ? one(last(x)) : zero(last(x))))
    @test B[firstindex(B)] != x
    @test A[firstindex(A)] == x

    # Construction from collections of pairs.
    B = (:x=>1, :y=>2, :z=>3)
    C = collect(B)
    D = (B[i] for i in eachindex(B))
    A = PairedArray(B...)
    @test A isa PairedVector{Symbol,Int}
    @test A == C
    A = PairedArray(B)
    @test A isa PairedVector{Symbol,Int}
    @test A == C
    A = PairedArray(C)
    @test A isa PairedVector{Symbol,Int}
    @test A == C
    A = PairedVector{Symbol,Int}(D)
    @test A isa PairedVector{Symbol,Int}
    @test A == C

    @test_throws UndefVarError PairedArray()
    @test_throws UndefVarError PairedArray{Symbol}()
    A = PairedArray{Symbol,Int}()
    @test A isa PairedArray{Symbol,Int,1}
    @test length(A) == 0
    A = PairedArray{Symbol,Int,1}()
    @test A isa PairedArray{Symbol,Int,1}
    @test length(A) == 0
    @test_throws ArgumentError PairedVector()
    @test_throws ArgumentError PairedVector{Symbol}()
    A = PairedVector{Symbol,Int}()
    @test A isa PairedVector{Symbol,Int}
    @test length(A) == 0
    for x in B; push!(A, x); end
    @test A == C
end

end # module
