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

