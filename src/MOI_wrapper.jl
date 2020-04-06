export DualOptimizer, dual_optimizer

dual_optimizer(optimizer_constructor) = () -> DualOptimizer(MOI.instantiate(optimizer_constructor))

struct DualOptimizer{T, OT <: MOI.ModelLike} <: MOI.AbstractOptimizer
    dual_problem::DualProblem{T, OT}

    function DualOptimizer{T, OT}(dual_problem::DualProblem{T, OT}) where {T, OT <: MOI.ModelLike}
        return new{T, OT}(dual_problem)
    end
end

"""
    DualOptimizer(dual_optimizer::OT) where {OT <: MOI.ModelLike}

The DualOptimizer finds the solution for a problem by solving its dual representation.
It builds the dual model internally and solve it using the `dual_optimizer` as solver.
Primal results are obtained by querying dual results of the internal problem solved
by `dual_optimizer`. Analogously, dual results are obtained by querying primal results
of the internal problem.

The user can define the model providing the `DualOptimizer` and the solver of its choice.

Example:

```julia
julia> using Dualization, JuMP, GLPK

julia> model = Model(dual_optimizer(GLPK.Optimizer))
A JuMP Model
Feasibility problem with:
Variables: 0
Model mode: AUTOMATIC
CachingOptimizer state: EMPTY_OPTIMIZER
Solver name: Dual model with GLPK attached
```
"""
function DualOptimizer(dual_optimizer::OT) where {OT <: MOI.ModelLike}
    return DualOptimizer{Float64}(dual_optimizer)
end

function DualOptimizer{T}(dual_optimizer::OT) where {T, OT <: MOI.ModelLike}
    dual_problem = DualProblem{T}(MOIB.full_bridge_optimizer(MOIU.CachingOptimizer(MOIU.UniversalFallback(DualizableModel{T}()), dual_optimizer), T))
    # discover the type of MOIU.CachingOptimizer(DualizableModel{T}(), dual_optimizer)
    OptimizerType = typeof(dual_problem.dual_model)
    return DualOptimizer{T, OptimizerType}(dual_problem)
end

function DualOptimizer()
    return error("DualOptimizer must have a solver attached")
end

function MOI.supports(::DualOptimizer,
                      ::MOI.ObjectiveSense)
    return true
end
function MOI.supports(optimizer::DualOptimizer{T},
                      ::MOI.ObjectiveFunction{F}) where {T, F}
    # If the objective function is `MOI.SingleVariable` or `MOI.ScalarAffineFunction`,
    # a `MOI.ScalarAffineFunction` is set as objective function for the dual problem.
    # If it is `MOI.ScalarQuadraticFunction` , a `MOI.ScalarQuadraticFunction` is set as objective function for the dual problem.
    G = F <: MOI.ScalarQuadraticFunction ? MOI.ScalarQuadraticFunction{T} : MOI.ScalarAffineFunction{T}
    return supported_obj(F) && MOI.supports(optimizer.dual_problem.dual_model, MOI.ObjectiveFunction{G}())
end

function MOI.supports_constraint(
    optimizer::DualOptimizer{T},
    F::Type{<:Union{MOI.SingleVariable, MOI.ScalarAffineFunction{T}}},
    S::Type{<:MOI.AbstractScalarSet}) where T
    D = try
        D = dual_set_type(S)
    catch
        return false # The fallback of `dual_set_type` throws an error.
    end
    if D <: MOI.AbstractVectorSet # The dual of `EqualTo` is `Reals`
        return MOI.supports_add_constrained_variables(optimizer.dual_problem.dual_model, D)
    else
        return MOI.supports_add_constrained_variable(optimizer.dual_problem.dual_model, D)
    end
end

function MOI.supports_constraint(
    optimizer::DualOptimizer{T},
    F::Type{<:Union{MOI.VectorOfVariables, MOI.VectorAffineFunction{T}}},
    S::Type{<:MOI.AbstractVectorSet}) where T
    D = try
        D = dual_set_type(S)
    catch
        return false # The fallback of `dual_set_type` throws an error.
    end
    return MOI.supports_add_constrained_variables(optimizer.dual_problem.dual_model, D)
end

# TODO add this when constrained variables are implemented
#function MOI.supports_add_constrained_variables(
#    optimizer::DualOptimizer{T}, S::Type{MOI.Reals}) where T
#    return MOI.supports_constraint(optimizer.dual_problem.dual_model,
#                                   MOI.ScalarAffineFunction{T},
#                                   MOI.EqualTo{T}) # If it was `MOI.Zeros`, we would not need this method as special case of the one below
#end
#function MOI.supports_add_constrained_variables(
#    optimizer::DualOptimizer{T}, S::Type{<:MOI.AbstractVectorSet}) where T
#    D = try
#        D = dual_set_type(S)
#    catch
#        return false # The fallback of `dual_set_type` throws an error.
#    end
#    return MOI.supports_constraint(optimizer.dual_problem.dual_model,
#                                   MOI.VectorAffineFunction{T}, MOI.dual_set_type(S))
#end

function MOI.copy_to(dest::DualOptimizer, src::MOI.ModelLike; kwargs...)
    # Dualize the original problem
    dualize(src, dest.dual_problem)

    # Identity IndexMap
    idx_map = MOIU.IndexMap()

    for vi in MOI.get(src, MOI.ListOfVariableIndices())
        setindex!(idx_map, vi, vi)
    end

    for (F, S) in MOI.get(src, MOI.ListOfConstraints())
        for con in MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
            setindex!(idx_map, con, con)
        end
    end
    return idx_map
end

function MOI.optimize!(optimizer::DualOptimizer)
    return MOI.optimize!(optimizer.dual_problem.dual_model)
end

function MOI.is_empty(optimizer::DualOptimizer)
    return (MOI.is_empty(optimizer.dual_problem.dual_model)) && is_empty(optimizer.dual_problem.primal_dual_map)
end

function MOI.empty!(optimizer::DualOptimizer)
    MOI.empty!(optimizer.dual_problem.dual_model)
    empty!(optimizer.dual_problem.primal_dual_map)
    return
end

# MOI.get auxiliary functions
function get_ci_dual_problem(optimizer::DualOptimizer, vi::VI)
    return optimizer.dual_problem.primal_dual_map.primal_var_dual_con[vi]
end

function get_ci_dual_problem(optimizer::DualOptimizer, ci::CI)
    return optimizer.dual_problem.primal_dual_map.primal_con_dual_con[ci]
end

function get_primal_ci_constant(optimizer::DualOptimizer, ci::CI)
    return first(get_primal_ci_constants(optimizer, ci))
end

function get_primal_ci_constants(optimizer::DualOptimizer, ci::CI)
    return optimizer.dual_problem.primal_dual_map.primal_con_constants[ci]
end

function get_vi_dual_problem(optimizer::DualOptimizer, ci::CI)
    return first(get_vis_dual_problem(optimizer, ci))
end

function get_vis_dual_problem(optimizer::DualOptimizer, ci::CI)
    return optimizer.dual_problem.primal_dual_map.primal_con_dual_var[ci]
end

function MOI.get(optimizer::DualOptimizer, ::MOI.SolverName)
    return "Dual model with "*MOI.get(optimizer.dual_problem.dual_model, MOI.SolverName()) * " attached"
end

function MOI.get(optimizer::DualOptimizer, ::MOI.VariablePrimal, vi::VI)
    return -MOI.get(optimizer.dual_problem.dual_model,
                    MOI.ConstraintDual(), get_ci_dual_problem(optimizer, vi))
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintDual,
                 ci::CI{F,S}) where {F <: MOI.AbstractScalarFunction, S <: MOI.AbstractScalarSet}
    return MOI.get(optimizer.dual_problem.dual_model,
                   MOI.VariablePrimal(), get_vi_dual_problem(optimizer, ci))
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintDual,
                 ci::CI{F,S}) where {F <: MOI.AbstractVectorFunction, S <: MOI.AbstractVectorSet}
    return MOI.get.(optimizer.dual_problem.dual_model,
                    MOI.VariablePrimal(), get_vis_dual_problem(optimizer, ci))
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintPrimal,
                 ci::CI{F,S}) where {F <: MOI.AbstractScalarFunction, S <: MOI.AbstractScalarSet}
    primal_ci_constant = get_primal_ci_constant(optimizer, ci)
    # If it has no key than there is no dual constraint
    if !haskey(optimizer.dual_problem.primal_dual_map.primal_con_dual_con, ci)
        return -primal_ci_constant
    end
    ci_dual_problem = get_ci_dual_problem(optimizer, ci)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.ConstraintDual(), ci_dual_problem) - primal_ci_constant
end

function MOI.get(optimizer::DualOptimizer{T}, ::MOI.ConstraintPrimal,
                 ci::CI{F,S}) where {T, F <: MOI.AbstractVectorFunction, S <: MOI.AbstractVectorSet}
    # If it has no key than there is no dual constraint
    if !haskey(optimizer.dual_problem.primal_dual_map.primal_con_dual_con, ci)
        # The number of dual variable associated with the primal constraint is the ci dimension
        ci_dimension = length(get_vis_dual_problem(optimizer, ci))
        return zeros(T, ci_dimension)
    end
    ci_dual_problem = get_ci_dual_problem(optimizer, ci)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.ConstraintDual(), ci_dual_problem)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.TerminationStatus)
    return dual_status(MOI.get(optimizer.dual_problem.dual_model, MOI.TerminationStatus()))
end

function dual_status(term::MOI.TerminationStatusCode)
    if term == MOI.INFEASIBLE
        return MOI.DUAL_INFEASIBLE
    elseif term == MOI.DUAL_INFEASIBLE
        return MOI.INFEASIBLE
    elseif term == MOI.ALMOST_INFEASIBLE
        return MOI.ALMOST_DUAL_INFEASIBLE
    elseif term == MOI.ALMOST_DUAL_INFEASIBLE
        return MOI.ALMOST_INFEASIBLE
    end
    return term
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ObjectiveValue)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.DualObjectiveValue())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.DualObjectiveValue)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.ObjectiveValue())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.PrimalStatus)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.DualStatus())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.DualStatus)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.PrimalStatus())
end

function MOI.set(optimizer::DualOptimizer, attr::MOI.AbstractOptimizerAttribute, value)
    return MOI.set(optimizer.dual_problem.dual_model, attr, value)
end
function MOI.get(optimizer::DualOptimizer, attr::Union{MOI.AbstractModelAttribute, MOI.AbstractOptimizerAttribute})
    return MOI.get(optimizer.dual_problem.dual_model, attr)
end
