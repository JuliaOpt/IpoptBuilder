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

for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done

if [ $target = "x86_64-apple-darwin14" ]; then
  # seems static linking requires apple's ar
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar

   # Ignore the "# Don't fix this by using the ld -exported_symbols_list flag, it doesn't exist in older darwin lds"
  # seems to work for the current version and otherwise a long list of non-Clp symbols are exported
  sed -i~ -e "s|~nmedit -s \$output_objdir/\${libname}-symbols.expsym \${lib}| -exported_symbols_list \$output_objdir/\${libname}-symbols.expsym|g" ../configure
fi

export CPPFLAGS="-DCOIN_USE_MUMPS_MPI_H"

## STATIC BUILD START
# Staticly link all dependencies and export only Ipopt symbols

# force only exporting symbols related to Ipopt
# SetIntermediateCallback is to fix https://github.com/JuliaOpt/IpoptBuilder/issues/2
sed -i~ -e 's|LT_LDFLAGS="-no-undefined"|LT_LDFLAGS="-no-undefined -export-symbols-regex \\\\"Ipopt\|SetIntermediateCallback\\\\""|g' ../configure
sed -i~ -e 's|LT_LDFLAGS="-no-undefined"|LT_LDFLAGS="-no-undefined -export-symbols-regex \\\\"Ipopt\|SetIntermediateCallback\\\\""|g' ../Ipopt/configure

../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --disable-static \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-asl-lib="-L${prefix}/lib -lasl" --with-asl-incdir="$prefix/include/asl" \
--with-blas="-L${prefix}/lib -lcoinblas -lgfortran" \
--with-lapack="-L${prefix}/lib -lcoinlapack" \
--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
--with-mumps-lib="-L${prefix}/lib -lcoinmumps -lcoinmetis" --with-mumps-incdir="$prefix/include/coin/ThirdParty"

## STATIC BUILD END

## DYNAMIC BUILD START
#../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --enable-static \
#--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
#--with-asl-lib="-L${prefix}/lib -lasl" --with-asl-incdir="$prefix/include/asl" \
#--with-blas="-L${prefix}/lib -lcoinblas -lgfortran" \
#--with-lapack="-L${prefix}/lib -lcoinlapack" \
#--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
#--with-mumps-lib="-L${prefix}/lib -lcoinmumps" --with-mumps-incdir="$prefix/include/coin/ThirdParty"
## DYNAMIC BUILD END

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)
# To fix gcc4 bug in Windows
#platforms = setdiff(platforms, [Windows(:x86_64, compiler_abi=CompilerABI(:gcc4)), Windows(:i686, compiler_abi=CompilerABI(:gcc4))])
push!(platforms, Windows(:i686,compiler_abi=CompilerABI(:gcc6)))
push!(platforms, Windows(:x86_64,compiler_abi=CompilerABI(:gcc6)))

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libipopt", :libipopt),
     ExecutableProduct(prefix, "ipopt", :amplexe)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/juan-pablo-vielma/ASLBuilder/releases/download/v3.1.0-1-static/build_ASLBuilder.v3.1.0.jl",
    "https://github.com/juan-pablo-vielma/COINBLASBuilder/releases/download/v1.4.6-1-static/build_COINBLASBuilder.v1.4.6.jl",
    "https://github.com/juan-pablo-vielma/COINLapackBuilder/releases/download/v1.5.6-1-static/build_COINLapackBuilder.v1.5.6.jl",
    "https://github.com/juan-pablo-vielma/COINMetisBuilder/releases/download/v1.3.5-1-static/build_COINMetisBuilder.v1.3.5.jl",
    "https://github.com/juan-pablo-vielma/COINMumpsBuilder/releases/download/v1.6.0-1-static/build_COINMumpsBuilder.v1.6.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
