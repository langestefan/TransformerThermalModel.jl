module TransformerThermalModel

using Dates

include("transformer.jl")
include("model.jl")

# ---------------------------------------------------------------------------
# Top level types
# ---------------------------------------------------------------------------
include("types.jl")

# ---------------------------------------------------------------------------
# Cooler and insulation types
# ---------------------------------------------------------------------------
include("cooler.jl")

export CoolerType, ONAN, ONAF
export PaperInsulationType, NormalPaper, ThermallyUpgradedPaper


end
