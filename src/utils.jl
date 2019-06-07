# Functions to get constraint index
function get_ci(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    model.moi_scalaraffinefunction.moi_greaterthan[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    model.moi_scalaraffinefunction.moi_lessthan[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    model.moi_scalaraffinefunction.moi_equalto[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    model.moi_singlevariable.moi_greaterthan[con_id][1]
end

function get_ci(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    model.moi_singlevariable.moi_lessthan[con_id][1]
end