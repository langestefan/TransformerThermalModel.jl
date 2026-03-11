# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

# ---------------------------------------------------------------------------
# Default parameter sets (IEC 60076-7 / empirical)
# ---------------------------------------------------------------------------

const _SHARED_POWER_DEFAULTS = (
    Δθ_or = 60.0,
    g_r = 17.0,
    H = 1.3,
    k₁₁ = 0.5,
    k₂₁ = 2.0,
    k₂₂ = 2.0,
    x_oil = 0.8,
    y_wdg = 1.3,
    Δθ_end = 0.0,
    Δθ_amb = 0.0,
)

const _POWER_ONAN_DEFAULTS = merge(_SHARED_POWER_DEFAULTS, (τ_oil = 210.0, τ_w = 10.0))
const _POWER_ONAF_DEFAULTS = merge(_SHARED_POWER_DEFAULTS, (τ_oil = 150.0, τ_w = 7.0))

const _DISTRIBUTION_DEFAULTS = (
    τ_oil = 180.0,
    τ_w = 4.0,
    Δθ_or = 60.0,
    g_r = 23.0,
    H = 1.2,
    k₁₁ = 1.0,
    k₂₁ = 1.0,
    k₂₂ = 2.0,
    x_oil = 0.8,
    y_wdg = 1.6,
    Δθ_end = 0.0,
    Δθ_amb = 10.0,  # indoor installation surcharge
)

const _SHARED_THREE_WINDING_DEFAULTS = (
    Δθ_or = 60.0,
    k₁₁ = 0.5,
    k₂₁ = 2.0,
    k₂₂ = 2.0,
    x_oil = 0.8,
    y_wdg = 1.3,
    Δθ_end = 0.0,
    Δθ_amb = 0.0,
)

const _THREE_WINDING_ONAN_DEFAULTS = merge(_SHARED_THREE_WINDING_DEFAULTS, (τ_oil = 210.0,))
const _THREE_WINDING_ONAF_DEFAULTS = merge(_SHARED_THREE_WINDING_DEFAULTS, (τ_oil = 150.0,))

# ---------------------------------------------------------------------------
# ThermalOverrides — optional per-field parameter overrides
# ---------------------------------------------------------------------------

"""
Optional thermal parameter overrides for a transformer.

All fields default to `nothing` (use the cooler-appropriate IEC default).
Supply a `Float64` value to override that specific parameter.
"""
struct ThermalOverrides
    τ_oil::Union{Float64,Nothing}
    τ_w::Union{Float64,Nothing}
    Δθ_or::Union{Float64,Nothing}
    g_r::Union{Float64,Nothing}
    H::Union{Float64,Nothing}
    k₁₁::Union{Float64,Nothing}
    k₂₁::Union{Float64,Nothing}
    k₂₂::Union{Float64,Nothing}
    x_oil::Union{Float64,Nothing}
    y_wdg::Union{Float64,Nothing}
    Δθ_end::Union{Float64,Nothing}
    Δθ_amb::Union{Float64,Nothing}
end

function ThermalOverrides(;
    τ_oil = nothing,
    τ_w = nothing,
    Δθ_or = nothing,
    g_r = nothing,
    H = nothing,
    k₁₁ = nothing,
    k₂₁ = nothing,
    k₂₂ = nothing,
    x_oil = nothing,
    y_wdg = nothing,
    Δθ_end = nothing,
    Δθ_amb = nothing,
)
    return ThermalOverrides(
        τ_oil,
        τ_w,
        Δθ_or,
        g_r,
        H,
        k₁₁,
        k₂₁,
        k₂₂,
        x_oil,
        y_wdg,
        Δθ_end,
        Δθ_amb,
    )
end

# ---------------------------------------------------------------------------
# Parameter structs
# ---------------------------------------------------------------------------

"""
Parameters for a two-winding power transformer.

# Fields
- `no_load_loss`: Iron/core loss [W]
- `load_loss`: Copper/short-circuit loss at rated load [W]
- `nom_load`: Nominal current, secondary side [A]
- `cooler`: [`CoolerType`](@ref) — `ONAN` (default) or `ONAF`
- `overrides`: Optional [`ThermalOverrides`](@ref) to deviate from IEC defaults
"""
@kwdef struct PowerTransformerParams
    no_load_loss::Float64
    load_loss::Float64
    nom_load::Float64
    cooler::CoolerType = ONAN
    overrides::ThermalOverrides = ThermalOverrides()
end

"""
Parameters for a distribution transformer.

# Fields
- `no_load_loss`: Iron/core loss [W]
- `load_loss`: Copper/short-circuit loss at rated load [W]
- `nom_load`: Nominal current, secondary side [A]
- `overrides`: Optional [`ThermalOverrides`](@ref) to deviate from IEC defaults
"""
@kwdef struct DistributionTransformerParams
    no_load_loss::Float64
    load_loss::Float64
    nom_load::Float64
    overrides::ThermalOverrides = ThermalOverrides()
end

"""
Parameters for a three-winding transformer.

# Fields
- `no_load_loss`: Iron/core loss [W]
- `lv_winding`, `mv_winding`, `hv_winding`: Per-winding [`WindingSpec`](@ref)
- `load_loss_hv_lv`: Load loss between HV and LV windings [W]
- `load_loss_hv_mv`: Load loss between HV and MV windings [W]
- `load_loss_mv_lv`: Load loss between MV and LV windings [W]
- `cooler`: [`CoolerType`](@ref) — `ONAN` (default) or `ONAF`
- `load_loss_total`: Override total load loss [W]; derived from pairwise losses if `nothing`
- `overrides`: Optional [`ThermalOverrides`](@ref) to deviate from IEC defaults
"""
@kwdef struct ThreeWindingTransformerParams
    no_load_loss::Float64
    lv_winding::WindingSpec
    mv_winding::WindingSpec
    hv_winding::WindingSpec
    load_loss_hv_lv::Float64
    load_loss_hv_mv::Float64
    load_loss_mv_lv::Float64
    cooler::CoolerType = ONAN
    load_loss_total::Union{Float64,Nothing} = nothing
    overrides::ThermalOverrides = ThermalOverrides()
end

# ---------------------------------------------------------------------------
# Constructor functions
# ---------------------------------------------------------------------------

function _build_spec(no_load_loss, load_loss, nom_load, add_surcharge_to_ambient, ov, d)
    return TransformerSpec(
        no_load_loss = no_load_loss,
        load_loss = load_loss,
        nom_load = nom_load,
        add_surcharge_to_ambient = add_surcharge_to_ambient,
        τ_oil = something(ov.τ_oil, d.τ_oil),
        τ_w = something(ov.τ_w, d.τ_w),
        Δθ_or = something(ov.Δθ_or, d.Δθ_or),
        g_r = something(ov.g_r, d.g_r),
        H = something(ov.H, d.H),
        k₁₁ = something(ov.k₁₁, d.k₁₁),
        k₂₁ = something(ov.k₂₁, d.k₂₁),
        k₂₂ = something(ov.k₂₂, d.k₂₂),
        x_oil = something(ov.x_oil, d.x_oil),
        y_wdg = something(ov.y_wdg, d.y_wdg),
        Δθ_end = something(ov.Δθ_end, d.Δθ_end),
        Δθ_amb = something(ov.Δθ_amb, d.Δθ_amb),
    )
end

"""
    PowerTransformer(params::PowerTransformerParams) -> TransformerSpec

Construct a [`TransformerSpec`](@ref) for a two-winding power transformer.

Unspecified parameters fall back to IEC 60076-7 defaults for the chosen cooling type.
The ambient temperature surcharge is applied as a fixed offset (does not scale with load).

# Example
```julia
params = PowerTransformerParams(no_load_loss=200.0, load_loss=1000.0, nom_load=1500.0)
spec = PowerTransformer(params)

# With partial overrides:
params = PowerTransformerParams(
    no_load_loss=200.0, load_loss=1000.0, nom_load=1500.0,
    overrides=ThermalOverrides(τ_oil=180.0),
)
spec = PowerTransformer(params)
```
"""
function PowerTransformer(params::PowerTransformerParams)
    d = params.cooler == ONAN ? _POWER_ONAN_DEFAULTS : _POWER_ONAF_DEFAULTS
    return _build_spec(
        params.no_load_loss,
        params.load_loss,
        params.nom_load,
        true,
        params.overrides,
        d,
    )
end

"""
    DistributionTransformer(params::DistributionTransformerParams) -> TransformerSpec

Construct a [`TransformerSpec`](@ref) for a distribution transformer.

Unspecified parameters fall back to IEC 60076-7 distribution transformer defaults.
The ambient temperature surcharge scales with load (included in the top-oil rise pre-factor).

# Example
```julia
params = DistributionTransformerParams(no_load_loss=800.0, load_loss=5200.0, nom_load=900.0)
spec = DistributionTransformer(params)
```
"""
function DistributionTransformer(params::DistributionTransformerParams)
    return _build_spec(
        params.no_load_loss,
        params.load_loss,
        params.nom_load,
        false,
        params.overrides,
        _DISTRIBUTION_DEFAULTS,
    )
end

"""
    ThreeWindingTransformer(params::ThreeWindingTransformerParams) -> ThreeWindingTransformerSpec

Construct a [`ThreeWindingTransformerSpec`](@ref) for a three-winding transformer.

# Example
```julia
w = WindingSpec(nom_load=1000.0, nom_power=10.0, g_r=17.0, τ_w=10.0, H=1.3)
params = ThreeWindingTransformerParams(
    no_load_loss=20.0,
    lv_winding=w, mv_winding=w, hv_winding=w,
    load_loss_hv_lv=100.0, load_loss_hv_mv=100.0, load_loss_mv_lv=100.0,
)
spec = ThreeWindingTransformer(params)
```
"""
function ThreeWindingTransformer(params::ThreeWindingTransformerParams)
    d = params.cooler == ONAN ? _THREE_WINDING_ONAN_DEFAULTS : _THREE_WINDING_ONAF_DEFAULTS
    ov = params.overrides
    return ThreeWindingTransformerSpec(
        no_load_loss = params.no_load_loss,
        Δθ_amb = something(ov.Δθ_amb, d.Δθ_amb),
        τ_oil = something(ov.τ_oil, d.τ_oil),
        Δθ_or = something(ov.Δθ_or, d.Δθ_or),
        k₁₁ = something(ov.k₁₁, d.k₁₁),
        k₂₁ = something(ov.k₂₁, d.k₂₁),
        k₂₂ = something(ov.k₂₂, d.k₂₂),
        x_oil = something(ov.x_oil, d.x_oil),
        y_wdg = something(ov.y_wdg, d.y_wdg),
        Δθ_end = something(ov.Δθ_end, d.Δθ_end),
        lv_winding = params.lv_winding,
        mv_winding = params.mv_winding,
        hv_winding = params.hv_winding,
        load_loss_hv_lv = params.load_loss_hv_lv,
        load_loss_hv_mv = params.load_loss_hv_mv,
        load_loss_mv_lv = params.load_loss_mv_lv,
        load_loss_total = params.load_loss_total,
    )
end
