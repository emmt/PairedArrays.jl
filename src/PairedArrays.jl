module PairedArrays

export
    PairedArray,
    PairedVector,
    PairedMatrix

"""
    PairedArray(keys, vals) -> A

builds an array `A` such that the syntax `A[i]` yields the pair `keys[i] =>
vals[i]` while `A[i] = key => val` is equivalent to `keys[i] = key` and
`vals[i] = val`. In fact, the syntax `A[i] = x` is supported for any `x` that
can be converted to an instance of `Pair{K,V}`. Setting elements of a paired
array requires that `K` and `V` be both writable.

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

Base.push!(A::PairedArray{K,V}, x) where {K,V} =
    push!(A, convert(Pair{K,V}, x)::Pair{K,V})

function Base.push!(A::PairedArray{K,V}, x::Pair{K,V}) where {K,V}
    push!(A.keys, x.first)
    push!(A.vals, x.second)
    return A
end

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
