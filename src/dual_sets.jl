# This should be putted in MOIU and used for Dualization later
function dual_function_in_set(F::MOI.AbstractFunction, S::MOI.AbstractSet)
    return _dual_set(F, S)
end

function _dual_set(F::SAF{T}, S::MOI.GreaterThan) where T
    return MOI.GreaterThan(zero(T))
end

function _dual_set(F::SAF{T}, S::MOI.LessThan{T}) where T
    return MOI.LessThan(zero(T))
end

function _dual_set(F::SAF{T}, S::MOI.EqualTo) where T
    return # Reals ?
end