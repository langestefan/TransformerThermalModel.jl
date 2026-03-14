
# ---------------------------------------------------------------------------
# BushingConfig
# ---------------------------------------------------------------------------

@testitem "BushingConfig — subtypes are distinct" tags = [:unit, :fast] begin
    using TransformerThermalModel:
        BushingConfig, SingleBushing, DoubleBushing, TriangleBushing

    @test SingleBushing() isa BushingConfig
    @test DoubleBushing() isa BushingConfig
    @test TriangleBushing() isa BushingConfig
    @test typeof(SingleBushing()) != typeof(DoubleBushing())
    @test typeof(DoubleBushing()) != typeof(TriangleBushing())
    @test typeof(SingleBushing()) != typeof(TriangleBushing())
end

# ---------------------------------------------------------------------------
# TransformerSide
# ---------------------------------------------------------------------------

@testitem "TransformerSide — subtypes are distinct" tags = [:unit, :fast] begin
    using TransformerThermalModel: TransformerSide, Primary, Secondary

    @test Primary() isa TransformerSide
    @test Secondary() isa TransformerSide
    @test typeof(Primary()) != typeof(Secondary())
end

# ---------------------------------------------------------------------------
# VectorConfig
# ---------------------------------------------------------------------------

@testitem "VectorConfig — subtypes are distinct" tags = [:unit, :fast] begin
    using TransformerThermalModel:
        VectorConfig, StarVector, TriangleInsideVector, TriangleOutsideVector

    @test StarVector() isa VectorConfig
    @test TriangleInsideVector() isa VectorConfig
    @test TriangleOutsideVector() isa VectorConfig
    @test typeof(StarVector()) != typeof(TriangleInsideVector())
    @test typeof(TriangleInsideVector()) != typeof(TriangleOutsideVector())
end

# ---------------------------------------------------------------------------
# TransformerKind hierarchy
# ---------------------------------------------------------------------------

@testitem "TransformerKind — subtypes are distinct" tags = [:unit, :fast] begin
    using TransformerThermalModel:
        TransformerKind,
        PowerTransformer,
        DistributionTransformer,
        ThreeWindingTransformer,
        WindingSpec,
        ONAN,
        ONAF

    lv = WindingSpec(I_r = 100.0, S_r = 10.0, g_r = 25.4, τ_w = 7.0, H = 1.3)
    mv = WindingSpec(I_r = 50.0, S_r = 10.0, g_r = 18.6, τ_w = 7.0, H = 1.3)
    hv = WindingSpec(I_r = 20.0, S_r = 10.0, g_r = 17.6, τ_w = 7.0, H = 1.3)
    tw_kwargs = (
        P_fe = 1000.0,
        lv = lv,
        mv = mv,
        hv = hv,
        P_ll_hv_lv = 5000.0,
        P_ll_hv_mv = 3000.0,
        P_ll_mv_lv = 2000.0,
    )

    @test PowerTransformer(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0) isa TransformerKind
    @test PowerTransformer{ONAN}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0) isa
          TransformerKind
    @test PowerTransformer{ONAF}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0) isa
          TransformerKind
    @test DistributionTransformer(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0) isa
          TransformerKind
    @test ThreeWindingTransformer(; tw_kwargs...) isa TransformerKind
    @test ThreeWindingTransformer{ONAF}(; tw_kwargs...) isa TransformerKind

    @test typeof(PowerTransformer{ONAN}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)) !=
          typeof(PowerTransformer{ONAF}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0))
    @test typeof(PowerTransformer(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)) ==
          typeof(PowerTransformer{ONAN}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0))
    @test typeof(ThreeWindingTransformer(; tw_kwargs...)) ==
          typeof(ThreeWindingTransformer{ONAN}(; tw_kwargs...))
end

# ---------------------------------------------------------------------------
# default_spec — PowerTransformer
# ---------------------------------------------------------------------------

@testitem "default_spec(PowerTransformer{ONAN}) — IEC 60076-7 power ONAN defaults" tags =
    [:unit, :fast] begin
    using TransformerThermalModel:
        ONAN, PowerTransformer, DefaultTransformerSpec, default_spec

    # explicit and default type produce identical results
    @test default_spec(PowerTransformer{ONAN}) == default_spec(PowerTransformer{ONAN})

    d = default_spec(PowerTransformer{ONAN})

    @test d isa DefaultTransformerSpec
    @test d.oil.τ_oil == 210.0
    @test d.τ_w == 10.0
    @test d.oil.Δθ_or == 60.0
    @test d.g_r == 17.0
    @test d.H == 1.3
    @test d.oil.k₁₁ == 0.5
    @test d.oil.x == 0.8
    @test d.oil.y == 1.3
end

@testitem "default_spec(PowerTransformer{ONAF}) — IEC 60076-7 power ONAF defaults" tags =
    [:unit, :fast] begin
    using TransformerThermalModel:
        ONAF, PowerTransformer, DefaultTransformerSpec, default_spec

    d = default_spec(PowerTransformer{ONAF})

    @test d isa DefaultTransformerSpec
    @test d.oil.τ_oil == 150.0
    @test d.τ_w == 7.0
    @test d.g_r == 17.0
    @test d.H == 1.3
end

# ---------------------------------------------------------------------------
# default_spec — DistributionTransformer
# ---------------------------------------------------------------------------

@testitem "default_spec(DistributionTransformer) — IEC 60076-7 distribution defaults" tags =
    [:unit, :fast] begin
    using TransformerThermalModel:
        DistributionTransformer, DefaultTransformerSpec, default_spec

    d = default_spec(DistributionTransformer)

    @test d isa DefaultTransformerSpec
    @test d.oil.τ_oil == 180.0
    @test d.τ_w == 4.0
    @test d.g_r == 23.0
    @test d.H == 1.2
    @test d.oil.k₁₁ == 1.0
    @test d.oil.x == 0.8
    @test d.oil.y == 1.6
    @test d.oil.Δθ_amb == 10.0   # indoor surcharge
end

# ---------------------------------------------------------------------------
# default_spec — ThreeWindingTransformer
# ---------------------------------------------------------------------------

@testitem "default_spec(ThreeWindingTransformer{ONAN}) — IEC 60076-7 three-winding ONAN defaults" tags =
    [:unit, :fast] begin
    using TransformerThermalModel:
        ONAN, ThreeWindingTransformer, DefaultThreeWindingSpec, default_spec

    # explicit and default type produce identical results
    @test default_spec(ThreeWindingTransformer{ONAN}) ==
          default_spec(ThreeWindingTransformer{ONAN})

    d = default_spec(ThreeWindingTransformer{ONAN})

    @test d isa DefaultThreeWindingSpec
    @test d.oil.τ_oil == 210.0

    for w in (d.lv, d.mv, d.hv)
        @test w.I_r == 0.0   # sentinel
        @test w.S_r == 0.0   # sentinel
        @test w.g_r == 17.0
        @test w.τ_w == 10.0
        @test w.H == 1.3
    end
end

@testitem "default_spec(ThreeWindingTransformer{ONAF}) — IEC 60076-7 three-winding ONAF defaults" tags =
    [:unit, :fast] begin
    using TransformerThermalModel:
        ONAF, ThreeWindingTransformer, DefaultThreeWindingSpec, default_spec

    d = default_spec(ThreeWindingTransformer{ONAF})

    @test d isa DefaultThreeWindingSpec
    @test d.oil.τ_oil == 150.0
    @test d.lv.τ_w == 7.0
    @test d.mv.τ_w == 7.0
    @test d.hv.τ_w == 7.0
end

# ---------------------------------------------------------------------------
# default_spec — compose with TransformerSpec / ThreeWindingSpec constructors
# ---------------------------------------------------------------------------

@testitem "default_spec + TransformerSpec — round-trip for power transformer" tags =
    [:unit, :fast] begin
    using TransformerThermalModel:
        ONAN, PowerTransformer, TransformerSpec, default_spec, τ_oil

    d = default_spec(PowerTransformer{ONAN})
    spec = TransformerSpec(100.0, 5000.0, 400.0, true, d)

    @test spec.P_fe == 100.0
    @test spec.P_cu == 5000.0
    @test spec.I_r == 400.0
    @test spec.scale_amb == true
    @test τ_oil(spec) == 210.0   # τ_oil accessor works on AbstractTransformerSpec
    @test spec.g_r == 17.0
end

@testitem "default_spec + ThreeWindingSpec — round-trip for three-winding transformer" tags =
    [:unit, :fast] begin
    using TransformerThermalModel:
        ONAF, ThreeWindingTransformer, WindingSpec, ThreeWindingSpec, default_spec, τ_oil

    d = default_spec(ThreeWindingTransformer{ONAF})

    lv = WindingSpec(I_r = 1649.6, S_r = 30.0, g_r = 25.4, τ_w = 7.0, H = 1.3)
    mv = WindingSpec(I_r = 1099.7, S_r = 100.0, g_r = 18.6, τ_w = 7.0, H = 1.3)
    hv = WindingSpec(I_r = 384.9, S_r = 100.0, g_r = 17.6, τ_w = 7.0, H = 1.3)

    spec = ThreeWindingSpec(
        51740.0,
        lv,
        mv,
        hv,
        184439.0,
        93661.0,
        46531.0,
        d;
        P_ll_total = 329800.0,
    )

    @test τ_oil(spec) == 150.0   # τ_oil accessor works on AbstractTransformerSpec
    @test spec.P_fe == 51740.0
    @test spec.P_ll_total == 329800.0
    @test spec.lv.S_r == 30.0
end

# ---------------------------------------------------------------------------
# One-step constructor — PowerTransformer
# ---------------------------------------------------------------------------

@testitem "PowerTransformer one-step constructor — ONAN defaults" tags = [:unit, :fast] begin
    using TransformerThermalModel: ONAN, PowerTransformer, TransformerSpec, spec, τ_oil

    tr = PowerTransformer{ONAN}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)

    @test tr isa PowerTransformer{ONAN}
    @test spec(tr) isa TransformerSpec
    @test tr.spec.P_fe == 100.0
    @test tr.spec.P_cu == 5000.0
    @test tr.spec.I_r == 400.0
    @test tr.spec.scale_amb == true
    @test τ_oil(tr) == 210.0
    @test tr.spec.g_r == 17.0
end

@testitem "PowerTransformer one-step constructor — ONAF defaults" tags = [:unit, :fast] begin
    using TransformerThermalModel: ONAF, PowerTransformer, spec, τ_oil

    tr = PowerTransformer{ONAF}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)

    @test tr isa PowerTransformer{ONAF}
    @test τ_oil(tr) == 150.0
    @test tr.spec.scale_amb == true
end

@testitem "PowerTransformer default cooler type is ONAN" tags = [:unit, :fast] begin
    using TransformerThermalModel: ONAN, PowerTransformer

    tr_default = PowerTransformer(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)
    tr_onan = PowerTransformer{ONAN}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)

    @test typeof(tr_default) == typeof(tr_onan)
    @test tr_default.spec == tr_onan.spec
end

@testitem "PowerTransformer kwargs override defaults" tags = [:unit, :fast] begin
    using TransformerThermalModel: ONAN, PowerTransformer

    tr = PowerTransformer{ONAN}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0, g_r = 99.9)

    @test tr.spec.g_r == 99.9
end

# ---------------------------------------------------------------------------
# One-step constructor — DistributionTransformer
# ---------------------------------------------------------------------------

@testitem "DistributionTransformer one-step constructor — sets scale_amb=false" tags =
    [:unit, :fast] begin
    using TransformerThermalModel: DistributionTransformer, TransformerSpec, spec, τ_oil

    tr = DistributionTransformer(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)

    @test tr isa DistributionTransformer
    @test spec(tr) isa TransformerSpec
    @test tr.spec.scale_amb == false
    @test τ_oil(tr) == 180.0
    @test tr.spec.g_r == 23.0
end

# ---------------------------------------------------------------------------
# One-step constructor — ThreeWindingTransformer
# ---------------------------------------------------------------------------

@testsnippet ThreeWindingFixture begin
    using TransformerThermalModel: WindingSpec
    lv = WindingSpec(I_r = 1649.6, S_r = 30.0, g_r = 25.4, τ_w = 7.0, H = 1.3)
    mv = WindingSpec(I_r = 1099.7, S_r = 100.0, g_r = 18.6, τ_w = 7.0, H = 1.3)
    hv = WindingSpec(I_r = 384.9, S_r = 100.0, g_r = 17.6, τ_w = 7.0, H = 1.3)
end

@testitem "ThreeWindingTransformer one-step constructor — ONAN defaults" tags =
    [:unit, :fast] setup = [ThreeWindingFixture] begin
    using TransformerThermalModel:
        ONAN, ThreeWindingTransformer, ThreeWindingSpec, spec, τ_oil, windings

    tr = ThreeWindingTransformer{ONAN}(
        P_fe = 51740.0,
        lv = lv,
        mv = mv,
        hv = hv,
        P_ll_hv_lv = 184439.0,
        P_ll_hv_mv = 93661.0,
        P_ll_mv_lv = 46531.0,
    )

    @test tr isa ThreeWindingTransformer{ONAN}
    @test spec(tr) isa ThreeWindingSpec
    @test tr.spec.P_fe == 51740.0
    @test τ_oil(tr) == 210.0
    @test windings(tr) == (lv, mv, hv)
end

@testitem "ThreeWindingTransformer default cooler type is ONAN" tags = [:unit, :fast] setup =
    [ThreeWindingFixture] begin
    using TransformerThermalModel: ONAN, ThreeWindingTransformer

    kwargs = (
        P_fe = 51740.0,
        lv = lv,
        mv = mv,
        hv = hv,
        P_ll_hv_lv = 184439.0,
        P_ll_hv_mv = 93661.0,
        P_ll_mv_lv = 46531.0,
    )

    tr_default = ThreeWindingTransformer(; kwargs...)
    tr_onan = ThreeWindingTransformer{ONAN}(; kwargs...)

    @test typeof(tr_default) == typeof(tr_onan)
    @test tr_default.spec == tr_onan.spec
end

# ---------------------------------------------------------------------------
# Accessor forwarding on TransformerKind
# ---------------------------------------------------------------------------

@testitem "accessor forwarding — PowerTransformer delegates to spec" tags = [:unit, :fast] begin
    using TransformerThermalModel:
        ONAF, PowerTransformer, spec, oil, τ_oil, Δθ_or, Δθ_amb, k₁₁, k₂₁, k₂₂, x, y, Δθ_end

    tr = PowerTransformer{ONAF}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)

    @test oil(tr) == oil(spec(tr))
    @test τ_oil(tr) == τ_oil(spec(tr))
    @test Δθ_or(tr) == Δθ_or(spec(tr))
    @test Δθ_amb(tr) == Δθ_amb(spec(tr))
    @test k₁₁(tr) == k₁₁(spec(tr))
    @test k₂₁(tr) == k₂₁(spec(tr))
    @test k₂₂(tr) == k₂₂(spec(tr))
    @test x(tr) == x(spec(tr))
    @test y(tr) == y(spec(tr))
    @test Δθ_end(tr) == Δθ_end(spec(tr))
end

@testitem "accessor forwarding — ThreeWindingTransformer windings" tags = [:unit, :fast] setup =
    [ThreeWindingFixture] begin
    using TransformerThermalModel: ONAN, ThreeWindingTransformer, windings

    tr = ThreeWindingTransformer{ONAN}(
        P_fe = 51740.0,
        lv = lv,
        mv = mv,
        hv = hv,
        P_ll_hv_lv = 184439.0,
        P_ll_hv_mv = 93661.0,
        P_ll_mv_lv = 46531.0,
    )

    ws = windings(tr)
    @test ws[1] === lv
    @test ws[2] === mv
    @test ws[3] === hv
end
