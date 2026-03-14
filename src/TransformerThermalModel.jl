module TransformerThermalModel

using Dates
import ModelingToolkitBase as MTK
using ModelingToolkitBase: t_nounits as t, D_nounits as D, @variables
using ModelingToolkitInputs: InputSystem, Input

# ---------------------------------------------------------------------------
# Top-level abstract types and spec structs (no dependencies)
# ---------------------------------------------------------------------------
include("types.jl")

# ---------------------------------------------------------------------------
# Cooler and insulation types
# ---------------------------------------------------------------------------
include("cooler.jl")

export CoolerType, ONAN, ONAF
export PaperInsulationType, NormalPaper, ThermallyUpgradedPaper

# ---------------------------------------------------------------------------
# Component enums and transformer kind types (depends on nothing above)
# ---------------------------------------------------------------------------
include("components.jl")

export BushingConfig, SingleBushing, DoubleBushing, TriangleBushing
export TransformerSide, Primary, Secondary
export VectorConfig, StarVector, TriangleInsideVector, TriangleOutsideVector
export TransformerKind, PowerTransformer, DistributionTransformer, ThreeWindingTransformer

# ---------------------------------------------------------------------------
# Default parameter sets and default_spec dispatch
# (depends on types.jl, cooler.jl, components.jl)
# ---------------------------------------------------------------------------
include("transformer.jl")

export default_spec
export spec

# ---------------------------------------------------------------------------
# Spec types and accessors
# ---------------------------------------------------------------------------
export InitialState, ColdStart, InitialTopOil, InitialLoad
export OilSpec
export WindingSpec
export DefaultTransformerSpec, DefaultThreeWindingSpec
export TransformerSpec, ThreeWindingSpec
export AbstractTransformerSpec
export oil, Δθ_amb, τ_oil, Δθ_or, k₁₁, k₂₁, k₂₂, x, y, Δθ_end
export windings

# ---------------------------------------------------------------------------
# Thermal model simulation
# ---------------------------------------------------------------------------
include("model.jl")

export thermal_system, initial_conditions
export Input  # re-export for user convenience

end
