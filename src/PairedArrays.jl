module PairedArrays

export
    PairedArray,
    PairedVector,
    PairedMatrix

using Base: @propagate_inbounds

"""
    PairedArray(keys, vals) -> A

builds an array `A` such that the syntax `A[i...]` yields the pair `keys[i...]
=> vals[i...]` while `A[i...] = (key => val)` is equivalent to `keys[i...] =
key` and `vals[i...] = val`. In fact, the syntax `A[i...] = x` is supported for
any `x` that can be converted to an instance of `Pair{K,V}`. Setting elements
of a paired array requires that `keys` and `vals` be both writable.

A paired array is as fast but has less storage requirements (because data
alignment constraints are relaxed) than an array of pairs which could be built
as follows:

    B = [key => val for (key,val) in zip(keys, vals)]

Methods `push!`, `resize!`, and `sizehint!` are extended for paired arrays but
may or may not work depending on the types of the arrays `keys` and `vals`.

"""
struct PairedArray{K,V,N,I<:IndexStyle,
                   KA<:AbstractArray{K,N},
                   VA<:AbstractArray{V,N}} <: AbstractArray{Pair{K,V},N}
    keys::KA
    vals::VA
    function PairedArray(keys::KA, vals::VA) where {K,V,N,
                                                    KA<:AbstractArray{K,N},
                                                    VA<:AbstractArray{V,N}}
        axes(keys) == axes(vals) || throw(DimensionMismatch(
            "keys and values must have the same indices"))
        I = typeof(IndexStyle(keys, vals))
        return new{K,V,N,I,KA,VA}(keys, vals)
    end
end

const PairedVector{K,V,I,KA,VA} = PairedArray{K,V,1,I,KA,VA}
const PairedMatrix{K,V,I,KA,VA} = PairedArray{K,V,2,I,KA,VA}

# Copy constructor.
Base.copy(A::PairedArray) = PairedArray(copy(A.keys), copy(A.vals))

# Conversion constructors. NOTE: A paired array cannot be partially converted.
# Either exactly the same array or a new paired array with fresh pair of arrays
# to store the contents is returned.
PairedArray(A::PairedArray) = A

PairedArray{K}(A::PairedArray{K}) where {K} = A
PairedArray{K}(A::PairedArray{<:Any,V}) where {K,V} = PairedArray{K,V}(A)

PairedArray{K,V}(A::PairedArray{K,V}) where {K,V} = A
PairedArray{K,V}(A::PairedArray{<:Any,<:Any}) where {K,V} =
    # If any of the key or value types are different, copy and convert the two
    # arrays backing the storage of the keys and of the values.
    PairedArray(copyto!(similar(A.keys, K), A.keys),
                copyto!(similar(A.vals, V), A.vals))

PairedArray{K,V,N}(A::PairedArray{K,V,N}) where {K,V,N} = A
PairedArray{K,V,N}(A::PairedArray{<:Any,<:Any,N}) where {K,V,N} =
    # Get rid of the N parameter.
    PairedArray{K,V}(A)

# Constructors for uninitialized contents.
PairedArray{K,V}(::UndefInitializer, dims::Integer...) where {K,V} =
    PairedArray{K,V}(undef, dims)
PairedArray{K,V}(::UndefInitializer, dims::NTuple{N,Integer}) where {K,V,N} =
    PairedArray{K,V,N}(undef, dims)
PairedArray{K,V,N}(::UndefInitializer, dims::Integer...) where {K,V,N} =
    PairedArray{K,V,N}(undef, dims)
PairedArray{K,V,N}(::UndefInitializer, dims::NTuple{N,Integer}) where {K,V,N} =
    PairedArray{K,V,N}(undef, convert(Dims{N}, dims)::Dims{N})
PairedArray{K,V,N}(::UndefInitializer, dims::Dims{N}) where {K,V,N} =
    PairedArray(Array{K,N}(undef, dims), Array{V,N}(undef, dims))

# Conversions from collections of pairs.
PairedArray(A::AbstractArray{Pair{K,V}}) where {K,V} = PairedArray{K,V}(A)
PairedArray{K}(A::AbstractArray{Pair{<:Any,V}}) where {K,V} = PairedArray{K,V}(A)
PairedArray{K,V,N}(A::AbstractArray{<:Pair,N}) where {K,V,N} = PairedArray{K,V}(A)
function PairedArray{K,V}(A::AbstractArray{<:Pair}) where {K,V}
    B = PairedArray(similar(A, K), similar(A, V))
    @inbounds @simd for i in eachindex(A, B)
        B[i] = A[i]
    end
    return B
end

# Build paired arrays from nothing or 0-tuple.
PairedVector() = throw(ArgumentError("types K and V of keys and values must be specified"))
PairedVector{K}() where {K} = throw(ArgumentError("type V of values must be specified"))
PairedVector{K,V}() where {K,V} = PairedArray(Vector{K}(undef,0), Vector{V}(undef,0))
for X in (:PairedArray, :PairedVector)
    @eval $X(::Tuple{}) = PairedVector()
    @eval $X{K}(::Tuple{}) where {K} = PairedVector{K}()
    @eval $X{K,V}(::Tuple{}) where {K,V} = PairedVector{K,V}()
    if X === :PairedArray
        @eval $X() = PairedVector()
        @eval $X{K}() where {K} = PairedVector{K}()
        @eval $X{K,V}() where {K,V} = PairedVector{K,V}()
        @eval $X{K,V,1}() where {K,V} = PairedVector{K,V}()
    end
end

# Build paired arrays from tuples.
for X in (:PairedArray, :PairedVector)
    @eval $X(pairs::Vararg{Pair{K,V}}) where {K,V} = PairedVector{K,V}(pairs)
    @eval $X(pairs::Tuple{Vararg{Pair{K,V}}}) where {K,V} = PairedVector{K,V}(pairs)
    @eval $X{K}(pairs::Vararg{Pair{<:Any,V}}) where {K,V} = PairedVector{K,V}(pairs)
end
PairedArray{K,V}(pairs::Tuple{Vararg{Pair}}) where {K,V} = PairedVector{K,V}(pairs)
PairedArray{K,V,1}(pairs::Tuple{Vararg{Pair}}) where {K,V} = PairedVector{K,V}(pairs)
function PairedVector{K,V}(A::NTuple{N,Pair}) where {K,V,N}
    B = PairedArray(Vector{K}(undef, N), Vector{V}(undef, N))
    @inbounds for i in 1:N
        B[i] = A[i]
    end
    return B
end

PairedArray{K,V}(iter) where {K,V} = PairedVector{K,V}(iter)
PairedVector{K,V}(iter) where {K,V} =
    build(PairedVector{K,V}, Base.IteratorSize(iter), iter)
function build(::Type{PairedVector{K,V}}, ::Base.SizeUnknown, iter) where {K,V}
    B = PairedVector{K,V}()
    for x in iter
        push!(B, x)
    end
    return B
end
function build(::Type{PairedVector{K,V}}, ::Base.HasLength, iter) where {K,V}
    len = length(iter)
    B = PairedArray(Vector{K}(undef, len), Vector{V}(undef, len))
    for (i,x) in enumerate(iter)
        B[i] = x
    end
    return B
end
function build(::Type{PairedVector{K,V}}, ::Base.HasShape{N}, iter) where {K,V,N}
    inds = axes(iter)
    all(r -> first(r) == 1, inds) || throw(ArgumentError("only 1-based indices are allowed"))
    dims = map(length, inds)
    B = PairedArray(Array{K,N}(undef, dims), Array{V,N}(undef, dims))
    for (i,x) in enumerate(iter)
        B[i] = x
    end
    return B
end

Base.convert(::Type{T}, A::T) where {T<:PairedArray} = A
Base.convert(::Type{T}, A) where {T<:PairedArray} = T(A)

Base.IndexStyle(::Type{<:PairedArray{K,V,N,I}}) where {K,V,N,I} = I()
Base.length(A::PairedArray) = length(A.keys)
Base.size(A::PairedArray) = size(A.keys)
Base.axes(A::PairedArray) = axes(A.keys)

const PairedArrayLinear{K,V,N,KA,VA} = PairedArray{K,V,N,IndexLinear,KA,VA}
const PairedArrayCartesian{K,V,N,KA,VA} = PairedArray{K,V,N,IndexCartesian,KA,VA}

@inline function Base.getindex(A::PairedArrayLinear, i::Int)
    @boundscheck checkbounds(A, i)
    @inbounds begin
        key = getindex(A.keys, i)
        val = getindex(A.vals, i)
    end
    return key => val
end

@inline function Base.getindex(A::PairedArrayCartesian{<:Any,<:Any,N},
                               I::Vararg{Int,N}) where {N}
    @boundscheck checkbounds(A, I...)
    @inbounds begin
        key = getindex(A.keys, I...)
        val = getindex(A.vals, I...)
    end
    return key => val
end

@inline function Base.setindex!(A::PairedArrayLinear, x::Pair, i::Int)
    @boundscheck checkbounds(A, i)
    @inbounds begin
        setindex!(A.keys, x.first, i)
        setindex!(A.vals, x.second, i)
    end
    return A
end

@inline function Base.setindex!(A::PairedArrayCartesian{<:Any,<:Any,N},
                                x::Pair, I::Vararg{Int,N}) where {N}
    @boundscheck checkbounds(A, I...)
    @inbounds begin
        setindex!(A.keys, x.first, I...)
        setindex!(A.vals, x.second, I...)
    end
    return A
end

function Base.push!(A::PairedVector, x::Pair)
    push!(A.keys, x.first)
    push!(A.vals, x.second)
    return A
end

"""
    PairedArrays.pair(K,V,x) -> p::Pair{K,V}

yields argument `x` converted to a pair `p` of type `Pair{K,V}`. By default,
this method amounts to evaluating `convert(Pair{K,V},x)::Pair`, but is intended
to be extended for specific `typeof(x)` by other packages for their own types.
To avoid stack overflow errors (due to infinite recursive calls), the extend
methods shall insure that they return a `Pair`.

"""
pair(::Type{K}, ::Type{V}, x::Pair{K,V}) where {K,V} = x
pair(::Type{K}, ::Type{V}, x) where {K,V} = convert(Pair{K,V}, x)::Pair

@inline @propagate_inbounds function Base.setindex!(A::PairedArrayLinear{K,V},
                                                    x, i::Int) where {K,V}
    return setindex!(A, pair(K,V,x), i)
end
@inline @propagate_inbounds function Base.setindex!(A::PairedArrayCartesian{K,V,N},
                                                    x, I::Vararg{Int,N}) where {K,V,N}
    return setindex!(A, pair(K,V,x), I...)
end
Base.push!(A::PairedArray{K,V}, x) where {K,V} = push!(A, pair(K,V,x))

function Base.resize!(A::PairedArray, newlen::Integer)
    # First try to resize keys, then vals. If the latter fails, restore the
    # previous size.
    newlen ≥ zero(newlen) || throw(ArgumentError("length must be nonnegative"))
    if newlen != length(A.keys)
        resize!(A.keys, newlen)
    end
    if newlen != length(A.vals)
        try
            resize!(A.vals, newlen)
        catch error
            resize!(A.keys, length(A.vals))
            throw(error)
        end
    end
    return A
end

function Base.sizehint!(A::PairedArray, len::Integer)
    sizehint!(A.keys, len)
    sizehint!(A.vals, len)
    return A
end

# Accelarate some operations.
Base.Broadcast.broadcasted(::typeof(first), A::PairedArray) = A.keys
Base.Broadcast.broadcasted(::typeof(last), A::PairedArray) = A.vals
Base.map(::typeof(first), A::PairedArray) = A.keys
Base.map(::typeof(last), A::PairedArray) = A.vals

end # module
