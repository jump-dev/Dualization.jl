"""
Docs here
"""
function dual_set end

# This should be putted in MOIU and used for Dualization later
function dual_set(s::MOI.GreaterThan{T}) where T
    return MOI.GreaterThan(zero(T))
end

function dual_set(s::MOI.LessThan{T}) where T
    return MOI.LessThan(zero(T))
end

function dual_set(s::MOI.EqualTo{T}) where T
    return # Maybe return Reals in the future
end

function dual_set(s::MOI.Nonpositives)
    return MOI.Nonpositives(MOI.dimension(s))
end

function dual_set(s::MOI.Nonnegatives)
    return MOI.Nonnegatives(MOI.dimension(s))
end

function dual_set(s::MOI.Zeros)
    return # Maybe return Reals in the future
end

function dual_set(s::MOI.SecondOrderCone)
    return MOI.SecondOrderCone(MOI.dimension(s))
end

function dual_set(s::MOI.RotatedSecondOrderCone)
    return MOI.RotatedSecondOrderCone(MOI.dimension(s))
end