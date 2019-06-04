function fill_constraint_terms(dict_coeffs::Dict, model::MOI.ModelLike,
                              ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T

    # Create zeros vector for Ai terms
    Ai = zeros(Float64, model.num_variables_created)
    constr = model.moi_scalaraffinefunction.moi_greaterthan[con_id] # Get constraint informations

    # Access constraint information
    ci          = constr[1]
    saf         = constr[2] # Access the SAF
    greaterthan = constr[3] # Access the GreatherThan set

    # Fill Ai
    for term in saf.terms
        Ai[term.variable_index.value] = term.coefficient #Fill Ai
    end
    # Considering ax + b >= c should be interpreted as ax + b - c in R_+
    # the term bi should be b - c
    bi = saf.constant - greaterthan.lower # Fill bi
    return push!(dict_coeffs, ci => (Ai, bi)) # return ConstraintIndex
end

function fill_constraint_terms(dict_coeffs::Dict, model::MOI.ModelLike,
                               ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T

    # Create zeros vector for Ai terms
    Ai = zeros(Float64, model.num_variables_created)
    constr = model.moi_scalaraffinefunction.moi_lessthan[con_id] # Get constraint informations

    # Access constraint information
    ci          = constr[1]
    saf         = constr[2] # Access the SAF
    greaterthan = constr[3] # Access the GreatherThan set

    # Fill Ai
    for term in saf.terms
        Ai[term.variable_index.value] = term.coefficient #Fill Ai
    end
    # Considering ax + b <= c should be interpreted as ax + b - c in R_-
    # the term bi should be b - c
    bi = saf.constant - greaterthan.upper # Fill bi
    return push!(dict_coeffs, ci => (Ai, bi)) # return ConstraintIndex
end