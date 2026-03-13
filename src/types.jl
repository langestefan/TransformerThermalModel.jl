# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
# SPDX-License-Identifier: MPL-2.0

# ---------------------------------------------------------------------------
# Abstract types
# ---------------------------------------------------------------------------

abstract type InitialState end
abstract type AbstractTransformerSpec end

# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------

"""Initialise the simulation from cold — all temperatures equal to ambient."""
struct ColdStart <: InitialState end

"""Initialise the simulation from a known top-oil temperature `θ_oil` [°C]."""
struct InitialTopOil <: InitialState
    θ_oil::Float64
end

"""
Initialise the simulation at the steady-state temperatures corresponding to a
constant load factor `K` [p.u.].
"""
struct InitialLoad <: InitialState
    K::Float64
end

# ---------------------------------------------------------------------------
# Shared oil/thermal parameters (composition target)
# ---------------------------------------------------------------------------

"""
IEC 60076-7 oil and thermal-model parameters shared by all transformer types.

| Symbol  | Quantity                                       | Unit |
|---------|------------------------------------------------|------|
| `Δθ_amb`| Ambient temperature surcharge                  | K    |
| `τ_oil` | Oil thermal time constant τₒ                   | min  |
| `Δθ_or` | Rated top-oil temperature rise Δθₒᵣ            | K    |
| `k₁₁`   | IEC oil thermal model constant                 | —    |
| `k₂₁`   | IEC winding thermal model constant             | —    |
| `k₂₂`   | IEC winding thermal model constant             | —    |
| `x`     | Oil viscosity exponent                         | —    |
| `y`     | Winding gradient exponent                      | —    |
| `Δθ_end`| Reduction applied to the steady-state end temp | K    |
"""
@kwdef struct OilSpec
    Δθ_amb::Float64
    τ_oil::Float64
    Δθ_or::Float64
    k₁₁::Float64
    k₂₁::Float64
    k₂₂::Float64
    x::Float64
    y::Float64
    Δθ_end::Float64
end

# Accessors on the abstract type — delegate to the embedded OilSpec.
# Concrete subtypes satisfy this interface by having an `oil` field.
oil(s::AbstractTransformerSpec) = s.oil
Δθ_amb(s::AbstractTransformerSpec) = s.oil.Δθ_amb
τ_oil(s::AbstractTransformerSpec) = s.oil.τ_oil
Δθ_or(s::AbstractTransformerSpec) = s.oil.Δθ_or
k₁₁(s::AbstractTransformerSpec) = s.oil.k₁₁
k₂₁(s::AbstractTransformerSpec) = s.oil.k₂₁
k₂₂(s::AbstractTransformerSpec) = s.oil.k₂₂
x(s::AbstractTransformerSpec) = s.oil.x
y(s::AbstractTransformerSpec) = s.oil.y
Δθ_end(s::AbstractTransformerSpec) = s.oil.Δθ_end

# ---------------------------------------------------------------------------
# Winding specification
# ---------------------------------------------------------------------------

"""
Thermal specification for a single winding (IEC 60076-7).

| Symbol | Quantity                          | Unit |
|--------|-----------------------------------|------|
| `I_r`  | Rated current                     | A    |
| `S_r`  | Rated apparent power              | MVA  |
| `g_r`  | Rated winding-to-oil gradient gᵣ  | K    |
| `τ_w`  | Winding thermal time constant τ_w | min  |
| `H`    | Hot-spot factor H                 | —    |
"""
@kwdef struct WindingSpec
    I_r::Float64
    S_r::Float64
    g_r::Float64
    τ_w::Float64
    H::Float64
end

# ---------------------------------------------------------------------------
# Default specifications
# ---------------------------------------------------------------------------

"""
Catalogue defaults for a two-winding transformer. Fields mirror the optional
thermal parameters of [`TransformerSpec`](@ref) and [`OilSpec`](@ref); see
those types for symbol definitions.
"""
@kwdef struct DefaultTransformerSpec
    oil::OilSpec
    g_r::Float64
    τ_w::Float64
    H::Float64
end

"""
Catalogue defaults for a three-winding transformer. Top-level oil parameters
are grouped in `oil`; per-winding defaults are nested as [`WindingSpec`](@ref)
values under `lv`, `mv`, and `hv` (with `I_r = 0` and `S_r = 0` as sentinels
since those are always supplied by the user).
"""
@kwdef struct DefaultThreeWindingSpec
    oil::OilSpec
    lv::WindingSpec
    mv::WindingSpec
    hv::WindingSpec
end

# ---------------------------------------------------------------------------
# Concrete transformer specifications
# ---------------------------------------------------------------------------

"""
Fully resolved thermal specification for a two-winding transformer (IEC 60076-7).

| Symbol      | Quantity                                        | Unit |
|-------------|-------------------------------------------------|------|
| `P_fe`      | No-load (iron/core) loss                        | W    |
| `P_cu`      | Load (copper/short-circuit) loss at rated load  | W    |
| `I_r`       | Rated current, secondary side                   | A    |
| `scale_amb` | `true`: `Δθ_amb` is a fixed offset added to     |      |
|             | ambient (power transformer). `false`: folded    |      |
|             | into the top-oil rise pre-factor, scales with   |      |
|             | load (distribution transformer).                |      |
| `g_r`       | Rated winding-to-oil temperature gradient gᵣ    | K    |
| `τ_w`       | Winding thermal time constant τ_w               | min  |
| `H`         | Hot-spot factor H                               | —    |
| `oil`       | Shared oil and thermal-model parameters         |      |
"""
@kwdef struct TransformerSpec <: AbstractTransformerSpec
    P_fe::Float64
    P_cu::Float64
    I_r::Float64
    scale_amb::Bool
    g_r::Float64
    τ_w::Float64
    H::Float64
    oil::OilSpec
end

"""
    TransformerSpec(P_fe, P_cu, I_r, scale_amb, d; kwargs...)

Construct a [`TransformerSpec`](@ref) from type-plate measurements and a
[`DefaultTransformerSpec`](@ref). Any field can be overridden via keyword
arguments; fields not supplied take their value from `d`.
"""
function TransformerSpec(
    P_fe::Float64,
    P_cu::Float64,
    I_r::Float64,
    scale_amb::Bool,
    d::DefaultTransformerSpec;
    kwargs...,
)
    TransformerSpec(; P_fe, P_cu, I_r, scale_amb, g_r = d.g_r, τ_w = d.τ_w, H = d.H, oil = d.oil, kwargs...)
end

"""
Fully resolved thermal specification for a three-winding transformer (IEC 60076-7).

Top-oil dynamics are governed by the shared `oil` parameters. Each winding carries
its own hot-spot parameters. `P_ll_total` is either supplied directly or computed
from the pairwise losses via the IEC star-circuit decomposition: the transformer is
represented as three series impedances meeting at a fictitious internal node, and
the individual winding losses are recovered by solving that circuit.

| Symbol         | Quantity                                       | Unit |
|----------------|------------------------------------------------|------|
| `P_fe`         | No-load (iron/core) loss                       | W    |
| `lv`,`mv`,`hv` | Per-winding thermal specifications             |      |
| `P_ll_hv_lv`   | Short-circuit loss, HV–LV winding pair         | W    |
| `P_ll_hv_mv`   | Short-circuit loss, HV–MV winding pair         | W    |
| `P_ll_mv_lv`   | Short-circuit loss, MV–LV winding pair         | W    |
| `P_ll_total`   | Total load loss at rated current               | W    |
| `oil`          | Shared oil and thermal-model parameters        |      |
"""
@kwdef struct ThreeWindingSpec <: AbstractTransformerSpec
    P_fe::Float64
    lv::WindingSpec
    mv::WindingSpec
    hv::WindingSpec
    P_ll_hv_lv::Float64
    P_ll_hv_mv::Float64
    P_ll_mv_lv::Float64
    P_ll_total::Float64
    oil::OilSpec
end

"""
    ThreeWindingSpec(P_fe, lv, mv, hv, P_ll_hv_lv, P_ll_hv_mv, P_ll_mv_lv, d;
                     P_ll_total=nothing, kwargs...)

Construct a [`ThreeWindingSpec`](@ref) from type-plate measurements and a
[`DefaultThreeWindingSpec`](@ref). Any field can be overridden via keyword
arguments. When `P_ll_total` is not supplied it is derived from the three
pairwise short-circuit losses using the IEC star-circuit decomposition.
"""
function ThreeWindingSpec(
    P_fe::Float64,
    lv::WindingSpec,
    mv::WindingSpec,
    hv::WindingSpec,
    P_ll_hv_lv::Float64,
    P_ll_hv_mv::Float64,
    P_ll_mv_lv::Float64,
    d::DefaultThreeWindingSpec;
    P_ll_total = nothing,
    kwargs...,
)
    c₁ = (mv.S_r / hv.S_r)^2
    c₂ = (lv.S_r / mv.S_r)^2

    P_ll_hc = (0.5 / c₁) * (P_ll_hv_mv - (1 / c₂) * P_ll_mv_lv + (1 / c₂) * P_ll_hv_lv)
    P_ll_mc = (0.5 / c₂) * (c₂ * P_ll_hv_mv - P_ll_hv_lv + P_ll_mv_lv)
    P_ll_lc = 0.5 * (P_ll_hv_lv - c₂ * P_ll_hv_mv + P_ll_mv_lv)

    resolved_total = isnothing(P_ll_total) ? P_ll_hc + P_ll_mc + P_ll_lc + P_fe : P_ll_total

    ThreeWindingSpec(;
        P_fe,
        lv,
        mv,
        hv,
        P_ll_hv_lv,
        P_ll_hv_mv,
        P_ll_mv_lv,
        P_ll_total = resolved_total,
        oil = d.oil,
        kwargs...,
    )
end

# ---------------------------------------------------------------------------
# Winding accessor
# ---------------------------------------------------------------------------

"""
Return the windings as a tuple of [`WindingSpec`](@ref) values.
Use `getfield.(windings(s), :g_r)` etc. to extract any field uniformly across
transformer types.
"""
windings(s::ThreeWindingSpec) = (s.lv, s.mv, s.hv)