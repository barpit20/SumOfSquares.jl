using Test
using SumOfSquares
using DynamicPolynomials
using SemialgebraicSets

# Adapted from:
# SOSDEMO4 --- Matrix Copositivity
# Section 3.4 of SOSTOOLS User's Manual
#
# See also (3.41) of [BPT12].
#
# [BPT12] Blekherman, G.; Parrilo, P. A. & Thomas, R. R.
# *Semidefinite Optimization and Convex Algebraic Geometry*.
# Society for Industrial and Applied Mathematics, **2012**.

function horn_test(optimizer,
                   config::MOIT.TestConfig,
                   cone::SumOfSquares.PolyJuMP.PolynomialSet)
    atol = config.atol
    rtol = config.rtol

    # Horn matrix
    H = [1 -1  1  1 -1;
        -1  1 -1  1  1;
         1 -1  1 -1  1;
         1  1 -1  1 -1;
        -1  1  1 -1  1]

    @polyvar x[1:5]

    model = _model(optimizer)
    cref = @constraint(model, x' * H * x in CopositiveInner(cone))
    optimize!(model)

    @test termination_status(model) == MOI.INFEASIBLE

    model = _model(optimizer)
    orthant = @set x[1] ≥ 0 && x[2] ≥ 0 && x[3] ≥ 0 && x[4] ≥ 0 && x[5] ≥ 0
    cref = @constraint(model, sum(x) * x' * H * x in cone, domain = orthant)
    optimize!(model)

    @test termination_status(model) == MOI.INFEASIBLE

    model = _model(optimizer)
    orthant = orthant ∩ basicsemialgebraicset(
        algebraicset(polynomialtype(x[1])[]), polynomial.(monomials(x, 3)))
    cref = @constraint(model, sum(x) * x' * H * x in cone, domain = orthant)
    optimize!(model)

    if cone isa SOSCone
        @test termination_status(model) == MOI.OPTIMAL

        @test primal_status(model) == MOI.FEASIBLE_POINT
        @test isempty(certificate_monomials(cref))
        @test isempty(getmat(gram_matrix(cref)))
    else
        @test termination_status(model) == MOI.INFEASIBLE
    end
end
sos_horn_test(optimizer, config)   = horn_test(optimizer, config, SOSCone())
sdsos_horn_test(optimizer, config) = horn_test(optimizer, config, SDSOSCone())
dsos_horn_test(optimizer, config)  = horn_test(optimizer, config, DSOSCone())
