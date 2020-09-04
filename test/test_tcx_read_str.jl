using Test

@testset "TESTSETS: Test read of TCX string" begin
    @testset "CASE: Test string is not XML" begin
        err, _ = TCX.parse_tcx_str("This is not a TCX string\nNot even a little")
        @test err == TCX.CLIENT_ERROR
    end

    @testset "CASE: Test a TCX records run." begin
        path_to_file = joinpath(@__DIR__, tcx_sample_file)
        err, data = TCX.parse_tcx_str(read(path_to_file, String))
        @test (err == TCX.OK) & (getActivityType(data) == "Running")
    end

    @testset "CASE: Test string is not TCX" begin
        err, _ = @test_logs(
            (:warn, "Invalid TCX string: <NotTCX>Oh no! Blorp!</NotTCX>"),
            TCX.parse_tcx_str("<NotTCX>Oh no! Blorp!</NotTCX>")
        )
        @test err == TCX.CLIENT_TCX_ERROR
    end
end
