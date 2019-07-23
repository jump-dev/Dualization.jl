"""
    set_dualmodel_sense!(dual_model::MOI.ModelLike, model::MOI.ModelLike)

Set the dual model objective sense
"""
function set_dual_model_sense(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike)::Nothing where T
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

    function PrimalObjective{T}(obj::SAF{T}) where T
        canonical_obj = MOIU.canonical(obj)
        if isempty(canonical_obj.terms)
            error("Dualization does not support models with no variables in the objective function.")
        end
        return new(canonical_obj)
    end
end

# Duals
"""
    DualObjectiveCoefficients{T}

Dual objective coefficients defined as ``b_i^Ty + b_0`` or ``-b_i^Ty + b_0`` as in
http://www.juliaopt.org/MathOptInterface.jl/stable/apimanual/#Advanced-1
"""
struct DualObjective{T}
    saf::SAF{T}
end

function get_saf(objective::Union{PrimalObjective{T}, DualObjective{T}})::SAF{T} where T
    return objective.saf
end

"""
    get_primal_obj_coeffs(model::MOI.ModelLike)

Get the coefficients from the primal objective function and
return a `PrimalObjectiveCoefficients{T}`
"""
function get_primal_objective(primal_model::MOI.ModelLike)
    T = MOI.get(primal_model, MOI.ObjectiveFunctionType())
    return _get_primal_objective(MOI.get(primal_model, MOI.ObjectiveFunction{T}()))
end

function _get_primal_objective(obj_fun::SAF{T}) where T
    return PrimalObjective{T}(obj_fun)
end

# Float64 is default while I don't know how to take other types
_get_primal_objective(obj_fun::SVF) = _get_primal_objective(obj_fun, Float64)
function _get_primal_objective(obj_fun::SVF, T::DataType)
    return PrimalObjective{T}(SAF{T}(obj_fun))
end

# You can add other generic _get_primal_obj_coeffs functions here



"""
    set_DOC(dual_model::MOI.ModelLike, doc::DualObjectiveCoefficients{T}) where T

Add the objective function to the dual model
"""
function set_dual_objective(dual_model::MOI.ModelLike, dual_objective::DualObjective{T})::Nothing where T
    # Set dual model objective function
    MOI.set(dual_model, MOI.ObjectiveFunction{SAF{T}}(),  
            get_saf(dual_objective))
    return 
end

"""
    get_dual_obj_coeffs(dual_model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                            dict_dualvar_primalcon::Dict, poc::POC{T}) where T

Get dual model objective function coefficients
"""
function get_dual_objective(dual_model::MOI.ModelLike, dual_obj_affine_terms::Dict,
                            primal_objective::PrimalObjective{T})::DualObjective{T} where T

    sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense

    num_objective_terms = length(dual_obj_affine_terms)
    term_vec = Vector{T}(undef, num_objective_terms)
    vi_vec   = Vector{VI}(undef, num_objective_terms)
    for (i, var) in enumerate(keys(dual_obj_affine_terms)) # Number of constraints of the primal model
        term = dual_obj_affine_terms[var]
        # Add positive terms bi if dual model sense is max
        term_vec[i] = (sense == MOI.MAX_SENSE ? -1 : 1) * term
        # Variable index associated with term bi
        vi_vec[i] = var
    end
    saf_dual_objective = MOI.ScalarAffineFunction(
                         MOI.ScalarAffineTerm.(term_vec, 
                                               vi_vec), 
                                               MOI._constant(get_saf(primal_objective)))
    return DualObjective{T}(saf_dual_objective)
end