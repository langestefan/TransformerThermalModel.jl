using TransformerThermalModel
using TestItemRunner

include("linting.jl")

@run_package_tests verbose = true
