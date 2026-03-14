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

const _THREE_WINDING_ONAN_DEFAULTS =
    merge(_SHARED_THREE_WINDING_DEFAULTS, (τ_oil = 210.0, g_r = 17.0, H = 1.3, τ_w = 10.0))
const _THREE_WINDING_ONAF_DEFAULTS =
    merge(_SHARED_THREE_WINDING_DEFAULTS, (τ_oil = 150.0, g_r = 17.0, H = 1.3, τ_w = 7.0))

# ---------------------------------------------------------------------------
# Helpers — build spec objects from the internal named-tuple constants
# ---------------------------------------------------------------------------

function _make_oil_spec(d)
    OilSpec(
        Δθ_amb = d.Δθ_amb,
        τ_oil = d.τ_oil,
        Δθ_or = d.Δθ_or,
        k₁₁ = d.k₁₁,
        k₂₁ = d.k₂₁,
        k₂₂ = d.k₂₂,
        x = d.x_oil,
        y = d.y_wdg,
        Δθ_end = d.Δθ_end,
    )
end

function _make_sentinel_winding(d)
    WindingSpec(I_r = 0.0, S_r = 0.0, g_r = d.g_r, τ_w = d.τ_w, H = d.H)
end

# ---------------------------------------------------------------------------
# default_spec — IEC 60076-7 catalogue defaults, dispatched on cooler + kind
# ---------------------------------------------------------------------------

"""
    default_spec(T) -> DefaultTransformerSpec | DefaultThreeWindingSpec

Return the IEC 60076-7 catalogue default parameters for the given transformer
type.  The cooler type is encoded as a type parameter.  The result can be
passed to the [`TransformerSpec`](@ref) or [`ThreeWindingSpec`](@ref)
constructors as the `d` argument.

# Examples
```julia
d  = default_spec(PowerTransformer{ONAN})   # ONAN
d  = default_spec(PowerTransformer{ONAF})   # ONAF
spec = TransformerSpec(P_fe, P_cu, I_r, true, d)

d3 = default_spec(ThreeWindingTransformer{ONAF})
spec3 = ThreeWindingSpec(P_fe, lv, mv, hv, P_ll_hv_lv, P_ll_hv_mv, P_ll_mv_lv, d3)
```
"""
function default_spec(::Type{PowerTransformer{ONAN}})
    d = _POWER_ONAN_DEFAULTS
    DefaultTransformerSpec(oil = _make_oil_spec(d), g_r = d.g_r, τ_w = d.τ_w, H = d.H)
end

function default_spec(::Type{PowerTransformer{ONAF}})
    d = _POWER_ONAF_DEFAULTS
    DefaultTransformerSpec(oil = _make_oil_spec(d), g_r = d.g_r, τ_w = d.τ_w, H = d.H)
end

"""
    default_spec(::Type{DistributionTransformer}) -> DefaultTransformerSpec

Distribution transformers are always ONAN; no cooler type parameter is needed.
"""
function default_spec(::Type{DistributionTransformer})
    d = _DISTRIBUTION_DEFAULTS
    DefaultTransformerSpec(oil = _make_oil_spec(d), g_r = d.g_r, τ_w = d.τ_w, H = d.H)
end

function default_spec(::Type{ThreeWindingTransformer{ONAN}})
    d = _THREE_WINDING_ONAN_DEFAULTS
    dw = _make_sentinel_winding(d)
    DefaultThreeWindingSpec(oil = _make_oil_spec(d), lv = dw, mv = dw, hv = dw)
end

function default_spec(::Type{ThreeWindingTransformer{ONAF}})
    d = _THREE_WINDING_ONAF_DEFAULTS
    dw = _make_sentinel_winding(d)
    DefaultThreeWindingSpec(oil = _make_oil_spec(d), lv = dw, mv = dw, hv = dw)
end

# ---------------------------------------------------------------------------
# Keyword-argument outer constructors
# ---------------------------------------------------------------------------

function PowerTransformer{C}(;
    P_fe::Float64,
    P_cu::Float64,
    I_r::Float64,
    kwargs...,
) where {C<:CoolerType}
    d = default_spec(PowerTransformer{C})
    PowerTransformer{C}(TransformerSpec(P_fe, P_cu, I_r, true, d; kwargs...))
end

"""Construct a `PowerTransformer{ONAN}` (default cooler type)."""
PowerTransformer(; kwargs...) = PowerTransformer{ONAN}(; kwargs...)

function DistributionTransformer(; P_fe::Float64, P_cu::Float64, I_r::Float64, kwargs...)
    d = default_spec(DistributionTransformer)
    DistributionTransformer(TransformerSpec(P_fe, P_cu, I_r, false, d; kwargs...))
end

function ThreeWindingTransformer{C}(;
    P_fe::Float64,
    lv::WindingSpec,
    mv::WindingSpec,
    hv::WindingSpec,
    P_ll_hv_lv::Float64,
    P_ll_hv_mv::Float64,
    P_ll_mv_lv::Float64,
    kwargs...,
) where {C<:CoolerType}
    d = default_spec(ThreeWindingTransformer{C})
    ThreeWindingTransformer{C}(
        ThreeWindingSpec(
            P_fe,
            lv,
            mv,
            hv,
            P_ll_hv_lv,
            P_ll_hv_mv,
            P_ll_mv_lv,
            d;
            kwargs...,
        ),
    )
end

"""Construct a `ThreeWindingTransformer{ONAN}` (default cooler type)."""
ThreeWindingTransformer(; kwargs...) = ThreeWindingTransformer{ONAN}(; kwargs...)
