# PairedArrays [![Build Status](https://github.com/emmt/PairedArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/emmt/PairedArrays.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Build Status](https://ci.appveyor.com/api/projects/status/github/emmt/PairedArrays.jl?svg=true)](https://ci.appveyor.com/project/emmt/PairedArrays-jl) [![Coverage](https://codecov.io/gh/emmt/PairedArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/emmt/PairedArrays.jl)

`PairedArrays` is a small [Julia](https://julialang.org) package providing
paired arrays build as:

``` julia
A = PairedArray(K, V)
```

where `K` and `V` are arrays of keys and values. The resulting paired array `A`
behaves as an array of same size as `keys` and `vals` whose elements are pairs.
More specifically, the syntax `A[i]` yields the pair `K[i] => V[i]` while `A[i]
= key => val` is equivalent to `K[i] = key` and `V[i] = val`. In fact, the
syntax `A[i] = x` is supported for any `x` that can be converted to an instance
of `Pair{eltype(K),eltype(V)}`.

A paired array is as fast but has less storage requirements (because data
alignment constraints are relaxed) than an array of pairs which could be built
as follows:

``` julia
B = [k => v for (k, v) in zip(K, V)]
```

Methods `push!`, `resize!`, and `sizehint!` are extended for paired arrays but
may or may not work depending on the types of the arrays `K` and `V`.

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
