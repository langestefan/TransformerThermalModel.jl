"""
Demo: TransformerThermalModel data models
=========================================
Run from the repo root:
    julia --project examples/demo_data_models.jl
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using TransformerThermalModel

# ---------------------------------------------------------------------------
# 1. Power transformer — one-step construction, verbose display
# ---------------------------------------------------------------------------

tr_onan = PowerTransformer{ONAN}(P_fe = 12_600.0, P_cu = 76_000.0, I_r = 1_443.4)
println(tr_onan)

# ---------------------------------------------------------------------------
# 2. Power transformer (ONAF) — different IEC defaults
# ---------------------------------------------------------------------------

println()
tr_onaf = PowerTransformer{ONAF}(P_fe = 12_600.0, P_cu = 76_000.0, I_r = 1_443.4)
println(tr_onaf)

# ---------------------------------------------------------------------------
# 3. Override IEC defaults via keyword arguments
# ---------------------------------------------------------------------------

println()
tr_custom = PowerTransformer{ONAN}(
    P_fe = 12_600.0,
    P_cu = 76_000.0,
    I_r = 1_443.4,
    g_r = 22.0,   # measured winding gradient — overrides the IEC default of 17 K
    τ_w = 12.0,   # measured winding time constant
)
println(tr_custom)

# ---------------------------------------------------------------------------
# 4. Distribution transformer — scale_amb=false, 10 K indoor Δθ_amb
# ---------------------------------------------------------------------------

println()
tr_dist = DistributionTransformer(P_fe = 500.0, P_cu = 8_000.0, I_r = 231.0)
println(tr_dist)

# ---------------------------------------------------------------------------
# 5. Three-winding transformer
# ---------------------------------------------------------------------------

println()
lv = WindingSpec(I_r = 1_649.6, S_r = 30.0, g_r = 25.4, τ_w = 7.0, H = 1.3)
mv = WindingSpec(I_r = 1_099.7, S_r = 100.0, g_r = 18.6, τ_w = 7.0, H = 1.3)
hv = WindingSpec(I_r = 384.9, S_r = 100.0, g_r = 17.6, τ_w = 7.0, H = 1.3)

tr_3w = ThreeWindingTransformer{ONAF}(
    P_fe = 51_740.0,
    lv = lv,
    mv = mv,
    hv = hv,
    P_ll_hv_lv = 184_439.0,
    P_ll_hv_mv = 93_661.0,
    P_ll_mv_lv = 46_531.0,
    P_ll_total = 329_800.0,   # optional — auto-computed from pairwise losses if omitted
)
println(tr_3w)

# ---------------------------------------------------------------------------
# 6. Compact form — used e.g. in log messages or print()
# ---------------------------------------------------------------------------

println()
println("Compact form:")
io_compact = IOContext(stdout, :compact => true)
print(io_compact, tr_onan);
println()
print(io_compact, tr_dist);
println()
print(io_compact, tr_3w);
println()
