# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

# ---------------------------------------------------------------------------
# CoolerType
# ---------------------------------------------------------------------------

@testitem "CoolerType enum values" tags = [:unit, :fast] begin
    using TransformerThermalModel
    @test instances(CoolerType) == (ONAN, ONAF)
end

# ---------------------------------------------------------------------------
# PaperInsulationType
# ---------------------------------------------------------------------------

@testitem "PaperInsulationType enum values" tags = [:unit, :fast] begin
    using TransformerThermalModel
    @test instances(PaperInsulationType) == (NormalPaper, ThermallyUpgradedPaper)
end

# ---------------------------------------------------------------------------
# InitialState
# ---------------------------------------------------------------------------

@testitem "InitialState subtypes" tags = [:unit, :fast] begin
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

@testitem "InputProfile construction" tags = [:unit, :fast] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 2)
    p = InputProfile(t, [0.8, 0.9, 1.0], [25.0, 24.5, 24.0])
    @test length(p.time) == 3
    @test p.load == [0.8, 0.9, 1.0]
    @test p.ambient == [25.0, 24.5, 24.0]
    @test p.top_oil === nothing
end

@testitem "InputProfile with top_oil" tags = [:unit, :fast] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 1)
    p = InputProfile(t, [0.8, 0.9], [25.0, 24.5], [40.0, 41.0])
    @test p.top_oil == [40.0, 41.0]
end

@testitem "InputProfile rejects negative load" tags = [:unit, :validation] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 1)
    @test_throws ArgumentError InputProfile(t, [-0.1, 0.9], [25.0, 24.5])
end

@testitem "InputProfile rejects mismatched lengths" tags = [:unit, :validation] begin
    using Dates, TransformerThermalModel
    t = DateTime(2024, 1, 1):Hour(1):DateTime(2024, 1, 1, 1)
    @test_throws ArgumentError InputProfile(t, [0.8], [25.0, 24.5])
end

@testitem "InputProfile rejects unsorted time" tags = [:unit, :validation] begin
    using Dates, TransformerThermalModel
    t = [DateTime(2024, 1, 1, 1), DateTime(2024, 1, 1, 0)]
    @test_throws ArgumentError InputProfile(t, [0.8, 0.9], [25.0, 24.5])
end

# ---------------------------------------------------------------------------
# ThreeWindingInputProfile
# ---------------------------------------------------------------------------

@testitem "ThreeWindingInputProfile construction" tags = [:unit, :fast] begin
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

@testitem "ThreeWindingInputProfile rejects negative load" tags = [:unit, :validation] begin
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
