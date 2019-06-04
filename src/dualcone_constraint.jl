function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}) where T
    return MOI.add_constraint(dualmodel, SVF(vi), MOI.GreaterThan(0.0))
end

function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}) where T
    return MOI.add_constraint(dualmodel, SVF(vi), MOI.LessThan(0.0))
end

function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}) where T
    return # No constraint
end
