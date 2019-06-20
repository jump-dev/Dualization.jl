# """
# Add dual model with variables and dual cone constraints. 
# Creates dual variables => primal constraints dict
# """
# function get_primal_constraint_coeffs(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, con_types::Vector{Tuple{DataType, DataType}})
#     con_coeffs = Dict{CI, Tuple{Vector{Float64}, Float64}}()
#     (F, S) = con_types[1]
#     for (F, S) in con_types
#         num_con_f_s = MOI.get(primal_model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
#         for con_id = 1:num_con_f_s
#             fill_constraint_coefficients(con_coeffs, primal_model, F, S, con_id)
#             push!(dual_var_primal_con, vi => ci) # Fill the dual variables primal constraints dictionary
#             add_dualcone_constraint(dual_model, vi, F, S) # Add dual variable in dual cone constraint y \in C^*
#             i += 1
#         end
#     end
#     return dual_var_primal_con, con_coeffs
# end

# # Get scalar term of a constraint
# function get_scalar_term(model::MOI.ModelLike, con_id::Int,
#                          F::Type{SAF{T}}, S::Type{MOI.GreaterThan{T}}) where T
#     return get_function(model, F, S, con_id).constant - get_set(model, F, S, con_id).lower
# end

# function get_scalar_term(model::MOI.ModelLike, con_id::Int,
#                          F::Type{SAF{T}}, S::Type{MOI.LessThan{T}}) where T
#     return get_function(model, F, S, con_id).constant - get_set(model, F, S, con_id).upper
# end

# function get_scalar_term(model::MOI.ModelLike, con_id::Int,
#                          F::Type{SAF{T}}, S::Type{MOI.EqualTo{T}}) where T
#     return get_function(model, F, S, con_id).constant - get_set(model, F, S, con_id).value
# end

# function get_scalar_term(model::MOI.ModelLike, con_id::Int,
#                          F::Type{SVF}, S::Type{MOI.GreaterThan{T}}) where T
#     return - get_set(model, F, S, con_id).lower
# end

# function get_scalar_term(model::MOI.ModelLike, con_id::Int,
#                          F::Type{SVF}, S::Type{MOI.LessThan{T}}) where T
#     return - get_set(model, F, S, con_id).upper
# end

# function get_scalar_term(model::MOI.ModelLike, con_id::Int,
#                          F::Type{SVF}, S::Type{MOI.EqualTo{T}}) where T
#     return - get_set(model, F, S, con_id).value
# end

# function get_scalar_term(model::MOI.ModelLike, con_id::Int,
#                          F::Type{VAF{T}}, S::Union{Type{MOI.Nonnegatives},
#                                                    Type{MOI.Nonpositives},
#                                                    Type{MOI.Zeros}}) where T
#     return get_function(model, F, S, con_id).constants
# end



# function fillAi(Ai::Vector{T}, saf::SAF{T}) where T
#     for term in saf.terms
#         Ai[term.variable_index.value] = term.coefficient #Fill Ai
#     end
#     return nothing
# end

# function fillAi(Ai::Vector{T}, svf::SVF) where T
#     Ai[svf.variable.value] = 1 #Fill Ai
#     return nothing
# end

# # SAF
# function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
#                                       ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T

#     # Create zeros vector for Ai terms
#     Ai = zeros(Float64, model.num_variables_created)
#     con = model.moi_scalaraffinefunction.moi_greaterthan[con_id] # Get constraint informations

#     # Access constraint information
#     ci          = con[1]
#     saf         = con[2] # Access the SAF
#     greaterthan = con[3] # Access the GreatherThan set

#     # Fill Ai
#     fillAi(Ai, saf)
#     # Considering ax + b >= l should be interpreted as ax + b - l in R_+
#     # the term bi should be b - l
#     bi = saf.constant - greaterthan.lower # Fill bi
#     return push!(dict_coeffs, ci => (Ai, bi)) 
# end

# function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
#                                       ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T

#     # Create zeros vector for Ai terms
#     Ai = zeros(Float64, model.num_variables_created)
#     con = model.moi_scalaraffinefunction.moi_lessthan[con_id] # Get constraint informations

#     # Access constraint information
#     ci       = con[1]
#     saf      = con[2] # Access the SAF
#     lessthan = con[3] # Access the LessThan set

#     # Fill Ai
#     fillAi(Ai, saf)
#     # Considering ax + b <= u should be interpreted as ax + b - u in R_-
#     # the term bi should be b - u
#     bi = saf.constant - lessthan.upper # Fill bi
#     return push!(dict_coeffs, ci => (Ai, bi)) 
# end

# function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
#                                       ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T

#     # Create zeros vector for Ai terms
#     Ai = zeros(Float64, model.num_variables_created)
#     con = model.moi_scalaraffinefunction.moi_equalto[con_id] # Get constraint informations

#     # Access constraint information
#     ci      = con[1]
#     saf     = con[2] # Access the SAF
#     equalto = con[3] # Access the EqualTo set

#     # Fill Ai
#     fillAi(Ai, saf)
#     # Considering ax + b == v should be interpreted as ax + b - v in Zeros
#     # the term bi should be b - v
#     bi = saf.constant - equalto.value # Fill bi
#     return push!(dict_coeffs, ci => (Ai, bi)) 
# end


# # SVF
# function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
#                                       ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T

#     # Create zeros vector for Ai terms
#     Ai = zeros(Float64, model.num_variables_created)
#     con = model.moi_singlevariable.moi_greaterthan[con_id] # Get constraint informations

#     # Access constraint information
#     ci          = con[1]
#     svf         = con[2] # Access the SVF
#     greaterthan = con[3] # Access the GreatherThan set

#     # Fill Ai
#     fillAi(Ai, svf)
#     # Considering x >= l should be interpreted as x - c in R_+
#     # the term bi should be - l
#     bi =  - greaterthan.lower # Fill bi
#     return push!(dict_coeffs, ci => (Ai, bi)) 
# end

# function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
#                                       ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T

#     # Create zeros vector for Ai terms
#     Ai = zeros(Float64, model.num_variables_created)
#     con = model.moi_singlevariable.moi_lessthan[con_id] # Get constraint informations

#     # Access constraint information
#     ci       = con[1]
#     svf      = con[2] # Access the SVF
#     lessthan = con[3] # Access the LessThan set

#     # Fill Ai
#     fillAi(Ai, svf)
#     # Considering x <= u should be interpreted as x - u in R_-
#     # the term bi should be - u
#     bi =  - lessthan.upper # Fill bi
#     return push!(dict_coeffs, ci => (Ai, bi)) 
# end

# function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
#                                       ::Type{SVF}, ::Type{MOI.EqualTo{T}}, con_id::Int) where T

#     # Create zeros vector for Ai terms
#     Ai = zeros(Float64, model.num_variables_created)
#     con = model.moi_singlevariable.moi_equalto[con_id] # Get constraint informations

#     # Access constraint information
#     ci      = con[1]
#     svf     = con[2] # Access the SVF
#     equalto = con[3] # Access the EqualTo set

#     # Fill Ai
#     fillAi(Ai, svf)
#     # Considering x == v should be interpreted as x - v in Zeros
#     # the term bi should be - v
#     bi =  - equalto.value # Fill bi
#     return push!(dict_coeffs, ci => (Ai, bi)) 
# end