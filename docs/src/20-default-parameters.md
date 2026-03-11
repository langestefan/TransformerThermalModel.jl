# Default Parameters

Default values follow **IEC 60076-7** unless noted otherwise.
All parameters can be overridden via keyword arguments to the constructor.

---

## PowerTransformer — ONAN

Oil Natural Air Natural cooling.

| Symbol | Field | Value | Unit | Description |
|--------|-------|------:|------|-------------|
| τₒ | `τ_oil` | 210 | min | Oil thermal time constant |
| τ_w | `τ_w` | 10 | min | Winding thermal time constant |
| Δθₒᵣ | `Δθ_or` | 60 | K | Top-oil temperature rise at rated load |
| gᵣ | `g_r` | 17 | K | Winding-to-oil temperature gradient |
| H | `H` | 1.3 | — | Hot-spot factor |
| k₁₁ | `k₁₁` | 0.5 | — | Oil time constant correction factor |
| k₂₁ | `k₂₁` | 2 | — | Winding hot-spot factor (initial) |
| k₂₂ | `k₂₂` | 2 | — | Winding hot-spot factor (final) |
| x | `x_oil` | 0.8 | — | Oil viscosity exponent |
| y | `y_wdg` | 1.3 | — | Winding gradient exponent |
| Δθ_end | `Δθ_end` | 0 | K | Steady-state end temperature correction |
| Δθ_amb | `Δθ_amb` | 0 | K | Ambient temperature surcharge |

---

## PowerTransformer — ONAF

Oil Natural Air Forced cooling.

| Symbol | Field | Value | Unit | Description |
|--------|-------|------:|------|-------------|
| τₒ | `τ_oil` | 150 | min | Oil thermal time constant |
| τ_w | `τ_w` | 7 | min | Winding thermal time constant |
| Δθₒᵣ | `Δθ_or` | 60 | K | Top-oil temperature rise at rated load |
| gᵣ | `g_r` | 17 | K | Winding-to-oil temperature gradient |
| H | `H` | 1.3 | — | Hot-spot factor |
| k₁₁ | `k₁₁` | 0.5 | — | Oil time constant correction factor |
| k₂₁ | `k₂₁` | 2 | — | Winding hot-spot factor (initial) |
| k₂₂ | `k₂₂` | 2 | — | Winding hot-spot factor (final) |
| x | `x_oil` | 0.8 | — | Oil viscosity exponent |
| y | `y_wdg` | 1.3 | — | Winding gradient exponent |
| Δθ_end | `Δθ_end` | 0 | K | Steady-state end temperature correction |
| Δθ_amb | `Δθ_amb` | 0 | K | Ambient temperature surcharge |

---

## DistributionTransformer — ONAN

Distribution transformers are ONAN only. A default ambient temperature surcharge of
10 K is applied to account for indoor installation (surcharge scales with load).

| Symbol | Field | Value | Unit | Description |
|--------|-------|------:|------|-------------|
| τₒ | `τ_oil` | 180 | min | Oil thermal time constant |
| τ_w | `τ_w` | 4 | min | Winding thermal time constant |
| Δθₒᵣ | `Δθ_or` | 60 | K | Top-oil temperature rise at rated load |
| gᵣ | `g_r` | 23 | K | Winding-to-oil temperature gradient |
| H | `H` | 1.2 | — | Hot-spot factor |
| k₁₁ | `k₁₁` | 1.0 | — | Oil time constant correction factor |
| k₂₁ | `k₂₁` | 1 | — | Winding hot-spot factor (initial) |
| k₂₂ | `k₂₂` | 2 | — | Winding hot-spot factor (final) |
| x | `x_oil` | 0.8 | — | Oil viscosity exponent |
| y | `y_wdg` | 1.6 | — | Winding gradient exponent |
| Δθ_end | `Δθ_end` | 0 | K | Steady-state end temperature correction |
| Δθ_amb | `Δθ_amb` | 10 | K | Ambient temperature surcharge (indoor) |

---

## ThreeWindingTransformer — ONAN

Shared oil parameters only. Per-winding parameters (`g_r`, `τ_w`, `H`) must be
supplied explicitly in each [`WindingSpec`](@ref).

| Symbol | Field | Value | Unit | Description |
|--------|-------|------:|------|-------------|
| τₒ | `τ_oil` | 210 | min | Oil thermal time constant |
| Δθₒᵣ | `Δθ_or` | 60 | K | Top-oil temperature rise at rated load |
| k₁₁ | `k₁₁` | 0.5 | — | Oil time constant correction factor |
| k₂₁ | `k₂₁` | 2 | — | Winding hot-spot factor (initial) |
| k₂₂ | `k₂₂` | 2 | — | Winding hot-spot factor (final) |
| x | `x_oil` | 0.8 | — | Oil viscosity exponent |
| y | `y_wdg` | 1.3 | — | Winding gradient exponent |
| Δθ_end | `Δθ_end` | 0 | K | Steady-state end temperature correction |
| Δθ_amb | `Δθ_amb` | 0 | K | Ambient temperature surcharge |

---

## ThreeWindingTransformer — ONAF

| Symbol | Field | Value | Unit | Description |
|--------|-------|------:|------|-------------|
| τₒ | `τ_oil` | 150 | min | Oil thermal time constant |
| Δθₒᵣ | `Δθ_or` | 60 | K | Top-oil temperature rise at rated load |
| k₁₁ | `k₁₁` | 0.5 | — | Oil time constant correction factor |
| k₂₁ | `k₂₁` | 2 | — | Winding hot-spot factor (initial) |
| k₂₂ | `k₂₂` | 2 | — | Winding hot-spot factor (final) |
| x | `x_oil` | 0.8 | — | Oil viscosity exponent |
| y | `y_wdg` | 1.3 | — | Winding gradient exponent |
| Δθ_end | `Δθ_end` | 0 | K | Steady-state end temperature correction |
| Δθ_amb | `Δθ_amb` | 0 | K | Ambient temperature surcharge |
