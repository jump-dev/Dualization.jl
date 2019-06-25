"""
    set_dualmodel_sense!(dual_model::AbstractModel{T}, model::AbstractModel{T})

Set the dual model objective sense
"""
function set_dual_model_sense(dual_model::AbstractModel{T}, primal_model::AbstractModel{T}) where T
    # Get model sense
    primal_sense = MOI.get(primal_model, MOI.ObjectiveSense())
    if primal_sense == MOI.FEASIBILITY_SENSE
        error(primal_sense, " is not supported") # Feasibility should be supported?
    end
    # Set dual model sense
    dual_sense = (primal_sense == MOI.MIN_SENSE) ? MOI.MAX_SENSE : MOI.MIN_SENSE
    MOI.set(dual_model, MOI.ObjectiveSense(), dual_sense)
    return 
end

# Primals
"""
        PrimalObjectiveCoefficients{T}

Primal objective coefficients defined as ``a_0^Tx + b_0`` as in
http://www.juliaopt.org/MathOptInterface.jl/stable/apimanual/#Advanced-1
"""
struct PrimalObjective{T}
    saf::SAF{T}
end

"""
    get_primal_obj_coeffs(model::AbstractModel{T})

Get the coefficients from the primal objective function and
return a `PrimalObjectiveCoefficients{T}`
"""
function get_primal_objective(primal_model::AbstractModel{T}) where T
    return _get_primal_objective(primal_model.objective)
end

function _get_primal_objective(obj_fun::SAF{T}) where T
    return PrimalObjective(obj_fun)
end

function _get_primal_objective(obj_fun::SVF)
    a0 = [1.0] # Equals one on the SingleVariableFunction
    vi = [obj_fun.variable]
    b0 = 0.0 # SVF has no b0
    saf = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(a0, vi), b0)
    return PrimalObjective(saf)
end

# You can add other generic _get_primal_obj_coeffs functions here


# Duals
"""
        DualObjectiveCoefficients{T}

Dual objective coefficients defined as ``b_i^Ty + b_0`` or ``-b_i^Ty + b_0`` as in
http://www.juliaopt.org/MathOptInterface.jl/stable/apimanual/#Advanced-1
"""
struct DualObjective{T}
    saf::SAF{T}
end

"""
        set_DOC(dual_model::AbstractModel{T}, doc::DualObjectiveCoefficients{T}) where T

Add the objective function to the dual model
"""
function set_dual_objective(dual_model::AbstractModel{T}, dual_objective::DualObjective{T}) where T
    # Set dual model objective function
    MOI.set(dual_model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),  
            dual_objective.saf)
    return 
end

"""
        get_dual_obj_coeffs(dual_model::AbstractModel{T}, dict_constr_coeffs::Dict, 
                            dict_dualvar_primalcon::Dict, poc::POC{T}) where T

Get dual model objective function coefficients
"""
function get_dual_objective(dual_model::AbstractModel{T}, dual_obj_affine_terms::Dict,
                            primal_objective::PrimalObjective{T}) where T

    sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense

    num_objective_terms = length(dual_obj_affine_terms)
    term_vec = Vector{T}(undef, num_objective_terms)
    vi_vec   = Vector{VI}(undef, num_objective_terms)
    i::Int = 1
    for var in keys(dual_obj_affine_terms) # Number of constraints of the primal model
        term = dual_obj_affine_terms[var]
        # Add positive terms bi if dual model sense is max
        term_vec[i] = (sense == MOI.MAX_SENSE ? -1 : 1) * term
        # Variable index associated with term bi
        vi_vec[i] = var
        i += 1
    end
    saf_dual_objective = MOI.ScalarAffineFunction(
                         MOI.ScalarAffineTerm.(term_vec, 
                                               vi_vec), 
                                               primal_objective.saf.constant)
    return DualObjective{T}(saf_dual_objective)
end