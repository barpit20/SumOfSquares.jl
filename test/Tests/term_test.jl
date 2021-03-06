using Test
using SumOfSquares
using DynamicPolynomials

function term_test(optimizer,
                   config::MOIT.TestConfig,
                   cone::SumOfSquares.PolyJuMP.PolynomialSet)
    atol = config.atol
    rtol = config.rtol

    model = _model(optimizer)

    @variable(model, α)

    @polyvar x
    cref = @constraint(model, α * x^2 in cone)

    # See https://github.com/JuliaOpt/MathOptInterface.jl/issues/676
    @objective(model, Min, α + 1)
    optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ 1.0 atol=atol rtol=rtol

    @test primal_status(model) == MOI.FEASIBLE_POINT
    @test value(α) ≈ 0.0 atol=atol rtol=rtol

    p = gram_matrix(cref)
    @test getmat(p) ≈ zeros(1, 1) atol=atol rtol=rtol
    @test p.x == [x]

    @test dual_status(model) == MOI.FEASIBLE_POINT
    μ = dual(cref)
    @test μ isa AbstractMeasure{Float64}
    @test length(moments(μ)) == 1
    @test moment_value(moments(μ)[1]) ≈ 1.0 atol=atol rtol=rtol
    @test monomial(moments(μ)[1]) == x^2

    ν = moment_matrix(cref)
    @test getmat(ν) ≈ ones(1, 1) atol=atol rtol=rtol
    @test ν.x == [x]

    S = SumOfSquares.SOSPolynomialSet{
        SumOfSquares.FullSpace, typeof(cone), SumOfSquares.MonomialBasis,
        Monomial{true},MonomialVector{true},Tuple{}
    }
    @test list_of_constraint_types(model) == [(Vector{VariableRef}, S)]
    test_delete_bridge(
        model, cref, 1,
        ((MOI.VectorOfVariables, MOI.Nonnegatives, 0),
         (MOI.VectorAffineFunction{Float64},
          SumOfSquares.PolyJuMP.ZeroPolynomialSet{
              SumOfSquares.FullSpace, SumOfSquares.MonomialBasis,
              Monomial{true}, MonomialVector{true}},
          0)))
end
sos_term_test(optimizer, config)   = term_test(optimizer, config, SOSCone())
sdsos_term_test(optimizer, config) = term_test(optimizer, config, SDSOSCone())
dsos_term_test(optimizer, config)  = term_test(optimizer, config, DSOSCone())
