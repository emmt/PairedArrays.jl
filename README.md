# PairedArrays [![Build Status](https://github.com/emmt/PairedArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/emmt/PairedArrays.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Build Status](https://ci.appveyor.com/api/projects/status/github/emmt/PairedArrays.jl?svg=true)](https://ci.appveyor.com/project/emmt/PairedArrays-jl) [![Coverage](https://codecov.io/gh/emmt/PairedArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/emmt/PairedArrays.jl)

`PairedArrays` is a [Julia](https://julialang.org) package providing paired
arrays build as:

``` julia
A = PairedArray(keys, vals)
```

where `keys` and `vals` are arrays of keys and values. The resulting paired array `A`
behaves as an array of same size as `keys` and `vals` whose elements are pairs.
More specifically, the syntax `A[i]` yields the pair `keys[i] => vals[i]` while `A[i]
= (key => val)` is equivalent to `keys[i] = key` and `vals[i] = val`.

A paired array is as fast but has less storage requirements (because data
alignment constraints are relaxed) than an array of pairs which could be built
as follows:

``` julia
B = [k => v for (k, v) in zip(keys, vals)]
```

To build an empty paired vector of pairs, do:

``` julia
B = PairedArray{K,V}()
```

with `K` and `V` the respective types of the keys and of the values. Then, this
array may be filled like a regular vector by calling:

``` julia
push!(B, k1=>v1)
push!(B, k2=>v2)
# and so on
```

Methods `push!`, `resize!`, and `sizehint!` are extended for paired arrays but
may not work for all the types of arrays `keys` and `vals`.

Paired arrays may be directly constructed from collections of pairs. For
example, the same paired vector can be built by any of:

``` julia
A = PairedArray("a"=>1, "b"=>2, "c"=>3)
B = PairedArray(("a"=>1, "b"=>2, "c"=>3))
C = PairedArray(["a"=>1, "b"=>2, "c"=>3])
```

Type parameters `K` and `V` may be specified with the `PairedArray` constructor
to force the types of the keys and of the values or to provide them when they
cannot be deduced form the type of the arguments. For example, a paired array
may be built from a general iterator, say `iter`, as:

``` julia
A = PairedArray{K,V}(iter)
```

Like any other arrays, an uninitialized paired array of given type and size is
built by:

``` julia
A = PairedArray{K,V}(undef, dims...)
```

By extending the `PairedArrays.pair` method for `typeof(x)` so that
`PairedArrays.pair(K,V,x)` yields an instance of `Pair{K,V}`, operations like
`A[i] = x` and `push!(A,x)` are also supported for the specific type of `x`.

Properties `A.keys` and `A.vals` respectively yield the arrays of keys and
values of the paired array `A`. Broadcasting or mapping methods `first` and
`last` on a paired array `A` respectively yield `A.keys` and `A.vals` with no
overheads. That is to say the following identities hold:

``` julia
first.(A) === A.keys
last.(A) === A.vals
map(first, A) === A.keys
map(last, A) === A.vals
```

Beware that these are different from `first(A)` and `last(A)` which
respectively yield the first and last pairs stored by `A`. These are also
different from `keys(A)` and `values(A)` which respectively yield iterators
over the indices of `A` and over the values of `A`. The latter is `A` itself.
