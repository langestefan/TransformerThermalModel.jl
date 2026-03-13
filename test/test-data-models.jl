
@testsnippet ThreeWindingFixtures begin
    using TransformerThermalModel: OilSpec, WindingSpec, DefaultThreeWindingSpec

    # ONAN oil defaults matching IEC test case (τ_oil=180, k₁₁=1.0, y=1.6)
    _oil = OilSpec(
        Δθ_amb = 0.0,
        τ_oil = 180.0,
        Δθ_or = 60.0,
        k₁₁ = 1.0,
        k₂₁ = 1.0,
        k₂₂ = 2.0,
        x = 0.8,
        y = 1.6,
        Δθ_end = 0.0,
    )

    # Per-winding defaults (sentinel I_r=S_r=0; g_r, τ_w, H match IEC power defaults)
    _dw = WindingSpec(I_r = 0.0, S_r = 0.0, g_r = 17.0, τ_w = 10.0, H = 1.3)

    _defaults = DefaultThreeWindingSpec(oil = _oil, lv = _dw, mv = _dw, hv = _dw)
end

@testitem "ThreeWindingSpec — construction preserves fields" tags = [:unit, :fast] setup =
    [ThreeWindingFixtures] begin
    using TransformerThermalModel: ThreeWindingSpec, windings, τ_oil

    lv = WindingSpec(I_r = 1000.0, S_r = 30.0, g_r = 17.0, τ_w = 10.0, H = 1.3)
    mv = WindingSpec(I_r = 1000.0, S_r = 100.0, g_r = 17.0, τ_w = 10.0, H = 1.3)
    hv = WindingSpec(I_r = 1000.0, S_r = 100.0, g_r = 17.0, τ_w = 10.0, H = 1.3)

    spec = ThreeWindingSpec(20.0, lv, mv, hv, 100.0, 100.0, 100.0, _defaults)

    @test spec.lv.I_r == 1000.0
    @test τ_oil(spec) == 180.0
    @test getfield.(windings(spec), :I_r) == (1000.0, 1000.0, 1000.0)
    @test getfield.(windings(spec), :g_r) == (17.0, 17.0, 17.0)
end

@testitem "ThreeWindingSpec — P_ll_total auto-computed from pairwise losses" tags =
    [:unit, :fast] setup = [ThreeWindingFixtures] begin
    using TransformerThermalModel: ThreeWindingSpec

    # Equal S_r=150 MVA on all three windings → c₁ = c₂ = 1
    # P_hc = P_mc = P_lc = 0.5*(20000 - 20000 + 20000) = 10000
    # P_ll_total = 10000 + 10000 + 10000 + P_fe(10000) = 40000
    w = WindingSpec(I_r = 1600.0, S_r = 150.0, g_r = 23.0, τ_w = 10.0, H = 1.3)

    spec = ThreeWindingSpec(10000.0, w, w, w, 20000.0, 20000.0, 20000.0, _defaults)

    @test spec.P_ll_total == 40000.0
end

@testitem "ThreeWindingSpec — explicit P_ll_total takes precedence" tags = [:unit, :fast] setup =
    [ThreeWindingFixtures] begin
    using TransformerThermalModel: ThreeWindingSpec

    w = WindingSpec(I_r = 1600.0, S_r = 150.0, g_r = 23.0, τ_w = 10.0, H = 1.3)

    spec = ThreeWindingSpec(
        10000.0,
        w,
        w,
        w,
        20000.0,
        20000.0,
        20000.0,
        _defaults;
        P_ll_total = 35000.0,
    )

    @test spec.P_ll_total == 35000.0
end

@testitem "ThreeWindingSpec — star-circuit decomposition is consistent" tags =
    [:unit, :fast] begin
    using TransformerThermalModel:
        OilSpec, WindingSpec, DefaultThreeWindingSpec, ThreeWindingSpec

    # Real transformer data (ONAF, unequal winding MVA ratings)
    oil = OilSpec(
        Δθ_amb = 0.0,
        τ_oil = 150.0,
        Δθ_or = 60.0,
        k₁₁ = 0.5,
        k₂₁ = 2.0,
        k₂₂ = 2.0,
        x = 0.8,
        y = 1.3,
        Δθ_end = 0.0,
    )
    dw = WindingSpec(I_r = 0.0, S_r = 0.0, g_r = 17.0, τ_w = 7.0, H = 1.3)
    defaults = DefaultThreeWindingSpec(oil = oil, lv = dw, mv = dw, hv = dw)

    hv = WindingSpec(I_r = 384.9, S_r = 100.0, g_r = 17.6, τ_w = 7.0, H = 1.3)
    mv = WindingSpec(I_r = 1099.7, S_r = 100.0, g_r = 18.6, τ_w = 7.0, H = 1.3)
    lv = WindingSpec(I_r = 1649.6, S_r = 30.0, g_r = 25.4, τ_w = 7.0, H = 1.3)

    P_ll_hv_lv = 184439.0
    P_ll_hv_mv = 93661.0
    P_ll_mv_lv = 46531.0

    spec = ThreeWindingSpec(
        51740.0,
        lv,
        mv,
        hv,
        P_ll_hv_lv,
        P_ll_hv_mv,
        P_ll_mv_lv,
        defaults;
        P_ll_total = 329800.0,
    )

    # Re-derive the star-circuit individual winding losses
    c₁ = (spec.mv.S_r / spec.hv.S_r)^2
    c₂ = (spec.lv.S_r / spec.mv.S_r)^2

    P_hc = (0.5 / c₁) * (P_ll_hv_mv - (1 / c₂) * P_ll_mv_lv + (1 / c₂) * P_ll_hv_lv)
    P_mc = (0.5 / c₂) * (c₂ * P_ll_hv_mv - P_ll_hv_lv + P_ll_mv_lv)
    P_lc = 0.5 * (P_ll_hv_lv - c₂ * P_ll_hv_mv + P_ll_mv_lv)

    # Verify the three pairwise losses can be recovered from the star-circuit decomposition
    @test c₁ * P_hc + P_mc ≈ P_ll_hv_mv
    @test c₂ * P_mc + P_lc ≈ P_ll_mv_lv
    @test c₁ * c₂ * P_hc + P_lc ≈ P_ll_hv_lv
end

@testitem "ThreeWindingSpec — per-winding values override defaults" tags = [:unit, :fast] setup =
    [ThreeWindingFixtures] begin
    using TransformerThermalModel: ThreeWindingSpec

    lv = WindingSpec(I_r = 1600.0, S_r = 150.0, g_r = 25.0, τ_w = 8.0, H = 1.5)
    mv = WindingSpec(I_r = 1600.0, S_r = 150.0, g_r = 20.0, τ_w = 9.0, H = 1.4)
    hv = WindingSpec(I_r = 1600.0, S_r = 150.0, g_r = 17.0, τ_w = 10.0, H = 1.3)

    spec = ThreeWindingSpec(10000.0, lv, mv, hv, 20000.0, 20000.0, 20000.0, _defaults)

    @test spec.lv.H == 1.5
    @test spec.lv.g_r == 25.0
    @test spec.lv.τ_w == 8.0
    @test spec.mv.H == 1.4
    @test spec.mv.g_r == 20.0
    @test spec.hv.H == 1.3
end
