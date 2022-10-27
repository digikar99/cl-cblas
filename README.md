# cl-cblas

[C2FFI](https://github.com/rpav/c2ffi/) / [cl-autowrap](https://github.com/rpav/cl-autowrap) based wrapper for [CBLAS](http://www.netlib.org/blas/cblas.h).

Recommended installation: [OpenBLAS](http://www.openblas.net/), which should also be provided with your package manager. See [specs/cblas.h](src/cblas.h) for the API (taken from [netlib](https://netlib.org/blas/cblas.h)). 

## Other Solutions

[magicl](https://github.com/quil-lang/magicl) ships with BLAS and LAPACK bindings, however these are FORTRAN bindings. `cblas` provide C bindings, and these can be easier to work with given (i) a LAYOUT parameter allowing for both row-major or column-major matrices (ii) the absence of WORK parameters in several high level functions. In addition, the magicl generated high level bindings through the `magicl/ext-blas` or `magicl/ext-lapack` systems assume that the arguments will be undisplaced `simple-array`. While both [numcl](https://github.com/numcl/numcl) and [dense-numericals](https://github.com/digikar99/numericals) rely on displaced arrays. The cl-autowrap generated bindings expect pointer arguments which translate naturally to displaced arrays.
