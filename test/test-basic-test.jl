using Dates

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

@testsnippet Specs begin
    using Dates
    using TransformerThermalModel

    power_spec =
        PowerTransformer(no_load_loss = 200.0, load_loss = 1000.0, nom_load = 1500.0)
    dist_spec =
        DistributionTransformer(no_load_loss = 800.0, load_loss = 5200.0, nom_load = 900.0)

    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 2)
    profile = InputProfile(t, [0.8, 0.9, 1.0], [25.0, 24.5, 24.0])
end

# ---------------------------------------------------------------------------
# CoolerType
# ---------------------------------------------------------------------------

@testitem "CoolerType enum values" tags=[:unit, :fast] begin
    using TransformerThermalModel
    @test instances(CoolerType) == (ONAN, ONAF)
end

# ---------------------------------------------------------------------------
# PaperInsulationType
# ---------------------------------------------------------------------------

@testitem "PaperInsulationType enum values" tags=[:unit, :fast] begin
    using TransformerThermalModel
    @test instances(PaperInsulationType) == (NormalPaper, ThermallyUpgradedPaper)
end

# ---------------------------------------------------------------------------
# PowerTransformer defaults (ONAN)
# ---------------------------------------------------------------------------

@testitem "PowerTransformer ONAN defaults" tags=[:unit, :fast] setup=[Specs] begin
    @test power_spec.τ_oil == 210.0
    @test power_spec.τ_w == 10.0
    @test power_spec.Δθ_or == 60.0
    @test power_spec.g_r == 17.0
    @test power_spec.H == 1.3
    @test power_spec.k₁₁ == 0.5
    @test power_spec.k₂₁ == 2.0
    @test power_spec.k₂₂ == 2.0
    @test power_spec.x == 0.8
    @test power_spec.y == 1.3
    @test power_spec.end_temp_reduction == 0.0
    @test power_spec.amb_temp_surcharge == 0.0
    @test power_spec.add_surcharge_to_ambient == true
end

@testitem "PowerTransformer stores user fields" tags=[:unit, :fast] setup=[Specs] begin
    @test power_spec.no_load_loss == 200.0
    @test power_spec.load_loss == 1000.0
    @test power_spec.nom_load == 1500.0
end

@testitem "PowerTransformer ONAF defaults differ from ONAN" tags=[:unit, :fast] begin
    using TransformerThermalModel
    spec = PowerTransformer(
        no_load_loss = 200.0,
        load_loss = 1000.0,
        nom_load = 1500.0,
        cooler = ONAF,
    )
    @test spec.τ_oil == 150.0
    @test spec.τ_w == 7.0
end

@testitem "PowerTransformer keyword overrides" tags=[:unit, :fast] begin
    using TransformerThermalModel
    spec = PowerTransformer(
        no_load_loss = 200.0,
        load_loss = 1000.0,
        nom_load = 1500.0,
        H = 1.5,
        amb_temp_surcharge = 5.0,
    )
    @test spec.H == 1.5
    @test spec.amb_temp_surcharge == 5.0
    @test spec.τ_oil == 210.0  # default unchanged
end

# ---------------------------------------------------------------------------
# DistributionTransformer defaults
# ---------------------------------------------------------------------------

@testitem "DistributionTransformer defaults" tags=[:unit, :fast] setup=[Specs] begin
    @test dist_spec.τ_oil == 180.0
    @test dist_spec.τ_w == 4.0
    @test dist_spec.g_r == 23.0
    @test dist_spec.H == 1.2
    @test dist_spec.k₁₁ == 1.0
    @test dist_spec.k₂₁ == 1.0
    @test dist_spec.y == 1.6
    @test dist_spec.amb_temp_surcharge == 10.0
    @test dist_spec.add_surcharge_to_ambient == false
end

# ---------------------------------------------------------------------------
# InitialState
# ---------------------------------------------------------------------------

@testitem "InitialState subtypes" tags=[:unit, :fast] begin
    using TransformerThermalModel
    @test ColdStart() isa InitialState
    @test InitialTopOilTemp(50.0) isa InitialState
    @test InitialLoad(0.8) isa InitialState
    @test InitialTopOilTemp(50.0).temp == 50.0
    @test InitialLoad(0.8).load == 0.8
end

# ---------------------------------------------------------------------------
# InputProfile
# ---------------------------------------------------------------------------

@testitem "InputProfile construction" tags=[:unit, :fast] setup=[Specs] begin
    @test length(profile.time) == 3
    @test profile.load == [0.8, 0.9, 1.0]
    @test profile.ambient == [25.0, 24.5, 24.0]
    @test profile.top_oil === nothing
end

@testitem "InputProfile with top_oil" tags=[:unit, :fast] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 1)
    p = InputProfile(t, [0.8, 0.9], [25.0, 24.5], [40.0, 41.0])
    @test p.top_oil == [40.0, 41.0]
end

@testitem "InputProfile rejects negative load" tags=[:unit, :validation] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 1)
    @test_throws ArgumentError InputProfile(t, [-0.1, 0.9], [25.0, 24.5])
end

@testitem "InputProfile rejects mismatched lengths" tags=[:unit, :validation] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 1)
    @test_throws ArgumentError InputProfile(t, [0.8], [25.0, 24.5])
end

@testitem "InputProfile rejects unsorted time" tags=[:unit, :validation] begin
    using Dates, TransformerThermalModel
    t = [DateTime(2024, 1, 1, 1), DateTime(2024, 1, 1, 0)]
    @test_throws ArgumentError InputProfile(t, [0.8, 0.9], [25.0, 24.5])
end

# ---------------------------------------------------------------------------
# ThreeWindingInputProfile
# ---------------------------------------------------------------------------

@testitem "ThreeWindingInputProfile construction" tags=[:unit, :fast] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 2)
    p = ThreeWindingInputProfile(
        t,
        [0.8, 0.9, 1.0],
        [0.7, 0.8, 0.9],
        [0.6, 0.7, 0.8],
        [25.0, 24.5, 24.0],
    )
    @test length(p.time) == 3
    @test p.top_oil === nothing
end

@testitem "ThreeWindingInputProfile rejects negative load" tags=[:unit, :validation] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 1)
    @test_throws ArgumentError ThreeWindingInputProfile(
        t,
        [-0.1, 0.9],
        [0.7, 0.8],
        [0.6, 0.7],
        [25.0, 24.5],
    )
end

# ---------------------------------------------------------------------------
# WindingSpec and ThreeWindingTransformer
# ---------------------------------------------------------------------------

@testitem "WindingSpec construction" tags=[:unit, :fast] begin
    using TransformerThermalModel
    w = WindingSpec(nom_load = 1000.0, nom_power = 10.0, g_r = 17.0, τ_w = 10.0, H = 1.3)
    @test w.nom_load == 1000.0
    @test w.H == 1.3
end

@testitem "ThreeWindingTransformer ONAN defaults" tags=[:unit, :fast] begin
    using TransformerThermalModel
    w = WindingSpec(nom_load = 1000.0, nom_power = 10.0, g_r = 20.0, τ_w = 5.0, H = 1.2)
    spec = ThreeWindingTransformer(
        no_load_loss = 20.0,
        lv_winding = w,
        mv_winding = w,
        hv_winding = w,
        load_loss_hv_lv = 100.0,
        load_loss_hv_mv = 100.0,
        load_loss_mv_lv = 100.0,
    )
    @test spec.τ_oil == 210.0
    @test spec.Δθ_or == 60.0
    @test spec.load_loss_total === nothing
end
