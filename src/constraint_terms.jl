function fill_constraint_terms(Ai::Matrix{T}, bi::Vector{T}, model::MOI.ModelLike,
                              ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}, con_id::Int) where T

    # Get constraint as per con_id
    constr = model.moi_scalaraffinefunction.moi_greaterthan[con_id]
    saf = constr[2] # Access the SAF
    greaterthan = constr[3] # Access the GreatherThan set
    for term in saf.terms
        Ai[term.variable_index.value, con_id] = term.coefficient #Fill Ai
    end
    # Considering ax + b >= c should be interpreted as ax + b - c in R_+
    # the term bi should be b - c
    bi[con_id] = saf.constant - greaterthan.lower # Fill bi
    return 
end

function fill_constraint_terms(Ai::Matrix{T}, bi::Vector{T}, model::MOI.ModelLike,
                              ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}, con_id::Int) where T

    # Get constraint as per con_id
    constr = model.moi_scalaraffinefunction.moi_lessthan[con_id]
    saf = constr[2] # Access the SAF
    lessthan = constr[3] # Access the LessThan set
    for term in saf.terms
        Ai[term.variable_index.value, con_id] = term.coefficient #Fill Ai
    end
    # Considering ax + b <= c should be interpreted as ax + b - c in R_-
    # the term bi should be b - c
    bi[con_id] = saf.constant - lessthan.upper
    return 
end