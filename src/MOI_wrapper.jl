# Supported Functions
const SF = Union{MOI.SingleVariable, 
                 MOI.ScalarAffineFunction{Float64}, 
                 MOI.VectorOfVariables, 
                 MOI.VectorAffineFunction{Float64}}

# Supported Sets
const SS = Union{MOI.EqualTo{Float64}, MOI.GreaterThan{Float64}, MOI.LessThan{Float64}, 
                 MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives, 
                 MOI.SecondOrderCone, MOI.RotatedSecondOrderCone,
                 MOI.ExponentialCone, MOI.DualExponentialCone,
                 MOI.PowerCone, MOI.DualPowerCone,
                 MOI.PositiveSemidefiniteConeTriangle}

mutable struct DualOptimizer{OT <: MOI.ModelLike} <: MOI.AbstractOptimizer
    dual_problem::Union{Nothing, DualProblem}
    dual_optimizer::OT
    dual_optimizer_idx_map::Union{Nothing, MOIU.IndexMap}

    function DualOptimizer{OT}(dual_optimizer::OT) where {OT <: MOI.ModelLike}
        return new(nothing, dual_optimizer, nothing)
    end
    function DualOptimizer(dual_optimizer::OT) where {OT <: MOI.ModelLike}
        return DualOptimizer{OT}(dual_optimizer)
    end
end

function MOI.supports(::DualOptimizer,
                      ::Union{MOI.ObjectiveSense,
                              MOI.ObjectiveFunction{MOI.SingleVariable},
                              MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}})
    return true
end

function MOI.supports_constraint(optimizer::DualOptimizer, F::Type{<:SF}, S::Type{<:SS})
    if optimizer.dual_optimizer !== nothing
        MOI.supports_constraint(optimizer.dual_optimizer, F, S)
    else
        return true
    end
end

function MOI.supports_constraint(::DualOptimizer, ::Type{MOI.AbstractFunction}, ::Type{MOI.AbstractSet})
    return false 
end

function MOI.copy_to(dest::DualOptimizer, src::MOI.ModelLike; kwargs...)
    # Dualize the original problem
    dest.dual_problem = dualize(src)
    # Copy the dualized model to the inner optimizer
    idx_map_optimizer = MOI.copy_to(dest.dual_optimizer, dest.dual_problem.dual_model; kwargs...)
    # Allocates the IndexMap of the inner Optimizer to later query results
    dest.dual_optimizer_idx_map = idx_map_optimizer

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
    return MOI.optimize!(optimizer.dual_optimizer)    
end

function MOI.is_empty(optimizer::DualOptimizer)
    return (optimizer.dual_problem === nothing) && (MOI.is_empty(optimizer.dual_optimizer))
end

function MOI.empty!(optimizer::DualOptimizer)
    MOI.empty!(optimizer.dual_optimizer)
    optimizer.dual_problem = nothing
    return
end

# MOI.get auxiliary functions
function get_ci_dual_problem(optimizer::DualOptimizer, vi::VI)
    return optimizer.dual_problem.primal_dual_map.primal_var_dual_con[vi]
end

function get_ci_dual_problem(optimizer::DualOptimizer, ci::CI)
    return optimizer.dual_problem.primal_dual_map.primal_con_dual_con[ci]
end

function get_ci_dual_optimizer(optimizer::DualOptimizer, vi::VI)
    return optimizer.dual_optimizer_idx_map.conmap[get_ci_dual_problem(optimizer, vi)]
end

function get_ci_dual_optimizer(optimizer::DualOptimizer, ci::CI)
    return optimizer.dual_optimizer_idx_map.conmap[ci]
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

function get_vi_dual_optimizer(optimizer::DualOptimizer, ci::CI)
    return optimizer.dual_optimizer_idx_map.varmap[get_vi_dual_problem(optimizer, ci)]
end

function get_vis_dual_optimizer(optimizer::DualOptimizer, ci::CI)
    vis_dual_problem = get_vis_dual_problem(optimizer, ci)
    dual_optimizer_vi = Vector{VI}(undef, length(vis_dual_problem))
    for (i, vi) in enumerate(vis_dual_problem)
        dual_optimizer_vi[i] = optimizer.dual_optimizer_idx_map.varmap[vi]
    end
    return dual_optimizer_vi
end

function MOI.get(optimizer::DualOptimizer, ::MOI.SolverName)
    return "Dual model with "*MOI.get(optimizer.dual_optimizer, MOI.SolverName())*" attached"
end

function MOI.get(optimizer::DualOptimizer, ::MOI.VariablePrimal, vi::VI)
    return -MOI.get(optimizer.dual_optimizer, 
                    MOI.ConstraintDual(), get_ci_dual_optimizer(optimizer, vi))
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintDual, 
                 ci::CI{F,S}) where {F <: MOI.AbstractScalarFunction, S}
    return MOI.get(optimizer.dual_optimizer, 
                   MOI.VariablePrimal(), get_vi_dual_optimizer(optimizer, ci))
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintDual, 
                 ci::CI{F,S}) where {F <: MOI.AbstractVectorFunction, S}
    return MOI.get.(optimizer.dual_optimizer, 
                    MOI.VariablePrimal(), get_vis_dual_optimizer(optimizer, ci))
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintPrimal, 
                 ci::CI{F,S}) where {F <: MOI.AbstractScalarFunction, S}
    ci_dual_problem = get_ci_dual_problem(optimizer, ci)
    primal_ci_constant = get_primal_ci_constant(optimizer, ci)
    if ci_dual_problem === nothing
        return -primal_ci_constant
    end
    ci_dual_optimizer = get_ci_dual_optimizer(optimizer, ci_dual_problem)
    return MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci_dual_optimizer) - primal_ci_constant
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintPrimal, 
                 ci::CI{F,S}) where {F <: MOI.AbstractVectorFunction, S}
    ci_dual_problem = get_ci_dual_problem(optimizer, ci)
    primal_ci_constants = get_primal_ci_constants(optimizer, ci)
    if ci_dual_problem === nothing
        return -primal_ci_constants
    end
    ci_dual_optimizer = get_ci_dual_optimizer(optimizer, ci_dual_problem)
    return MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci_dual_optimizer) .- primal_ci_constants
end

"""
In the VAF case it is different 
"""
function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintPrimal, 
                 ci::CI{F,S}) where {T, F <: VAF{T}, S}
    ci_dual_problem = get_ci_dual_problem(optimizer, ci)
    primal_ci_constants = get_primal_ci_constants(optimizer, ci)
    if ci_dual_problem === nothing
        return zeros(T, length(primal_ci_constants))
    end
    ci_dual_optimizer = get_ci_dual_optimizer(optimizer, ci_dual_problem)
    return MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci_dual_optimizer)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.SolveTime) 
    return MOI.get(optimizer.dual_optimizer, MOI.SolveTime())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.TerminationStatus) 
    return dual_status(MOI.get(optimizer.dual_optimizer, MOI.TerminationStatus()))
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

# To be added in MOI 0.9.0
# function MOI.get(optimizer::DualOptimizer, ::MOI.ObjectiveValue)
#     return MOI.get(optimizer.dual_optimizer, MOI.DualObjectiveValue())
# end

# function MOI.get(optimizer::DualOptimizer, ::MOI.DualObjectiveValue)
#     return MOI.get(optimizer.dual_optimizer, MOI.ObjectiveValue())
# end

function MOI.get(optimizer::DualOptimizer, ::MOI.ObjectiveValue)
    return MOI.get(optimizer.dual_optimizer, MOI.ObjectiveValue())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.PrimalStatus)
    return MOI.get(optimizer.dual_optimizer, MOI.DualStatus())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.DualStatus)
    return MOI.get(optimizer.dual_optimizer, MOI.PrimalStatus())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ResultCount)
    return MOI.get(optimizer.dual_optimizer, MOI.ResultCount())
end