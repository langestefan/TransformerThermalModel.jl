# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

module TransformerThermalModel

using Dates

include("cooler.jl")
include("types.jl")
include("transformer.jl")

export CoolerType, ONAN, ONAF
export PaperInsulationType, NormalPaper, ThermallyUpgradedPaper

export InitialState, ColdStart, InitialTopOilTemp, InitialLoad

export TransformerSpec, WindingSpec, ThreeWindingTransformerSpec
export InputProfile, ThreeWindingInputProfile
export ThermalResult, ThreeWindingThermalResult

export PowerTransformer, DistributionTransformer, ThreeWindingTransformer

end
