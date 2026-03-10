# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

using Dates

# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------

"""Abstract base for transformer initial thermal state."""
abstract type InitialState end

"""Start the simulation from cold (ambient temperature)."""
struct ColdStart <: InitialState end

"""Start with a known top-oil temperature [°C]."""
struct InitialTopOilTemp <: InitialState
    temp::Float64
end

"""Start at the steady-state temperatures for a given initial load [p.u.]."""
struct InitialLoad <: InitialState
    load::Float64
end

# ---------------------------------------------------------------------------
# Transformer specifications
# ---------------------------------------------------------------------------

"""
Full resolved specification for a single-winding (power or distribution) transformer.

All thermal parameters follow IEC 60076-7 notation.

# Fields
- `no_load_loss`: Iron/core loss [W]
- `load_loss`: Copper/short-circuit loss at rated load [W]
- `nom_load`: Nominal current, secondary side [A]
- `amb_temp_surcharge`: Constant temperature offset to account for enclosure or
  environment [K]
- `add_surcharge_to_ambient`: If `true` (power transformer), the surcharge is added
  to the ambient temperature as a fixed offset. If `false` (distribution transformer),
  the surcharge is included in the top-oil rise pre-factor and scales with load.
- `τ_oil`: Oil thermal time constant τₒ [min]
- `Δθ_or`: Rated top-oil temperature rise Δθₒᵣ [K]
- `k₁₁`: IEC oil constant k₁₁ [-]
- `k₂₁`: IEC winding constant k₂₁ [-]
- `k₂₂`: IEC winding constant k₂₂ [-]
- `x`: Oil exponent x [-]
- `y`: Winding exponent y [-]
- `end_temp_reduction`: Reduction applied to the steady-state end temperature [K]
- `g_r`: Winding-to-oil temperature gradient gᵣ [K]
- `τ_w`: Winding thermal time constant τ_w [min]
- `H`: Hot-spot factor H [-]
"""
@kwdef struct TransformerSpec
    no_load_loss::Float64
    load_loss::Float64
    nom_load::Float64
    amb_temp_surcharge::Float64
    add_surcharge_to_ambient::Bool
    τ_oil::Float64
    Δθ_or::Float64
    k₁₁::Float64
    k₂₁::Float64
    k₂₂::Float64
    x::Float64
    y::Float64
    end_temp_reduction::Float64
    g_r::Float64
    τ_w::Float64
    H::Float64
end

"""
Specification for a single winding in a three-winding transformer.

# Fields
- `nom_load`: Nominal current [A]
- `nom_power`: Nominal apparent power [MVA]
- `g_r`: Winding-to-oil temperature gradient gᵣ [K]
- `τ_w`: Winding thermal time constant τ_w [min]
- `H`: Hot-spot factor H [-]
"""
@kwdef struct WindingSpec
    nom_load::Float64
    nom_power::Float64
    g_r::Float64
    τ_w::Float64
    H::Float64
end

"""
Full resolved specification for a three-winding transformer.

The top-oil temperature is governed by shared oil parameters. Each winding has its
own hot-spot parameters. The total load loss is either user-supplied or derived from
pairwise losses using the IEC star-circuit decomposition.

# Fields
- `no_load_loss`: Iron/core loss [W]
- `amb_temp_surcharge`: Constant temperature surcharge [K]
- `τ_oil`: Oil thermal time constant τₒ [min]
- `Δθ_or`: Rated top-oil temperature rise Δθₒᵣ [K]
- `k₁₁`: IEC oil constant k₁₁ [-]
- `k₂₁`: IEC winding constant k₂₁ [-]
- `k₂₂`: IEC winding constant k₂₂ [-]
- `x`: Oil exponent x [-]
- `y`: Winding exponent y [-]
- `end_temp_reduction`: Reduction applied to the steady-state end temperature [K]
- `lv_winding`, `mv_winding`, `hv_winding`: Per-winding specifications
- `load_loss_hv_lv`: Load loss between HV and LV windings [W]
- `load_loss_hv_mv`: Load loss between HV and MV windings [W]
- `load_loss_mv_lv`: Load loss between MV and LV windings [W]
- `load_loss_total`: User-supplied total load loss [W], or `nothing` to compute it.
"""
@kwdef struct ThreeWindingTransformerSpec
    no_load_loss::Float64
    amb_temp_surcharge::Float64
    τ_oil::Float64
    Δθ_or::Float64
    k₁₁::Float64
    k₂₁::Float64
    k₂₂::Float64
    x::Float64
    y::Float64
    end_temp_reduction::Float64
    lv_winding::WindingSpec
    mv_winding::WindingSpec
    hv_winding::WindingSpec
    load_loss_hv_lv::Float64
    load_loss_hv_mv::Float64
    load_loss_mv_lv::Float64
    load_loss_total::Union{Float64,Nothing} = nothing
end

# ---------------------------------------------------------------------------
# Input profiles
# ---------------------------------------------------------------------------

"""
Input profile for a single-winding transformer simulation.

# Fields
- `time`: Datetime timestamps, must be strictly sorted [DateTime]
- `load`: Per-unit load profile (≥ 0) relative to nominal current [-]
- `ambient`: Ambient temperature profile [°C]
- `top_oil`: Optional measured top-oil temperature profile [°C]
"""
struct InputProfile
    time::Vector{DateTime}
    load::Vector{Float64}
    ambient::Vector{Float64}
    top_oil::Union{Vector{Float64},Nothing}

    function InputProfile(time, load, ambient, top_oil=nothing)
        time = collect(DateTime, time)
        load = collect(Float64, load)
        ambient = collect(Float64, ambient)
        n = length(time)
        length(load) == n ||
            throw(ArgumentError("load length $(length(load)) ≠ time length $n"))
        length(ambient) == n ||
            throw(ArgumentError("ambient length $(length(ambient)) ≠ time length $n"))
        issorted(time) || throw(ArgumentError("time must be sorted"))
        any(<(0), load) && throw(ArgumentError("load profile must not contain negative values"))
        if top_oil !== nothing
            top_oil = collect(Float64, top_oil)
            length(top_oil) == n ||
                throw(ArgumentError("top_oil length $(length(top_oil)) ≠ time length $n"))
        end
        return new(time, load, ambient, top_oil)
    end
end

"""
Input profile for a three-winding transformer simulation.

# Fields
- `time`: Datetime timestamps, must be strictly sorted [DateTime]
- `load_hv`: Per-unit load profile, high-voltage side (≥ 0) [-]
- `load_mv`: Per-unit load profile, medium-voltage side (≥ 0) [-]
- `load_lv`: Per-unit load profile, low-voltage side (≥ 0) [-]
- `ambient`: Ambient temperature profile [°C]
- `top_oil`: Optional measured top-oil temperature profile [°C]
"""
struct ThreeWindingInputProfile
    time::Vector{DateTime}
    load_hv::Vector{Float64}
    load_mv::Vector{Float64}
    load_lv::Vector{Float64}
    ambient::Vector{Float64}
    top_oil::Union{Vector{Float64},Nothing}

    function ThreeWindingInputProfile(time, load_hv, load_mv, load_lv, ambient, top_oil=nothing)
        time = collect(DateTime, time)
        load_hv = collect(Float64, load_hv)
        load_mv = collect(Float64, load_mv)
        load_lv = collect(Float64, load_lv)
        ambient = collect(Float64, ambient)
        n = length(time)
        for (name, v) in (
            ("load_hv", load_hv), ("load_mv", load_mv), ("load_lv", load_lv), ("ambient", ambient)
        )
            length(v) == n ||
                throw(ArgumentError("$name length $(length(v)) ≠ time length $n"))
        end
        issorted(time) || throw(ArgumentError("time must be sorted"))
        for (name, v) in (("load_hv", load_hv), ("load_mv", load_mv), ("load_lv", load_lv))
            any(<(0), v) && throw(ArgumentError("$name must not contain negative values"))
        end
        if top_oil !== nothing
            top_oil = collect(Float64, top_oil)
            length(top_oil) == n ||
                throw(ArgumentError("top_oil length $(length(top_oil)) ≠ time length $n"))
        end
        return new(time, load_hv, load_mv, load_lv, ambient, top_oil)
    end
end

# ---------------------------------------------------------------------------
# Simulation results
# ---------------------------------------------------------------------------

"""
Thermal simulation result for a single-winding transformer.

# Fields
- `time`: Datetime timestamps [DateTime]
- `top_oil`: Top-oil temperature profile [°C]
- `hot_spot`: Hot-spot temperature profile [°C]
"""
struct ThermalResult
    time::Vector{DateTime}
    top_oil::Vector{Float64}
    hot_spot::Vector{Float64}
end

"""
Thermal simulation result for a three-winding transformer.

# Fields
- `time`: Datetime timestamps [DateTime]
- `top_oil`: Top-oil temperature profile [°C]
- `hot_spot_lv`: Hot-spot temperature, low-voltage winding [°C]
- `hot_spot_mv`: Hot-spot temperature, medium-voltage winding [°C]
- `hot_spot_hv`: Hot-spot temperature, high-voltage winding [°C]
"""
struct ThreeWindingThermalResult
    time::Vector{DateTime}
    top_oil::Vector{Float64}
    hot_spot_lv::Vector{Float64}
    hot_spot_mv::Vector{Float64}
    hot_spot_hv::Vector{Float64}
end
