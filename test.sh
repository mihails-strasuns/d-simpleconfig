set -e

export PATH=$PATH:$(realpath $bindir)

dub -q test
cd example
output=`dub run --arch=x86_64 -q -- --one value --two 42`
test "$output" = 'Config("value", 42, " strange value")'
