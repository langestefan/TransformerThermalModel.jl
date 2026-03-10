# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

# ---------------------------------------------------------------------------
# Default parameter sets (IEC 60076-7 / empirical)
# ---------------------------------------------------------------------------

const _POWER_ONAN_DEFAULTS = (
    τ_oil=210.0,
    τ_w=10.0,
    Δθ_or=60.0,
    g_r=17.0,
    H=1.3,
    k₁₁=0.5,
    k₂₁=2.0,
    k₂₂=2.0,
    x=0.8,
    y=1.3,
    end_temp_reduction=0.0,
    amb_temp_surcharge=0.0,
)

const _POWER_ONAF_DEFAULTS = (
    τ_oil=150.0,
    τ_w=7.0,
    Δθ_or=60.0,
    g_r=17.0,
    H=1.3,
    k₁₁=0.5,
    k₂₁=2.0,
    k₂₂=2.0,
    x=0.8,
    y=1.3,
    end_temp_reduction=0.0,
    amb_temp_surcharge=0.0,
)

const _DISTRIBUTION_DEFAULTS = (
    τ_oil=180.0,
    τ_w=4.0,
    Δθ_or=60.0,
    g_r=23.0,
    H=1.2,
    k₁₁=1.0,
    k₂₁=1.0,
    k₂₂=2.0,
    x=0.8,
    y=1.6,
    end_temp_reduction=0.0,
    amb_temp_surcharge=10.0,  # indoor installation surcharge
)

const _THREE_WINDING_ONAN_DEFAULTS = (
    τ_oil=210.0,
    Δθ_or=60.0,
    k₁₁=0.5,
    k₂₁=2.0,
    k₂₂=2.0,
    x=0.8,
    y=1.3,
    end_temp_reduction=0.0,
    amb_temp_surcharge=0.0,
)

const _THREE_WINDING_ONAF_DEFAULTS = (
    τ_oil=150.0,
    Δθ_or=60.0,
    k₁₁=0.5,
    k₂₁=2.0,
    k₂₂=2.0,
    x=0.8,
    y=1.3,
    end_temp_reduction=0.0,
    amb_temp_surcharge=0.0,
)

# ---------------------------------------------------------------------------
# Constructors
# ---------------------------------------------------------------------------

"""
    PowerTransformer(; no_load_loss, load_loss, nom_load, cooler=ONAN, kwargs...)

Construct a [`TransformerSpec`](@ref) for a two-winding power transformer.

Unspecified parameters fall back to IEC 60076-7 defaults for the chosen cooling type.
The ambient temperature surcharge is applied as a fixed offset to the ambient temperature
(does not scale with load).

# Arguments
- `no_load_loss`: Iron/core loss [W]
- `load_loss`: Copper/short-circuit loss at rated load [W]
- `nom_load`: Nominal current, secondary side [A]
- `cooler`: [`CoolerType`](@ref) — `ONAN` (default) or `ONAF`

# Optional keyword overrides (all in IEC 60076-7 units)
`τ_oil`, `τ_w`, `Δθ_or`, `g_r`, `H`, `k₁₁`, `k₂₁`, `k₂₂`,
`x`, `y`, `end_temp_reduction`, `amb_temp_surcharge`
"""
function PowerTransformer(;
    no_load_loss::Float64,
    load_loss::Float64,
    nom_load::Float64,
    cooler::CoolerType=ONAN,
    τ_oil=nothing,
    τ_w=nothing,
    Δθ_or=nothing,
    g_r=nothing,
    H=nothing,
    k₁₁=nothing,
    k₂₁=nothing,
    k₂₂=nothing,
    x=nothing,
    y=nothing,
    end_temp_reduction=nothing,
    amb_temp_surcharge=nothing,
)
    d = cooler == ONAN ? _POWER_ONAN_DEFAULTS : _POWER_ONAF_DEFAULTS
    return TransformerSpec(
        no_load_loss=no_load_loss,
        load_loss=load_loss,
        nom_load=nom_load,
        add_surcharge_to_ambient=true,
        τ_oil=something(τ_oil, d.τ_oil),
        τ_w=something(τ_w, d.τ_w),
        Δθ_or=something(Δθ_or, d.Δθ_or),
        g_r=something(g_r, d.g_r),
        H=something(H, d.H),
        k₁₁=something(k₁₁, d.k₁₁),
        k₂₁=something(k₂₁, d.k₂₁),
        k₂₂=something(k₂₂, d.k₂₂),
        x=something(x, d.x),
        y=something(y, d.y),
        end_temp_reduction=something(end_temp_reduction, d.end_temp_reduction),
        amb_temp_surcharge=something(amb_temp_surcharge, d.amb_temp_surcharge),
    )
end

"""
    DistributionTransformer(; no_load_loss, load_loss, nom_load, kwargs...)

Construct a [`TransformerSpec`](@ref) for a distribution transformer (ONAN only).

Distribution transformers default to a 10 K ambient temperature surcharge, accounting
for indoor installation. The surcharge is folded into the top-oil rise pre-factor and
therefore scales with load (unlike power transformers where it is a fixed offset).

# Arguments
- `no_load_loss`: Iron/core loss [W]
- `load_loss`: Copper/short-circuit loss at rated load [W]
- `nom_load`: Nominal current, secondary side [A]

# Optional keyword overrides (all in IEC 60076-7 units)
Same as [`PowerTransformer`](@ref), excluding `cooler`.
"""
function DistributionTransformer(;
    no_load_loss::Float64,
    load_loss::Float64,
    nom_load::Float64,
    τ_oil=nothing,
    τ_w=nothing,
    Δθ_or=nothing,
    g_r=nothing,
    H=nothing,
    k₁₁=nothing,
    k₂₁=nothing,
    k₂₂=nothing,
    x=nothing,
    y=nothing,
    end_temp_reduction=nothing,
    amb_temp_surcharge=nothing,
)
    d = _DISTRIBUTION_DEFAULTS
    return TransformerSpec(
        no_load_loss=no_load_loss,
        load_loss=load_loss,
        nom_load=nom_load,
        add_surcharge_to_ambient=false,
        τ_oil=something(τ_oil, d.τ_oil),
        τ_w=something(τ_w, d.τ_w),
        Δθ_or=something(Δθ_or, d.Δθ_or),
        g_r=something(g_r, d.g_r),
        H=something(H, d.H),
        k₁₁=something(k₁₁, d.k₁₁),
        k₂₁=something(k₂₁, d.k₂₁),
        k₂₂=something(k₂₂, d.k₂₂),
        x=something(x, d.x),
        y=something(y, d.y),
        end_temp_reduction=something(end_temp_reduction, d.end_temp_reduction),
        amb_temp_surcharge=something(amb_temp_surcharge, d.amb_temp_surcharge),
    )
end

"""
    ThreeWindingTransformer(; no_load_loss, lv_winding, mv_winding, hv_winding,
                              load_loss_hv_lv, load_loss_hv_mv, load_loss_mv_lv,
                              cooler=ONAN, kwargs...)

Construct a [`ThreeWindingTransformerSpec`](@ref) for a three-winding transformer.

Each winding is specified via a [`WindingSpec`](@ref).

# Arguments
- `no_load_loss`: Iron/core loss [W]
- `lv_winding`, `mv_winding`, `hv_winding`: [`WindingSpec`](@ref) for each winding
- `load_loss_hv_lv`: Load loss between HV and LV windings [W]
- `load_loss_hv_mv`: Load loss between HV and MV windings [W]
- `load_loss_mv_lv`: Load loss between MV and LV windings [W]
- `cooler`: [`CoolerType`](@ref) — `ONAN` (default) or `ONAF`
- `load_loss_total`: Override total load loss [W]; computed from pairwise losses if `nothing`

# Optional keyword overrides for shared oil parameters
`amb_temp_surcharge`, `τ_oil`, `Δθ_or`, `k₁₁`, `k₂₁`, `k₂₂`, `x`, `y`, `end_temp_reduction`
"""
function ThreeWindingTransformer(;
    no_load_loss::Float64,
    lv_winding::WindingSpec,
    mv_winding::WindingSpec,
    hv_winding::WindingSpec,
    load_loss_hv_lv::Float64,
    load_loss_hv_mv::Float64,
    load_loss_mv_lv::Float64,
    cooler::CoolerType=ONAN,
    load_loss_total=nothing,
    amb_temp_surcharge=nothing,
    τ_oil=nothing,
    Δθ_or=nothing,
    k₁₁=nothing,
    k₂₁=nothing,
    k₂₂=nothing,
    x=nothing,
    y=nothing,
    end_temp_reduction=nothing,
)
    d = cooler == ONAN ? _THREE_WINDING_ONAN_DEFAULTS : _THREE_WINDING_ONAF_DEFAULTS
    return ThreeWindingTransformerSpec(
        no_load_loss=no_load_loss,
        amb_temp_surcharge=something(amb_temp_surcharge, d.amb_temp_surcharge),
        τ_oil=something(τ_oil, d.τ_oil),
        Δθ_or=something(Δθ_or, d.Δθ_or),
        k₁₁=something(k₁₁, d.k₁₁),
        k₂₁=something(k₂₁, d.k₂₁),
        k₂₂=something(k₂₂, d.k₂₂),
        x=something(x, d.x),
        y=something(y, d.y),
        end_temp_reduction=something(end_temp_reduction, d.end_temp_reduction),
        lv_winding=lv_winding,
        mv_winding=mv_winding,
        hv_winding=hv_winding,
        load_loss_hv_lv=load_loss_hv_lv,
        load_loss_hv_mv=load_loss_hv_mv,
        load_loss_mv_lv=load_loss_mv_lv,
        load_loss_total=load_loss_total,
    )
end
