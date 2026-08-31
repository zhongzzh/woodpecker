mutable struct WCOptions
    ULevel::Real
    Display::Bool
    VaryUncertainty::Bool
    VaryFrequency::Bool
    Sensitivity::Bool
    SensitivityPercent::Real
    MussvOptions::String
end

function WCOptions(
    ULevel::Real,
    Display::Bool,
    VaryUncertainty::Bool,
    Sensitivity::Bool,
    SensitivityPercent::Real,
    MussvOptions::String,
)
    return WCOptions(
        ULevel,
        Display,
        VaryUncertainty,
        false,
        Sensitivity,
        SensitivityPercent,
        MussvOptions,
    )
end

function wcOptions(;
    ULevel::Real=1,
    Display::Bool=false,
    VaryUncertainty::Bool=false,
    VaryFrequency::Bool=false,
    Sensitivity::Bool=false,
    SensitivityPercent::Real=25,
    MussvOptions::String="",
)
    return WCOptions(
        ULevel,
        Display,
        VaryUncertainty,
        VaryFrequency,
        Sensitivity,
        SensitivityPercent,
        MussvOptions,
    )
end
