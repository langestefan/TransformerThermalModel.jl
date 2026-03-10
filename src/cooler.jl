# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

"""Cooling type of a transformer (IEC 60076-7).

- `ONAN`: Oil Natural Air Natural — oil and air cooled by natural convection.
- `ONAF`: Oil Natural Air Forced — oil by natural convection, air by forced convection.
"""
@enum CoolerType begin
    ONAN
    ONAF
end

"""Winding insulation paper type (IEC 60076-7).

- `NormalPaper`: Reference hot-spot temperature 98 °C (aging rate = 1 day/day).
- `ThermallyUpgradedPaper`: Reference hot-spot temperature 110 °C (aging rate = 1 day/day).
"""
@enum PaperInsulationType begin
    NormalPaper
    ThermallyUpgradedPaper
end
