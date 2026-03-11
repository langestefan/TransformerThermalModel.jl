# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

@testsnippet OnanSpec begin
    using TransformerThermalModel, Dates
    # Matches Python conftest onan_power_transformer fixture:
    #   load_loss=1000, nom_load=1500, no_load_loss=200, amb_temp_surcharge=20, H=1.1
    spec_onan = PowerTransformer(
        PowerTransformerParams(
            no_load_loss = 200.0,
            load_loss = 1000.0,
            nom_load = 1500.0,
            overrides = ThermalOverrides(H = 1.1, Δθ_amb = 20.0),
        ),
    )
end

@testsnippet OnafSpec begin
    using TransformerThermalModel, Dates
    spec_onaf = PowerTransformer(
        PowerTransformerParams(
            no_load_loss = 200.0,
            load_loss = 1000.0,
            nom_load = 1500.0,
            cooler = ONAF,
            overrides = ThermalOverrides(H = 1.1, Δθ_amb = 20.0),
        ),
    )
end

@testsnippet DistSpec begin
    using TransformerThermalModel, Dates
    # Matches Python conftest distribution_transformer fixture:
    #   same losses/nom_load, amb_temp_surcharge=20, H=1.1
    spec_dist = DistributionTransformer(
        DistributionTransformerParams(
            no_load_loss = 200.0,
            load_loss = 1000.0,
            nom_load = 1500.0,
            overrides = ThermalOverrides(H = 1.1, Δθ_amb = 20.0),
        ),
    )
end

# Helper: build a profile with τ-time steps
@testsnippet ProfileHelpers begin
    using TransformerThermalModel, Dates

    function tau_profile(τ_time_min, loads, ambient_temp)
        t0 = DateTime(2021, 1, 1)
        n = length(loads)
        times = [t0 + Minute(round(Int, (i - 1) * τ_time_min)) for i = 1:n]
        return InputProfile(times, loads, fill(float(ambient_temp), n))
    end
end

# ---------------------------------------------------------------------------
# Cold-start / zero-load baseline
# ---------------------------------------------------------------------------

@testitem "zero load zero losses → temperatures equal ambient" tags = [:unit, :model] begin
    using TransformerThermalModel, Dates
    # H=1.3 default, no surcharge, no losses (R→∞, but handled via no_load_loss→0)
    spec = PowerTransformer(
        PowerTransformerParams(
            no_load_loss = 1e-9,   # near-zero (avoid /0)
            load_loss = 1000.0,
            nom_load = 1500.0,
            overrides = ThermalOverrides(Δθ_amb = 0.0),
        ),
    )
    t0 = DateTime(2021, 1, 1)
    profile = InputProfile(
        [t0, t0 + Hour(1), t0 + Hour(2)],
        [0.0, 0.0, 0.0],
        [5.0, 5.0, 5.0],
    )
    result = simulate(spec, profile)
    @test result.top_oil ≈ [5.0, 5.0, 5.0] atol = 1e-6
    @test result.hot_spot ≈ [5.0, 5.0, 5.0] atol = 1e-6
end

@testitem "large timesteps → steady-state temperatures" tags = [:unit, :model] begin
    using TransformerThermalModel, Dates
    # With month-long steps at nominal load (K=1), temperatures must reach
    # θ_a + Δθ_or   and   θ_a + Δθ_or + H*g_r  (at K=1, k₂₁=2 cancels: W∞-O∞=g_r_eff)
    spec = PowerTransformer(
        PowerTransformerParams(
            no_load_loss = 1e-9,
            load_loss = 1000.0,
            nom_load = 1500.0,
            overrides = ThermalOverrides(Δθ_amb = 0.0),
        ),
    )
    θ_a = 20.0
    t0 = DateTime(2021, 1, 1)
    # K = nom_load / nom_load = 1.0  →  steady-state
    profile = InputProfile(
        [t0, t0 + Day(30), t0 + Day(60)],
        [1.0, 1.0, 1.0],
        [θ_a, θ_a, θ_a],
    )
    result = simulate(spec, profile)
    # At K=1, R→0: Δθ_o∞ = Δθ_or*(1)^x = Δθ_or = 60
    # δθ_H∞ = W∞ - O∞ = k₂₁*g_r_eff - (k₂₁-1)*g_r_eff = g_r_eff = H*g_r = 1.3*17 = 22.1
    expected_oil = θ_a + spec.Δθ_or
    expected_hs = θ_a + spec.Δθ_or + spec.H * spec.g_r
    @test result.top_oil[2] ≈ expected_oil atol = 0.01
    @test result.top_oil[3] ≈ expected_oil atol = 0.01
    @test result.hot_spot[2] ≈ expected_hs atol = 0.01
    @test result.hot_spot[3] ≈ expected_hs atol = 0.01
end

# ---------------------------------------------------------------------------
# Reference comparison against Python test_expected_rise_distribution
# ---------------------------------------------------------------------------

@testitem "distribution τ-step profile — reference values" tags = [:unit, :model, :validation] setup = [
    DistSpec,
    ProfileHelpers,
] begin
    # τ_time = k₁₁ * τ_oil = 1.0 * 180 = 180 min for distribution
    τ_time = spec_dist.k₁₁ * spec_dist.τ_oil
    K = 1000.0 / spec_dist.nom_load   # per-unit load
    loads = vcat(fill(K, 8), fill(0.0, 8))
    profile = tau_profile(τ_time, loads, 20.0)
    result = simulate(spec_dist, profile)

    expected_oil = [
        20.0,
        50.75341103,
        62.0669587,
        66.22898029,
        67.76010247,
        68.32337084,
        68.53058569,
        68.60681578,
        49.9420479,
        43.07566352,
        40.54966187,
        39.62039779,
        39.27854065,
        39.15277843,
        39.10651309,
        39.08949303,
    ]
    expected_hs = [
        20.0,
        63.97776626,
        75.29131393,
        79.45333552,
        80.9844577,
        81.54772607,
        81.75494092,
        81.83117101,
        49.9420479,
        43.07566352,
        40.54966187,
        39.62039779,
        39.27854065,
        39.15277843,
        39.10651309,
        39.08949303,
    ]

    # First step must equal ambient (cold start, no surcharge added to ambient)
    @test result.top_oil[1] == 20.0
    @test result.hot_spot[1] == 20.0

    @test sum(abs.(result.top_oil .- expected_oil)) < 1e-6
    @test sum(abs.(result.hot_spot .- expected_hs)) < 1e-6
end

# ---------------------------------------------------------------------------
# Reference comparison against Python test_expected_rise_onan
# ---------------------------------------------------------------------------

@testitem "ONAN τ-step profile — reference values" tags = [:unit, :model, :validation] setup = [
    OnanSpec,
    ProfileHelpers,
] begin
    # τ_time = k₁₁ * τ_oil = 0.5 * 210 = 105 min
    τ_time = spec_onan.k₁₁ * spec_onan.τ_oil
    K = 1000.0 / spec_onan.nom_load
    loads = vcat(fill(K, 8), fill(0.0, 8))
    profile = tau_profile(τ_time, loads, 20.0)
    result = simulate(spec_onan, profile)

    # First step = ambient + Δθ_amb surcharge (power transformer, add_surcharge_to_ambient=true)
    @test result.top_oil[1] == 20.0 + spec_onan.Δθ_amb
    @test result.hot_spot[1] == 20.0 + spec_onan.Δθ_amb

    expected_oil = [
        40.0,
        63.06505828,
        71.55021902,
        74.67173522,
        75.82007685,
        76.24252813,
        76.39793927,
        76.45511183,
        62.45653592,
        57.30674764,
        55.4122464,
        54.71529835,
        54.45890548,
        54.36458382,
        54.32988482,
        54.31711977,
    ]
    expected_hs = [
        40.0,
        78.04899136,
        84.08238209,
        86.260151,
        87.06108811,
        87.35573525,
        87.46412987,
        87.50400603,
        58.51513404,
        55.81477495,
        54.86315987,
        54.51329954,
        54.38459427,
        54.33724625,
        54.31982789,
        54.31342003,
    ]

    @test sum(abs.(result.top_oil .- expected_oil)) < 1e-6
    @test sum(abs.(result.hot_spot .- expected_hs)) < 1e-6
end

# ---------------------------------------------------------------------------
# Reference comparison against Python test_expected_rise_onaf
# ---------------------------------------------------------------------------

@testitem "ONAF τ-step profile — reference values" tags = [:unit, :model, :validation] setup = [
    OnafSpec,
    ProfileHelpers,
] begin
    # τ_time = k₁₁ * τ_oil = 0.5 * 150 = 75 min
    τ_time = spec_onaf.k₁₁ * spec_onaf.τ_oil
    K = 1000.0 / spec_onaf.nom_load
    loads = vcat(fill(K, 8), fill(0.0, 8))
    profile = tau_profile(τ_time, loads, 20.0)
    result = simulate(spec_onaf, profile)

    @test result.top_oil[1] == 20.0 + spec_onaf.Δθ_amb
    @test result.hot_spot[1] == 20.0 + spec_onaf.Δθ_amb

    expected_oil = [
        40.0,
        63.06505828,
        71.55021902,
        74.67173522,
        75.82007685,
        76.24252813,
        76.39793927,
        76.45511183,
        62.45653592,
        57.30674764,
        55.4122464,
        54.71529835,
        54.45890548,
        54.36458382,
        54.32988482,
        54.31711977,
    ]
    expected_hs = [
        40.0,
        78.06076232,
        84.08249935,
        86.26015188,
        87.06108811,
        87.35573525,
        87.46412987,
        87.50400603,
        58.50336307,
        55.81465769,
        54.86315899,
        54.51329953,
        54.38459427,
        54.33724625,
        54.31982789,
        54.31342003,
    ]

    @test sum(abs.(result.top_oil .- expected_oil)) < 1e-6
    @test sum(abs.(result.hot_spot .- expected_hs)) < 1e-6
end

# ---------------------------------------------------------------------------
# IEC 60076-7 load profile — reference values (±1.5 °C tolerance)
# ---------------------------------------------------------------------------

@testitem "IEC load profile — reference values" tags = [:unit, :model, :validation] begin
    using TransformerThermalModel, Dates

    # Matches Python test_if_rise_matches_iec
    spec = PowerTransformer(
        PowerTransformerParams(
            no_load_loss = 1.0,
            load_loss = 1000.0,
            nom_load = 1000.0,
            cooler = ONAF,
            overrides = ThermalOverrides(
                Δθ_or = 38.3,
                g_r = 14.5,
                H = 1.4,
                Δθ_amb = 0.0,
            ),
        ),
    )

    # Build the IEC profile: 5-minute steps, piecewise-constant load factors
    breakpoints = [0, 190, 365, 500, 705, 730, 745]
    load_factors = [1.0, 0.6, 1.5, 0.3, 2.1, 0.0]
    θ_amb = 25.6

    t0 = DateTime(2021, 1, 1)
    times = DateTime[]
    loads = Float64[]
    for i = 1:(length(breakpoints)-1)
        start_min = breakpoints[i]
        stop_min = breakpoints[i+1]
        for step = 1:((stop_min - start_min) ÷ 5)
            push!(times, t0 + Minute(start_min + step * 5))
            push!(loads, load_factors[i])   # already per-unit (nom_load=1000, load=factor*1000/1000)
        end
    end
    ambient = fill(θ_amb, length(times))
    profile = InputProfile(times, loads, ambient)

    # Initial condition: top-oil at 25.6 + 12.7 °C
    result = simulate(spec, profile, InitialTopOilTemp(θ_amb + 12.7))

    # Look up results at specific minute marks
    function at_minute(result, t0, minutes)
        t = t0 + Minute(minutes)
        idx = findfirst(==(t), result.time)
        return result.top_oil[idx], result.hot_spot[idx]
    end

    expected = [
        (minutes = 190, top_oil = 61.9, hot_spot = 83.8),
        (minutes = 365, top_oil = 44.4, hot_spot = 54.0),
        (minutes = 500, top_oil = 89.2, hot_spot = 127.0),
        (minutes = 705, top_oil = 35.0, hot_spot = 37.54),
        (minutes = 730, top_oil = 67.9, hot_spot = 138.6),
        (minutes = 745, top_oil = 60.3, hot_spot = 75.3),
    ]

    for e in expected
        oil, hs = at_minute(result, t0, e.minutes)
        @test oil ≈ e.top_oil atol = 1.5
        @test hs ≈ e.hot_spot atol = 1.5
    end
end

# ---------------------------------------------------------------------------
# InitialLoad initial condition
# ---------------------------------------------------------------------------

@testitem "InitialLoad initial condition — steady state at step 1" tags = [:unit, :model] setup = [
    OnanSpec,
] begin
    using Dates
    # Start at K=2/3 steady state, then keep the same load.
    # Steps 1 and 2 should both be at (or very near) the same temperature.
    K = 1000.0 / spec_onan.nom_load
    t0 = DateTime(2021, 1, 1)
    profile = InputProfile(
        [t0, t0 + Hour(1), t0 + Hour(2)],
        [K, K, K],
        [20.0, 20.0, 20.0],
    )
    result = simulate(spec_onan, profile, InitialLoad(K))
    # If already at steady state, top-oil and hot-spot should barely change
    @test result.top_oil[1] ≈ result.top_oil[2] atol = 0.01
    @test result.hot_spot[1] ≈ result.hot_spot[2] atol = 0.01
end

# ---------------------------------------------------------------------------
# thermal_step_function / thermal_params consistency
# ---------------------------------------------------------------------------

@testitem "thermal_step_function matches simulate" tags = [:unit, :model] setup = [OnanSpec] begin
    using Dates
    K = 1000.0 / spec_onan.nom_load
    τ_time = spec_onan.k₁₁ * spec_onan.τ_oil   # 105 min
    loads = vcat(fill(K, 8), fill(0.0, 8))

    t0 = DateTime(2021, 1, 1)
    times = [t0 + Minute(round(Int, (i - 1) * τ_time)) for i = 1:16]
    profile = InputProfile(times, loads, fill(20.0, 16))

    result = simulate(spec_onan, profile)

    # Reconstruct via thermal_step_function
    p = thermal_params(spec_onan)
    f_disc = thermal_step_function(τ_time)
    idx_Δθ_o, idx_W, idx_O = thermal_state_indices()

    θ_a_eff = 20.0 + spec_onan.Δθ_amb   # 40.0

    let x = zeros(3)   # cold start; `let` avoids Julia hard-scope reassignment issue
        for k = 1:16
            oil_k = θ_a_eff + x[idx_Δθ_o]
            hs_k = oil_k + (x[idx_W] - x[idx_O]) - spec_onan.Δθ_end
            @test oil_k ≈ result.top_oil[k] atol = 1e-10
            @test hs_k ≈ result.hot_spot[k] atol = 1e-10
            k < 16 && (x = f_disc(x, [loads[k+1]], p, 0.0))
        end
    end
end
