using Test

gpx_sample_file2=joinpath(@__DIR__, gpx_sample_file)
tcx_sample_file2=joinpath(@__DIR__, tcx_sample_file)

@testset "TESTSETS: Test readable file" begin
    @testset "CASE: Test file not exists" begin
        err, data =  TCX.parse_tcx_file("non-existing-file.tcx")
        @test err == 404
    end
    @testset "CASE: Test file exist but not a TCX file" begin
        err, _ =  TCX.parse_tcx_file(gpx_sample_file2)
        @test err == 400
    end
    @testset "CASE: Test a TCX file" begin
        err, data =  TCX.parse_tcx_file(tcx_sample_file2)
        @test err == 200
    end
    @testset "CASE: Test a TCX Running file" begin
        err, data =  TCX.parse_tcx_file(tcx_sample_file2)
        @test (err == 200) & (activity_Type(data) == "Running")
    end

    @testset "CASE: Test track point not empty" begin
        err, data = TCX.parse_tcx_file(tcx_sample_file2)
        @test (err == 200) & (size(get_DataFrame(data), 2) > 0)
    end
end

