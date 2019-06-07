# SAF
function fillAi(Ai::Vector{T}, saf::SAF{T}) where T
    for term in saf.terms
        Ai[term.variable_index.value] = term.coefficient #Fill Ai
    end
end

function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
                                      ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T

    # Create zeros vector for Ai terms
    Ai = zeros(Float64, model.num_variables_created)
    constr = model.moi_scalaraffinefunction.moi_greaterthan[con_id] # Get constraint informations

    # Access constraint information
    ci          = constr[1]
    saf         = constr[2] # Access the SAF
    greaterthan = constr[3] # Access the GreatherThan set

    # Fill Ai
    fillAi(Ai, saf)
    # Considering ax + b >= l should be interpreted as ax + b - l in R_+
    # the term bi should be b - l
    bi = saf.constant - greaterthan.lower # Fill bi
    return push!(dict_coeffs, ci => (Ai, bi)) # return ConstraintIndex
end

function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
                                      ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T

    # Create zeros vector for Ai terms
    Ai = zeros(Float64, model.num_variables_created)
    constr = model.moi_scalaraffinefunction.moi_lessthan[con_id] # Get constraint informations

    # Access constraint information
    ci       = constr[1]
    saf      = constr[2] # Access the SAF
    lessthan = constr[3] # Access the GreatherThan set

    # Fill Ai
    fillAi(Ai, saf)
    # Considering ax + b <= u should be interpreted as ax + b - u in R_-
    # the term bi should be b - u
    bi = saf.constant - lessthan.upper # Fill bi
    return push!(dict_coeffs, ci => (Ai, bi)) # return ConstraintIndex
end

function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
                                      ::Type{SVF}, ::Type{MOI.LessThan{T}}, con_id::Int) where T

    # Create zeros vector for Ai terms
    Ai = zeros(Float64, model.num_variables_created)
    constr = model.moi_singlevariable.moi_lessthan[con_id] # Get constraint informations

    # Access constraint information
    ci       = constr[1]
    svf      = constr[2] # Access the SVF
    lessthan = constr[3] # Access the GreatherThan set

    # Fill Ai
    Ai[svf.variable.value] = 1 #Fill Ai
    # Considering x <= u should be interpreted as x - u in R_-
    # the term bi should be - u
    bi =  - lessthan.upper # Fill bi
    return push!(dict_coeffs, ci => (Ai, bi)) # return ConstraintIndex
end

function fill_constraint_coefficients(dict_coeffs::Dict, model::MOI.ModelLike,
                                      ::Type{SVF}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T

    # Create zeros vector for Ai terms
    Ai = zeros(Float64, model.num_variables_created)
    constr = model.moi_singlevariable.moi_greaterthan[con_id] # Get constraint informations

    # Access constraint information
    ci          = constr[1]
    svf         = constr[2] # Access the SVF
    greaterthan = constr[3] # Access the GreatherThan set

    # Fill Ai
    Ai[svf.variable.value] = 1 #Fill Ai
    # Considering x >= l should be interpreted as x - c in R_+
    # the term bi should be - l
    bi =  - greaterthan.lower # Fill bi
    return push!(dict_coeffs, ci => (Ai, bi)) # return ConstraintIndex
end