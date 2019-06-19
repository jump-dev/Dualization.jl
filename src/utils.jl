# Functions to get constraint index
function get_ci(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_greaterthan[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_lessthan[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_equalto[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_greaterthan[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_lessthan[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_equalto[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Nonpositives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonpositives[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Nonnegatives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonnegatives[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Zeros}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_zeros[con_id][1]
end

function get_ci_row_dimension(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Nonpositives}, con_id::Int) where T
    return MOI.output_dimension(model.moi_vectoraffinefunction.moi_nonpositives[con_id][2])
end

function get_ci_row_dimension(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Nonnegatives}, con_id::Int) where T
    return MOI.output_dimension(model.moi_vectoraffinefunction.moi_nonnegatives[con_id][2])
end

function get_ci_row_dimension(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Zeros}, con_id::Int) where T
    return MOI.output_dimension(model.moi_vectoraffinefunction.moi_zeros[con_id][2])
end