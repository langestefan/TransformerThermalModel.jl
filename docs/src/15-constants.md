# Symbols and Abbreviations

This page lists the symbols and abbreviations used in this package, following
**IEC 60076-7** (thermal modelling of power transformers) and **IEEE C57.91**
(loading guide for mineral-oil-immersed transformers) notation.

Where the Julia identifier differs from the standard symbol the difference is
noted in the *Code name* column.

---

## Temperatures

| Symbol | Code name | Unit | Description |
|--------|-----------|------|-------------|
| θ_amb | — | °C | Ambient (surrounding) temperature |
| θ_oil (θ_o) | — | °C | Top-oil temperature |
| θ_hs | — | °C | Hot-spot (winding) temperature |
| θ_boil | — | °C | Boiling point of the insulating oil |
| K | `K` | p.u. | Load factor (ratio of actual to rated current, K = I / Iᵣ) |

---

## Temperature Rises

| Symbol | Code name | Unit | Description |
|--------|-----------|------|-------------|
| Δθ_oil,r (Δθₒᵣ) | `Δθ_or` | K | Rated top-oil temperature rise above ambient |
| Δθ_oil (Δθₒ) | — | K | Instantaneous top-oil temperature rise above ambient |
| Δθ_hs,r | — | K | Rated hot-spot temperature rise above top-oil |
| Δθ_hs | — | K | Instantaneous hot-spot temperature rise above top-oil |
| Δθ_amb | `Δθ_amb` | K | Ambient temperature correction / surcharge |
| Δθ_end | `Δθ_end` | K | Steady-state end-temperature correction |

---

## Thermal Time Constants

| Symbol | Code name | Unit | Description |
|--------|-----------|------|-------------|
| τ_oil,rated (τₒ) | `τ_oil` | min | Oil thermal time constant at rated load |
| τ_wdn,rated (τ_w) | `τ_w` | min | Winding thermal time constant at rated load |

---

## Losses

| Symbol | Code name | Unit | Description |
|--------|-----------|------|-------------|
| P_o (no-load loss) | `P_fe` | W | No-load (core / iron) loss |
| P_ll (load loss) | `P_cu` | W | Total load loss at rated current |
| P_w | — | W | DC (resistive) component of the winding loss |
| P_ec | — | W | Eddy-current loss in the windings |
| P_ll_hv_lv | `P_ll_hv_lv` | W | Short-circuit loss for the HV–LV winding pair |
| P_ll_hv_mv | `P_ll_hv_mv` | W | Short-circuit loss for the HV–MV winding pair |
| P_ll_mv_lv | `P_ll_mv_lv` | W | Short-circuit loss for the MV–LV winding pair |
| P_ll_total | `P_ll_total` | W | Total load loss at rated current (all windings combined) |

> **Note — naming convention.**  IEC 60076-7 uses *P_o* for no-load loss and
> *P_ll* for load loss.  The code uses `P_fe` (iron loss) and `P_cu` (copper
> loss) instead, which are equally common in the power-systems literature.

---

## IEC Thermal-Model Constants

These appear in the IEC 60076-7 differential equations for top-oil and
hot-spot temperature rise.

| Symbol | Code name | Description |
|--------|-----------|-------------|
| k₁₁ | `k₁₁` | Oil thermal-model constant (time-constant correction factor) |
| k₂₁ | `k₂₁` | Winding thermal-model constant (initial, undershoot factor) |
| k₂₂ | `k₂₂` | Winding thermal-model constant (final, overshoot factor) |
| x | `x` (field) / `x_oil` (default) | Oil viscosity / loss exponent |
| y | `y` (field) / `y_wdg` (default) | Winding temperature-gradient exponent |

---

## Winding and Rated Parameters

| Symbol | Code name | Unit | Description |
|--------|-----------|------|-------------|
| Iᵣ (I_rated) | `I_r` | A | Rated current of the winding |
| Sᵣ (S_rated) | `S_r` | MVA | Rated apparent power of the winding |
| gᵣ | `g_r` | K | Rated winding-to-oil temperature gradient |
| H | `H` | — | Hot-spot factor (ratio of winding hot-spot gradient to mean gradient) |

---

## Abbreviations

| Abbreviation | Meaning |
|--------------|---------|
| ONAN | Oil Natural Air Natural (natural convection, no fans) |
| ONAF | Oil Natural Air Forced (natural oil circulation, forced-air cooling) |
| OFAN | Oil Forced Air Natural (forced oil circulation, natural-air cooling) |
| OFAF | Oil Forced Air Forced (forced oil circulation, forced-air cooling) |
| ODAF | Oil Directed Air Forced (directed forced oil, forced-air cooling) |
| IEC | International Electrotechnical Commission |
| IEEE | Institute of Electrical and Electronics Engineers |
| LV | Low Voltage winding |
| MV | Medium Voltage winding |
| HV | High Voltage winding |
| MVA | Megavolt-Ampere |
| p.u. | Per unit (normalised to rated value) |
