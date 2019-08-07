"""
    dual_set(s::MOI.AbstractSet) -> MOI.AbstractSet

Returns the dual set of `s`.
"""
function dual_set end

# This should be putted in MOIU and used for Dualization later
function dual_set(::MOI.GreaterThan{T}) where T
    return MOI.GreaterThan(zero(T))
end

function dual_set(::MOI.LessThan{T}) where T
    return MOI.LessThan(zero(T))
end

function dual_set(::MOI.EqualTo{T}) where T
    return # Maybe return Reals in the future
end

function dual_set(s::MOI.Nonpositives)
    return copy(s) # The set is self-dual
end

function dual_set(s::MOI.Nonnegatives)
    return copy(s) # The set is self-dual
end

function dual_set(::MOI.Zeros)
    return # Maybe return Reals in the future
end

function dual_set(s::MOI.SecondOrderCone)
    return copy(s) # The set is self-dual
end

function dual_set(s::MOI.RotatedSecondOrderCone)
    return copy(s) # The set is self-dual
end

function dual_set(s::MOI.PositiveSemidefiniteConeTriangle)
    return copy(s) # The set is self-dual
end

function dual_set(::MOI.ExponentialCone)
    return MOI.DualExponentialCone()
end

function dual_set(::MOI.DualExponentialCone)
    return MOI.ExponentialCone()
end

function dual_set(s::MOI.PowerCone)
    return MOI.DualPowerCone(s.exponent)
end

function dual_set(s::MOI.DualPowerCone)
    return MOI.PowerCone(s.exponent)
end
