using Test

@testset "TESTSETS: Test read TCX dir" begin
    @testset "CASE: Test a string that is NOT a path" begin
        err, _ = TCX.parse_tcx_dir("I am not a path")
        @test err == TCX.SERVER_ERROR
    end

    @testset "CASE: Test dir with NO TCX file" begin
	      err, _ =  TCX.parse_tcx_dir(tempdir())
        @test err == TCX.NOT_FOUND
    end

    @testset "CASE: Test dir with TCX file" begin
        err, _ =  TCX.parse_tcx_dir(@__DIR__)
        @test err == TCX.OK
    end

    @testset "CASE: Test relative dir with TCX file" begin
        err, _ =  TCX.parse_tcx_dir(".")
        @test err == TCX.OK
    end

    @testset "CASE: Test DataFrame after process dir" begin
        err, ta =  TCX.parse_tcx_dir(".")
        @test (err == TCX.OK) & (size(getDataFrame(ta), 1) == 10087)
    end
end

