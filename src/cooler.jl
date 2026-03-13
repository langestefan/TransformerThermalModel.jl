"""Types related to cooling and insulation of transformers."""

"""Cooling type of a transformer (IEC 60076-7)."""
abstract type CoolerType end

"""ONAN: Oil Natural Air Natural — oil and air cooled by natural convection."""
struct ONAN <: CoolerType end

"""ONAF: Oil Natural Air Forced — oil by natural convection, air by forced convection."""
struct ONAF <: CoolerType end

"""Winding insulation paper type (IEC 60076-7)."""
abstract type PaperInsulationType end

"""NormalPaper: Reference hot-spot temperature 98 °C (aging rate = 1 day/day)."""
struct NormalPaper <: PaperInsulationType end

"""ThermallyUpgradedPaper: Reference hot-spot temperature 110 °C (aging rate = 1 day/day)."""
struct ThermallyUpgradedPaper <: PaperInsulationType end
