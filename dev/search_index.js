var documenterSearchIndex = {"docs":
[{"location":"examples/#Examples-1","page":"Examples","title":"Examples","text":"","category":"section"},{"location":"examples/#","page":"Examples","title":"Examples","text":"Here we discuss some useful examples of usage.","category":"page"},{"location":"examples/#Dualize-a-JuMP-model-1","page":"Examples","title":"Dualize a JuMP model","text":"","category":"section"},{"location":"examples/#","page":"Examples","title":"Examples","text":"Let us dualize the following Second Order Cone program","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"beginalign\n     min_x y z  y + z \n    \n     textst\n    x  = 1\n     x  = 1\n    x  geq (yz)_2\nendalign","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"The corresponding code in JuMP is","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"using JuMP, Dualization\nmodel = Model()\n@variable(model, x)\n@variable(model, y)\n@variable(model, z)\n@constraint(model, soccon, [x; y; z] in SecondOrderCone())\n@constraint(model, eqcon, x == 1)\n@objective(model, Min, y + z)","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"You can dualize the model by doing","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"dual_model = dualize(model)","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"And you should get the model","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"beginalign\n     max_eqcon soccon  eqcon \n    \n     textst\n    eqcon + soccon_1  = 0\n     soccon_2  = 1\n     soccon_3  = 1\n    soccon_1  geq (soccon_2soccon_3)_2\nendalign","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"Note that if you declare the model with an optimizer attached you will lose the optimizer during the dualization. To dualize the model and attach the optimizer to the dual model you should do dualize(dual_model, SolverName.Optimizer)","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"using JuMP, Dualization, ECOS\nmodel = Model(ECOS.Optimizer)\n@variable(model, x)\n@variable(model, y)\n@variable(model, z)\n@constraint(model, soccon, [x; y; z] in SecondOrderCone())\n@constraint(model, eqcon, x == 1)\n@objective(model, Min, y + z)\n\ndual_model = dualize(model, ECOS.Optimizer)","category":"page"},{"location":"examples/#Naming-the-dual-variables-and-dual-constraints-1","page":"Examples","title":"Naming the dual variables and dual constraints","text":"","category":"section"},{"location":"examples/#","page":"Examples","title":"Examples","text":"You can provide prefixes for the name of the variables and the name of the constraints using the a DualNames variable. Everytime you use the dualize function you can provide a DualNames as keyword argument. Consider the following example.","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"You want to dualize this JuMP problem and add a prefix to the name of each constraint to be more clear on what the variables represent. For instance you want to put \"dual\" before the name of the constraint.","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"using JuMP, Dualization\nmodel = Model()\n@variable(model, x)\n@variable(model, y)\n@variable(model, z)\n@constraint(model, soccon, [x; y; z] in SecondOrderCone())\n@constraint(model, eqcon, x == 1)\n@objective(model, Min, y + z)\n\n# The first field of DualNames is the prefix of the dual variables\n# and the second field is the prefix of the dual constraint\ndual_model = dualize(model; dual_names = DualNames(\"dual\", \"\"))","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"The dual_model will be registered as","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"beginalign\n     max_dualeqcon dualsoccon  dualeqcon \n    \n     textst\n    dualeqcon + dualsoccon_1  = 0\n     dualsoccon_2  = 1\n     dualsoccon_3  = 1\n    dualsoccon_1  geq (dualsoccon_2 dualsoccon_3)_2\nendalign","category":"page"},{"location":"examples/#Solving-a-problem-using-its-dual-formulation-1","page":"Examples","title":"Solving a problem using its dual formulation","text":"","category":"section"},{"location":"examples/#","page":"Examples","title":"Examples","text":"Depending on the solver and on the type of formulation, solving the dual problem could be faster than solving the primal. To solve the problem via its dual formulation can be done using the DualOptimizer.","category":"page"},{"location":"examples/#","page":"Examples","title":"Examples","text":"using JuMP, Dualization, ECOS\n\n# Solving a problem the standard way\nmodel = Model(ECOS.Optimizer)\n@variable(model, x)\n@variable(model, y)\n@variable(model, z)\n@constraint(model, soccon, [x; y; z] in SecondOrderCone())\n@constraint(model, eqcon, x == 1)\n@objective(model, Min, y + z)\n\n# Solving a problem by providing its dual representation\nmodel = Model(dual_optimizer(ECOS.Optimizer))\n@variable(model, x)\n@variable(model, y)\n@variable(model, z)\n@constraint(model, soccon, [x; y; z] in SecondOrderCone())\n@constraint(model, eqcon, x == 1)\n@objective(model, Min, y + z)\n\n# You can pass arguments to the solver by attaching them to the solver constructor.\nmodel = Model(dual_optimizer(optimizer_with_attributes(ECOS.Optimizer, \"maxit\" => 5)))\n@variable(model, x)\n@variable(model, y)\n@variable(model, z)\n@constraint(model, soccon, [x; y; z] in SecondOrderCone())\n@constraint(model, eqcon, x == 1)\n@objective(model, Min, y + z)","category":"page"},{"location":"manual/#Manual-1","page":"Manual","title":"Manual","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"note: Note\nThis package only works for optimization models that can be written in the conic-form.","category":"page"},{"location":"manual/#Conic-Duality-1","page":"Manual","title":"Conic Duality","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Conic duality is the starting point for MOI's duality conventions. When all functions are affine (or coordinate projections), and all constraint sets are closed convex cones, the model may be called a conic optimization problem. For conic-form minimization problems, the primal is:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_x in mathbbR^n  a_0^T x + b_0\n\n textst  A_i x + b_i  in mathcalC_i  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"and the dual is:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n max_y_1 ldots y_m  -sum_i=1^m b_i^T y_i + b_0\n\n textst  a_0 - sum_i=1^m A_i^T y_i  = 0\n\n  y_i  in mathcalC_i^*  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"where each mathcalC_i is a closed convex cone and mathcalC_i^* is its dual cone.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"For conic-form maximization problems, the primal is:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n max_x in mathbbR^n  a_0^T x + b_0\n\n textst  A_i x + b_i  in mathcalC_i  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"and the dual is:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_y_1 ldots y_m  sum_i=1^m b_i^T y_i + b_0\n\n textst  a_0 + sum_i=1^m A_i^T y_i  = 0\n\n  y_i  in mathcalC_i^*  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"A linear inequality constraint a^T x + b ge c should be interpreted as a^T x + b - c in mathbbR_+, and similarly a^T x + b le c should be interpreted as a^T x + b - c in mathbbR_-. Variable-wise constraints should be interpreted as affine constraints with the appropriate identity mapping in place of A_i.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"For the special case of minimization LPs, the MOI primal form can be stated as","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_x in mathbbR^n  a_0^T x + b_0\n\n textst\nA_1 x  ge b_1\n A_2 x  le b_2\n A_3 x  = b_3\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"By applying the stated transformations to conic form, taking the dual, and transforming back into linear inequality form, one obtains the following dual:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n max_y_1y_2y_3  b_1^Ty_1 + b_2^Ty_2 + b_3^Ty_3 + b_0\n\n textst\nA_1^Ty_1 + A_2^Ty_2 + A_3^Ty_3  = a_0\n y_1 ge 0\n y_2 le 0\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"For maximization LPs, the MOI primal form can be stated as:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n max_x in mathbbR^n  a_0^T x + b_0\n\n textst\nA_1 x  ge b_1\n A_2 x  le b_2\n A_3 x  = b_3\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"and similarly, the dual is:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_y_1y_2y_3  -b_1^Ty_1 - b_2^Ty_2 - b_3^Ty_3 + b_0\n\n textst\nA_1^Ty_1 + A_2^Ty_2 + A_3^Ty_3  = -a_0\n y_1 ge 0\n y_2 le 0\nendalign","category":"page"},{"location":"manual/#Supported-constraints-1","page":"Manual","title":"Supported constraints","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"This is the list of supported Function-in-Set constraints of the package. If you try to dualize a constraint not listed here, it will return an unsupported error.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"MOI Function MOI Set\nVariableIndex GreaterThan\nVariableIndex LessThan\nVariableIndex EqualTo\nScalarAffineFunction GreaterThan\nScalarAffineFunction LessThan\nScalarAffineFunction EqualTo\nVectorOfVariables Nonnegatives\nVectorOfVariables Nonpositives\nVectorOfVariables Zeros\nVectorOfVariables SecondOrderCone\nVectorOfVariables RotatedSecondOrderCone\nVectorOfVariables PositiveSemidefiniteConeTriangle\nVectorOfVariables ExponentialCone\nVectorOfVariables DualExponentialCone\nVectorOfVariables PowerCone\nVectorOfVariables DualPowerCone\nVectorAffineFunction Nonnegatives\nVectorAffineFunction Nonpositives\nVectorAffineFunction Zeros\nVectorAffineFunction SecondOrderCone\nVectorAffineFunction RotatedSecondOrderCone\nVectorAffineFunction PositiveSemidefiniteConeTriangle\nVectorAffineFunction ExponentialCone\nVectorAffineFunction DualExponentialCone\nVectorAffineFunction PowerCone\nVectorAffineFunction DualPowerCone","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Note that some of MOI constraints can be bridged, see Bridges, to constraints in this list.","category":"page"},{"location":"manual/#Supported-objective-functions-1","page":"Manual","title":"Supported objective functions","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"MOI Function\nVariableIndex\nScalarAffineFunction","category":"page"},{"location":"manual/#Dualize-a-model-1","page":"Manual","title":"Dualize a model","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"dualize","category":"page"},{"location":"manual/#Dualization.dualize","page":"Manual","title":"Dualization.dualize","text":"dualize(args...; kwargs...)\n\nThe dualize function works in three different ways. The user can provide:\n\nA MathOptInterface.ModelLike\n\nThe function will return a DualProblem struct that has the dualized model and PrimalDualMap{Float64} for users to identify the links between primal and dual model. The PrimalDualMap{Float64} maps variables and constraints from the original primal model into the respective objects of the dual model.\n\nA MathOptInterface.ModelLike and a DualProblem{T}\nA JuMP.Model\n\nThe function will return a JuMP model with the dual representation of the problem.\n\nA JuMP.Model and an optimizer constructor\n\nThe function will return a JuMP model with the dual representation of the problem with the optimizer constructor attached.\n\nOn each of these methods, the user can provide the following keyword arguments:\n\ndual_names: of type DualNames struct. It allows users to set more intuitive names\n\nfor the dual variables and dual constraints created.\n\nvariable_parameters: A vector of MOI.VariableIndex containing the variables that\n\nshould not be considered model variables during dualization. These variables will behave like constants during dualization. This is specially useful for the case of bi-level modelling, where the second level depends on some decisions from the upper level.\n\nignore_objective: a boolean indicating if the objective function should be\n\nadded to the dual model. This is also useful for bi-level modelling, where the second level model is represented as a KKT in the upper level model.\n\n\n\n\n\n","category":"function"},{"location":"manual/#DualOptimizer-1","page":"Manual","title":"DualOptimizer","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"You can solve a primal problem by using its dual formulation using the DualOptimizer.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"DualOptimizer","category":"page"},{"location":"manual/#Dualization.DualOptimizer","page":"Manual","title":"Dualization.DualOptimizer","text":"DualOptimizer(dual_optimizer::OT) where {OT <: MOI.ModelLike}\n\nThe DualOptimizer finds the solution for a problem by solving its dual representation. It builds the dual model internally and solve it using the dual_optimizer as solver. Primal results are obtained by querying dual results of the internal problem solved by dual_optimizer. Analogously, dual results are obtained by querying primal results of the internal problem.\n\nThe user can define the model providing the DualOptimizer and the solver of its choice.\n\nExample:\n\njulia> using Dualization, JuMP, HiGHS\n\njulia> model = Model(dual_optimizer(HiGHS.Optimizer))\nA JuMP Model\nFeasibility problem with:\nVariables: 0\nModel mode: AUTOMATIC\nCachingOptimizer state: EMPTY_OPTIMIZER\nSolver name: Dual model with HiGHS attached\n\n\n\n\n\n","category":"type"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Solving an optimization problem via its dual representation can be useful because some conic solvers assume the model is in the standard form and others use the geometric form.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Geometric form has affine expressions in cones","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_x in mathbbR^n  c^T x\n\n textst  A_i x + b_i  in mathcalC_i  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Standard form has variables in cones","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_x in mathbbR^n  c^T x\n\n textst  A x + s  = b\n\n  s  in mathcalC\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Standard form Geometric form\nSDPT3 CDCS\nSDPNAL SCS\nCSDP ECOS\nSDPA SeDuMi\nMosek ","category":"page"},{"location":"manual/#Adding-new-sets-1","page":"Manual","title":"Adding new sets","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Dualization.jl can automatically dualize models with custom sets. To do this, the user needs to define the set and its dual set and provide the functions:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"supported_constraint\ndual_set ","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"If the custom set has some special scalar product (see the link), the user also needs to provide a set_dot function.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"For example, let us define a fake cone and its dual, the fake dual cone. We will write a JuMP model with the fake cone and dualize it.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"using Dualization, JuMP, MathOptInterface, LinearAlgebra\n\n# Rename MathOptInterface to simplify the code\nconst MOI = MathOptInterface\n\n# Define the custom cone and its dual\nstruct FakeCone <: MOI.AbstractVectorSet\n    dimension::Int\nend\n\nstruct FakeDualCone <: MOI.AbstractVectorSet\n    dimension::Int\nend\n\n# Define a model with your FakeCone\nmodel = Model()\n@variable(model, x[1:3])\n@constraint(model, con, x in FakeCone(3)) # Note that the constraint name is \"con\"\n@objective(model, Min, sum(x))","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"The resulting JuMP model is","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n     min_x  x_1 + x_2 + x_3 \n    \n     textst\n    x in FakeCone(3)\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Now in order to dualize we must overload the methods as described above.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"# Overload the methods dual_set and supported_constraints\nDualization.dual_set(s::FakeCone) = FakeDualCone(MOI.dimension(s))\nDualization.supported_constraint(::Type{MOI.VectorOfVariables}, ::Type{<:FakeCone}) = true\n\n# If your set has some specific scalar product you also need to define a new set_dot function\n# Our FakeCone has this weird scalar product\nMOI.Utilities.set_dot(x::Vector, y::Vector, set::FakeCone) = 2dot(x, y)\n\n# Dualize the model\ndual_model = dualize(model)","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"The resulting dual model is ","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n     max_con  0 \n    \n     textst\n    2con_1  = 1\n    2con_2  = 1\n    2con_3  = 1\n     con  in FakeDualCone(3)\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"If the model has constraints that are MOI.VectorAffineFunction","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"model = Model()\n@variable(model, x[1:3])\n@constraint(model, con, x + 3 in FakeCone(3))\n@objective(model, Min, sum(x))","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n     min_x  x_1 + x_2 + x_3 \n    \n     textst\n    x_1 + 3 x_2 + 3 x_3 + 3  in FakeCone(3)\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"the user only needs to extend the supported_constraints function.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"# Overload the supported_constraints for VectorAffineFunction\nDualization.supported_constraint(::Type{<:MOI.VectorAffineFunction}, ::Type{<:FakeCone}) = true\n\n# Dualize the model\ndual_model = dualize(model)","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"The resulting dual model is","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n     max_con  - 3con_1 - 3con_2 - 3con_3 \n    \n     textst\n    2con_1  = 1\n    2con_2  = 1\n    2con_3  = 1\n     con  in FakeDualCone(3)\nendalign","category":"page"},{"location":"manual/#Advanced-1","page":"Manual","title":"Advanced","text":"","category":"section"},{"location":"manual/#KKT-Conditions-1","page":"Manual","title":"KKT Conditions","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"The KKT conditions are a set of inequalities for which the feasible solution is equivalent to the optimal solution of an optimization problem, as long as strong duality holds and constraint qualification rules such as Slater's are valid. The KKT is used in many branches of optimization and it might be interesting to write them programatically.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"The KKT conditions of the minimization problem of the first section are the following:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Primal Feasibility:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"A_i x + b_i  in mathcalC_i    i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Dual Feasibility:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"y_i in mathcalC_i^*   i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Complementary slackness:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"y_i^T (A_i x + b_i) = 0   i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Stationarity:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"a_0 - sum_i=1^m A_i^T y_i  = 0","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Note that \"Dual Feasibility\" and \"Stationarity\" correspond to the two constraints of the dual problem. Therefore, after writing the primal problem, Dualization.jl can obtain the dual problem automatically and then we simply have to write the \"Complementary slackness\" to complete the KKT conditions.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"One important use case is Bilevel optimization, see BilevelJuMP.jl. In this case, variables of an upstream model are considered as parameters in a lower level model. One classical solution method for bilevel programs is to write the KKT conditions of the lower (or inner) problem and consider them as (non-linear) constraints of the upper (or outer) problem. Dualization can be used to derive parts of KKT conditions.","category":"page"},{"location":"manual/#Parametric-problems-1","page":"Manual","title":"Parametric problems","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"It is also possible to deal with parametric models. In regular optimization problems we only have a single (vector) variable represented by x in the duality section, there are many use cases in which we can represent parameters that will not be considered in the optimization, these are treated as constants and, hence, not \"dualized\".","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"In the following, we will use x to denote primal optimization variables, y for dual optimization variables and z for parameters.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_x in mathbbR^n  a_0^T x + b_0 + d_0^Tz\n\n textst  A_i x + b_i + D_i z  in mathcalC_i  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"and the dual is:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n max_y_1 ldots y_m  -sum_i=1^m (b_i + D_iz)^T y_i + b_0 + d_0^Tz\n\n  textst  a_0 - sum_i=1^m A_i^T y_i  = 0\n\n  y_i  in mathcalC_i^*  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"and the KKT conditions are:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Primal Feasibility:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"A_i x + b_i + D_i z in mathcalC_i    i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Dual Feasibility:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"y_i in mathcalC_i^*   i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Complementary slackness:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"y_i^T (A_i x + b_i + D_i z) = 0   i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Stationarity:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"a_0 - sum_i=1^m A_i^T y_i  = 0","category":"page"},{"location":"manual/#Quadratic-problems-1","page":"Manual","title":"Quadratic problems","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Optimization problems with conic constraints and quadratic objective are a straightforward extensions to the conic problem with linear constraints usually defined in MOI. More information here.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"A primal minimization problem can be standardized as:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_x in mathbbR^n  frac12 x^T P x + a_0^T x + b_0\n\n textst  A_i x + b_i  in mathcalC_i  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Where P is a positive semidefinite matrix.","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"A compact formulation for the dual problem requires pseudo-inverses, however, we can add an extra slack variable w to the dual problem and obtain the following dual problem:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n max_y_1 ldots y_m  - frac12 w^T P w - sum_i=1^m b_i^T y_i + b_0\n\n textst  a_0 - sum_i=1^m A_i^T y_i + P w  = 0\n\n  y_i  in mathcalC_i^*  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"note that the sign in front of the P matrix can be changed because w is free and the only other term depending in w is quadratic and symmetric. The sign choice is interesting to keep the dual problem closer to the KKT conditions that reads as follows:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"\n","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Primal Feasibility:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"A_i x + b_i in mathcalC_i    i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Dual Feasibility:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"y_i in mathcalC_i^*   i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Complementary slackness:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"y_i^T (A_i x + b_i) = 0   i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Stationarity:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"P x + a_0 - sum_i=1^m A_i^T y_i  = 0","category":"page"},{"location":"manual/#Parametric-quadratic-problems-1","page":"Manual","title":"Parametric quadratic problems","text":"","category":"section"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Just like the linear problems, these quadratic programs can be parametric. The Primal minimization form is:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n min_x in mathbbR^n   + frac12 x^T P_1 x + x^T P_2 z + frac12 z^T P_3 z\n\n   + a_0^T x + b_0 + d_0^T z notag\n\n textst  A_i x + b_i + D_i z  in mathcalC_i  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"The Dual is:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"beginalign\n max_y_1 ldots y_m  - frac12 w^T P_1 w + frac12 z^T P_3 z \n\n  -sum_i=1^m (b_i + D_i z)^T y_i + d_0^T z + b_0 notag\n\n textst  a_0 + P_2 z - sum_i=1^m A_i^T y_i + P_1 w  = 0\n\n  y_i  in mathcalC_i^*  i = 1 ldots m\nendalign","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"and the KKT conditions are:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Primal Feasibility:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"A_i x + b_i + D_i z in mathcalC_i    i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Dual Feasibility:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"y_i in mathcalC_i^*   i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Complementary slackness:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"y_i^T (A_i x + b_i + D_i z) = 0   i = 1 ldots m","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"Stationarity:","category":"page"},{"location":"manual/#","page":"Manual","title":"Manual","text":"P_1 x + P_2 z + a_0 - sum_i=1^m A_i^T y_i  = 0","category":"page"},{"location":"reference/#Reference-1","page":"Reference","title":"Reference","text":"","category":"section"},{"location":"reference/#","page":"Reference","title":"Reference","text":"Dualization.supported_constraints\nDualization.supported_objective\nDualization.DualNames","category":"page"},{"location":"reference/#Dualization.supported_constraints","page":"Reference","title":"Dualization.supported_constraints","text":"supported_constraints(con_types::Vector{Tuple{Type, Type}})\n\nReturns true if Function-in-Set is supported for Dualization and throws an error if it is not.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Dualization.supported_objective","page":"Reference","title":"Dualization.supported_objective","text":"supported_objective(primal_model::MOI.ModelLike)\n\nReturns true if MOI.ObjectiveFunctionType() is supported for Dualization and throws an error if it is not.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Dualization.DualNames","page":"Reference","title":"Dualization.DualNames","text":"DualNames\n\nDualNames is a struct to pass the prefix of dual variables and dual constraints names. See more on naming the variables.\n\n\n\n\n\n","category":"type"},{"location":"#Dualization.jl-Documentation-1","page":"Home","title":"Dualization.jl Documentation","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Dualization.jl is a package written on top of MathOptInterface that allows users to write the dual of a JuMP model automatically. This package has two main features: the dualize function, which enables users to get a dualized JuMP model, and the DualOptimizer, which enables users to solve a problem by providing the solver the dual of the problem. ","category":"page"},{"location":"#Installation-1","page":"Home","title":"Installation","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"To install the package you can use Pkg.add as follows:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"pkg> add Dualization","category":"page"},{"location":"#Contributing-1","page":"Home","title":"Contributing","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Contributions to this package are more than welcome, if you find a bug or have any suggestions for the documentation please post it on the github issue tracker.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"When contributing please note that the package follows the JuMP style guide.","category":"page"}]
}
