# We define `_dual_set` instead as adding methods for `MOI.dual_set` on MOI sets is type piracy.
_dual_set(set::MOI.AbstractSet) = MOI.dual_set(set)
function _dual_set_type(S::Type)
    return try
        MOI.dual_set_type(S)
    catch
        return nothing # The fallback of `dual_set_type` throws an error.
    end
end

function _dual_set(::MOI.GreaterThan{T}) where {T}
    return MOI.GreaterThan(zero(T))
end
function _dual_set_type(::Type{MOI.GreaterThan{T}}) where {T}
    return MOI.GreaterThan{T}
end

function _dual_set(::MOI.LessThan{T}) where {T}
    return MOI.LessThan(zero(T))
end
function _dual_set_type(::Type{MOI.LessThan{T}}) where {T}
    return MOI.GreaterThan{T}
end

function _dual_set(::MOI.EqualTo{T}) where {T}
    return # Maybe return Reals in the future
end
function _dual_set_type(::Type{<:MOI.EqualTo})
    return MOI.Reals
end
