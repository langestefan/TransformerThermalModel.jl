
@testsnippet TwoWindingFixtures begin
    using TransformerThermalModel

    _tr_power = PowerTransformer{ONAN}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)
    _tr_dist = DistributionTransformer(P_fe = 80.0, P_cu = 3000.0, I_r = 300.0)
end

@testsnippet ThreeWindingModelFixtures begin
    using TransformerThermalModel

    _lv = WindingSpec(I_r = 1649.6, S_r = 30.0, g_r = 25.4, τ_w = 10.0, H = 1.3)
    _mv = WindingSpec(I_r = 1099.7, S_r = 100.0, g_r = 18.6, τ_w = 10.0, H = 1.3)
    _hv = WindingSpec(I_r = 384.9, S_r = 100.0, g_r = 17.6, τ_w = 10.0, H = 1.3)

    _tr_3w = ThreeWindingTransformer{ONAN}(
        P_fe = 51740.0,
        lv = _lv,
        mv = _mv,
        hv = _hv,
        P_ll_hv_lv = 184439.0,
        P_ll_hv_mv = 93661.0,
        P_ll_mv_lv = 46531.0;
        P_ll_total = 329800.0,
    )
end

# ---------------------------------------------------------------------------
# System construction
# ---------------------------------------------------------------------------

@testitem "thermal_system — PowerTransformer compiles" tags = [:unit, :fast] setup =
    [TwoWindingFixtures] begin
    using TransformerThermalModel
    using ModelingToolkitInputs

    sys = thermal_system(_tr_power)
    @test sys isa ModelingToolkitInputs.InputSystem
    @test length(ModelingToolkitInputs.unknowns(sys)) == 3
end

@testitem "thermal_system — DistributionTransformer compiles" tags = [:unit, :fast] setup =
    [TwoWindingFixtures] begin
    using TransformerThermalModel
    using ModelingToolkitInputs

    sys = thermal_system(_tr_dist)
    @test sys isa ModelingToolkitInputs.InputSystem
    @test length(ModelingToolkitInputs.unknowns(sys)) == 3
end

@testitem "thermal_system — ThreeWindingTransformer compiles" tags = [:unit, :fast] setup =
    [ThreeWindingModelFixtures] begin
    using TransformerThermalModel
    using ModelingToolkitInputs

    sys = thermal_system(_tr_3w)
    @test sys isa ModelingToolkitInputs.InputSystem
    @test length(ModelingToolkitInputs.unknowns(sys)) == 7
end

# ---------------------------------------------------------------------------
# Initial conditions
# ---------------------------------------------------------------------------

@testitem "initial_conditions — ColdStart two-winding" tags = [:unit, :fast] setup =
    [TwoWindingFixtures] begin
    using TransformerThermalModel

    sys = thermal_system(_tr_power)
    u0 = initial_conditions(sys, _tr_power, ColdStart())

    @test length(u0) == 3
    @test all(last(p) == 0.0 for p in u0)
end

@testitem "initial_conditions — ColdStart three-winding" tags = [:unit, :fast] setup =
    [ThreeWindingModelFixtures] begin
    using TransformerThermalModel

    sys = thermal_system(_tr_3w)
    u0 = initial_conditions(sys, _tr_3w, ColdStart())

    @test length(u0) == 7
    @test all(last(p) == 0.0 for p in u0)
end

@testitem "initial_conditions — InitialLoad matches _steady_state" tags = [:unit, :fast] setup =
    [TwoWindingFixtures] begin
    using TransformerThermalModel

    K = 0.8
    sys = thermal_system(_tr_power)
    u0 = initial_conditions(sys, _tr_power, InitialLoad(K))
    ss = TransformerThermalModel._steady_state(spec(_tr_power), K)

    u0_dict = Dict(u0)
    @test u0_dict[sys.Δθ_o] ≈ ss.Δθ_o
    @test u0_dict[sys.W] ≈ ss.W
    @test u0_dict[sys.O_state] ≈ ss.O
end

@testitem "initial_conditions — InitialTopOil two-winding" tags = [:unit, :fast] setup =
    [TwoWindingFixtures] begin
    using TransformerThermalModel

    θ_oil = 65.0
    θ_a_0 = 20.0
    sys = thermal_system(_tr_power)
    u0 = initial_conditions(sys, _tr_power, InitialTopOil(θ_oil); θ_a_0 = θ_a_0)

    u0_dict = Dict(u0)
    # scale_amb=true, Δθ_amb=0 for ONAN default → θ_a_eff = θ_a_0
    @test u0_dict[sys.Δθ_o] ≈ θ_oil - θ_a_0
    @test u0_dict[sys.W] == 0.0
    @test u0_dict[sys.O_state] == 0.0
end

# ---------------------------------------------------------------------------
# Steady-state convergence
# ---------------------------------------------------------------------------

@testitem "steady-state convergence — PowerTransformer K=1" tags = [:integration] setup =
    [TwoWindingFixtures] begin
    using TransformerThermalModel
    using OrdinaryDiffEq
    import ModelingToolkitBase as MTK

    K = 1.0
    θ_a = 20.0
    tspan = (0.0, 10.0 * τ_oil(_tr_power))  # 10× τ_oil ≈ 2100 min

    sys = thermal_system(_tr_power)
    u0 = initial_conditions(sys, _tr_power, ColdStart())
    prob = MTK.ODEProblem(sys, u0, tspan)

    K_in = Input(sys.K, [K, K], [0.0, tspan[2]])
    θ_a_in = Input(sys.θ_a, [θ_a, θ_a], [0.0, tspan[2]])
    sol = solve(prob, Tsit5(); inputs = [K_in, θ_a_in], reltol = 1e-6, abstol = 1e-6)

    ss = TransformerThermalModel._steady_state(spec(_tr_power), K)
    # scale_amb=true, Δθ_amb=0 for ONAN → θ_a_eff = θ_a
    θ_oil_expected = θ_a + ss.Δθ_o
    θ_H_expected = θ_oil_expected + ss.W - ss.O - Δθ_end(_tr_power)

    @test sol(tspan[2]; idxs = sys.θ_oil) ≈ θ_oil_expected rtol = 0.01
    @test sol(tspan[2]; idxs = sys.θ_H) ≈ θ_H_expected rtol = 0.01
end

@testitem "step response — temperatures rise on load increase" tags = [:integration] setup =
    [TwoWindingFixtures] begin
    using TransformerThermalModel
    using OrdinaryDiffEq
    import ModelingToolkitBase as MTK

    θ_a = 20.0
    t_step = 60.0   # min — step from K=0 to K=1 at t=60
    tspan = (0.0, 5.0 * τ_oil(_tr_power))

    sys = thermal_system(_tr_power)
    u0 = initial_conditions(sys, _tr_power, ColdStart())
    prob = MTK.ODEProblem(sys, u0, tspan)

    K_in = Input(sys.K, [0.0, 1.0, 1.0], [0.0, t_step, tspan[2]])
    θ_a_in = Input(sys.θ_a, [θ_a, θ_a, θ_a], [0.0, t_step, tspan[2]])
    sol = solve(prob, Tsit5(); inputs = [K_in, θ_a_in])

    # Before the step, temperatures are below the post-step level
    θ_oil_prestep = sol(t_step - 1.0; idxs = sys.θ_oil)
    # After enough time, temperatures are higher than just before the step
    @test sol(tspan[2]; idxs = sys.θ_oil) > θ_oil_prestep
    @test sol(tspan[2]; idxs = sys.θ_H) > sol(t_step; idxs = sys.θ_H)
end
