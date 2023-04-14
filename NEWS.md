# User visible changes in `PairedArrays` package

## Version 0.1.1

- Provides aliases `PairedVector{K,V}` and `PairedMatrix{K,V}` for
  `PairedArray{K,V,1}` and `PairedArray{K,V,2}`.

- Provide many more constructors, converters, etc. to copy paired arrays and
  build paired arrays from collections of pairs.

- Other packages may extend method `PairedArrays.pair(K,V,x)` for specific
  `typeof(x)` to convert `x` into a pair of type `Pair{K,V}`.

## Version 0.1.0

First registered version.
