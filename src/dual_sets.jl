export dual_set

# Additional dual_set
function MOI.dual_set(::MOI.GreaterThan{T}) where T
    return MOI.GreaterThan(zero(T))
end
function MOI.dual_set_type(::Type{MOI.GreaterThan{T}}) where T
    return MOI.GreaterThan{T}
end

function MOI.dual_set(::MOI.LessThan{T}) where T
    return MOI.LessThan(zero(T))
end
function MOI.dual_set_type(::Type{MOI.LessThan{T}}) where T
    return MOI.GreaterThan{T}
end

function MOI.dual_set(::MOI.EqualTo{T}) where T
    return # Maybe return Reals in the future
end
function MOI.dual_set_type(::Type{<:MOI.EqualTo})
    return MOI.Reals
end
