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




# Functions to get the Function 
function get_function(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_greaterthan[con_id][2]
end

function get_function(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_lessthan[con_id][2]
end

function get_function(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_equalto[con_id][2]
end

function get_function(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_greaterthan[con_id][2]
end

function get_function(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_lessthan[con_id][2]
end

function get_function(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_equalto[con_id][2]
end

function get_function(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Nonpositives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonpositives[con_id][2]
end

function get_function(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Nonnegatives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonnegatives[con_id][2]
end

function get_function(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Zeros}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_zeros[con_id][2]
end




# Functions to get the Set
function get_set(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_greaterthan[con_id][3]
end

function get_set(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_lessthan[con_id][3]
end

function get_set(model::MOI.ModelLike, ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_equalto[con_id][3]
end

function get_set(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_greaterthan[con_id][3]
end

function get_set(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_lessthan[con_id][3]
end

function get_set(model::MOI.ModelLike, ::Type{SVF}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_equalto[con_id][3]
end

function get_set(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Nonpositives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonpositives[con_id][3]
end

function get_set(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Nonnegatives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonnegatives[con_id][3]
end

function get_set(model::MOI.ModelLike, ::Type{VAF{T}}, ::Type{MOI.Zeros}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_zeros[con_id][3]
end



# Functions to get the dimension of a constraint
function get_ci_row_dimension(model::MOI.ModelLike, F::Type{VAF{T}}, S::Type{MOI.Nonpositives}, con_id::Int) where T
    return MOI.output_dimension(get_function(model, F, S, con_id))
end

function get_ci_row_dimension(model::MOI.ModelLike, F::Type{VAF{T}}, S::Type{MOI.Nonnegatives}, con_id::Int) where T
    return MOI.output_dimension(get_function(model, F, S, con_id))
end

function get_ci_row_dimension(model::MOI.ModelLike, F::Type{VAF{T}}, S::Type{MOI.Zeros}, con_id::Int) where T
    return MOI.output_dimension(get_function(model, F, S, con_id))
end