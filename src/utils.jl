# Functions to get constraint index
function get_ci(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_greaterthan[con_id][1]
end

function get_ci(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_lessthan[con_id][1]
end

function get_ci(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_equalto[con_id][1]
end

function get_ci(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_greaterthan[con_id][1]
end

function get_ci(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_lessthan[con_id][1]
end

function get_ci(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_equalto[con_id][1]
end

function get_ci(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Nonpositives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonpositives[con_id][1]
end

function get_ci(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Nonnegatives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonnegatives[con_id][1]
end

function get_ci(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Zeros}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_zeros[con_id][1]
end




# Functions to get the Function 
function get_function(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_greaterthan[con_id][2]
end

function get_function(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_lessthan[con_id][2]
end

function get_function(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_equalto[con_id][2]
end

function get_function(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_greaterthan[con_id][2]
end

function get_function(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_lessthan[con_id][2]
end

function get_function(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_equalto[con_id][2]
end

function get_function(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Nonpositives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonpositives[con_id][2]
end

function get_function(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Nonnegatives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonnegatives[con_id][2]
end

function get_function(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Zeros}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_zeros[con_id][2]
end




# Functions to get the Set
function get_set(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_greaterthan[con_id][3]
end

function get_set(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_lessthan[con_id][3]
end

function get_set(model::AbstractModel{T}, ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_scalaraffinefunction.moi_equalto[con_id][3]
end

function get_set(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_greaterthan[con_id][3]
end

function get_set(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_lessthan[con_id][3]
end

function get_set(model::AbstractModel{T}, ::Type{SVF}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T
    return model.moi_singlevariable.moi_equalto[con_id][3]
end

function get_set(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Nonpositives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonpositives[con_id][3]
end

function get_set(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Nonnegatives}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_nonnegatives[con_id][3]
end

function get_set(model::AbstractModel{T}, ::Type{VAF{T}}, ::Type{MOI.Zeros}, con_id::Int) where T
    return model.moi_vectoraffinefunction.moi_zeros[con_id][3]
end



# Functions to get the dimension of a constraint
function get_ci_row_dimension(model::AbstractModel{T}, F::Type{VAF{T}}, S::Type{MOI.Nonpositives}, con_id::Int) where T
    return MOI.output_dimension(get_function(model, F, S, con_id))
end

function get_ci_row_dimension(model::AbstractModel{T}, F::Type{VAF{T}}, S::Type{MOI.Nonnegatives}, con_id::Int) where T
    return MOI.output_dimension(get_function(model, F, S, con_id))
end

function get_ci_row_dimension(model::AbstractModel{T}, F::Type{VAF{T}}, S::Type{MOI.Zeros}, con_id::Int) where T
    return MOI.output_dimension(get_function(model, F, S, con_id))
end



# Functions to get scalar terms of a Function - in- Set
function get_scalar_term(model::AbstractModel{T}, con_id::Int,
                         F::Type{SAF{T}}, S::Type{MOI.GreaterThan{T}}) where T
    return get_function(model, F, S, con_id).constant - get_set(model, F, S, con_id).lower
end

function get_scalar_term(model::AbstractModel{T}, con_id::Int,
                         F::Type{SAF{T}}, S::Type{MOI.LessThan{T}}) where T
    return get_function(model, F, S, con_id).constant - get_set(model, F, S, con_id).upper
end

function get_scalar_term(model::AbstractModel{T}, con_id::Int,
                         F::Type{SAF{T}}, S::Type{MOI.EqualTo{T}}) where T
    return get_function(model, F, S, con_id).constant - get_set(model, F, S, con_id).value
end

function get_scalar_term(model::AbstractModel{T}, con_id::Int,
                         F::Type{SVF}, S::Type{MOI.GreaterThan{T}}) where T
    return - get_set(model, F, S, con_id).lower
end

function get_scalar_term(model::AbstractModel{T}, con_id::Int,
                         F::Type{SVF}, S::Type{MOI.LessThan{T}}) where T
    return - get_set(model, F, S, con_id).upper
end

function get_scalar_term(model::AbstractModel{T}, con_id::Int,
                         F::Type{SVF}, S::Type{MOI.EqualTo{T}}) where T
    return - get_set(model, F, S, con_id).value
end

function get_scalar_term(model::AbstractModel{T}, con_id::Int,
                         F::Type{VAF{T}}, S::Union{Type{MOI.Nonnegatives},
                                                   Type{MOI.Nonpositives},
                                                   Type{MOI.Zeros}}) where T
    return get_function(model, F, S, con_id).constants
end