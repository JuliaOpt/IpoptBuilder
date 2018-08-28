# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "IpoptBuilder"
version = v"3.12.10"

# Collection of sources required to build IpoptBuilder
sources = [
    "https://github.com/coin-or/Ipopt/archive/releases/3.12.10.tar.gz" =>
    "dfd29dc95ec815e1ff0a3b7dc86ecc8944b24977e40724c35dac25aa192ac3cd",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Ipopt-releases-3.12.10/
update_configure_scripts
mkdir build
cd build/
export CPPFLAGS="-DCOIN_USE_MUMPS_MPI_H"
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all --with-asl-lib="-L${prefix}/lib -lasl" --with-asl-incdir="$prefix/include/asl" --with-blas="-L${prefix}/lib -lcoinblas -lgfortran" --with-lapack="-L${prefix}/lib -lcoinlapack" --with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" --with-mumps-lib="-L${prefix}/lib -lcoinmumps" --with-mumps-incdir="$prefix/include/coin/ThirdParty" 
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc, :eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libipopt", :libipopt)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/juan-pablo-vielma/ASLBuilder/releases/download/v3.1.0-beta2/build_ASLBuilder.v3.1.0.jl",
    "https://github.com/juan-pablo-vielma/COINBLASBuilder/releases/download/v1.4.6-beta2/build_COINBLASBuilder.v1.4.6.jl",
    "https://github.com/juan-pablo-vielma/COINLapackBuilder/releases/download/v1.5.6-beta/build_COINLapackBuilder.v1.5.6.jl",
    "https://github.com/juan-pablo-vielma/COINMetisBuilder/releases/download/v1.3.5-beta/build_COINMetisBuilder.v1.3.5.jl",
    "https://github.com/juan-pablo-vielma/COINMumpsBuilder/releases/download/v1.6.0-beta/build_COINMumpsBuilder.v1.6.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

