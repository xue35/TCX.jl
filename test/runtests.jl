using Test, TCX

tcx_sample_file="centry_park_run.tcx"
tcx_centrypark_run_file="centry_park_run.tcx"
tcx_treadmill_run_file="treadmill_run.tcx"
gpx_sample_file="shanghai_marathon_2018.gpx"

@testset "TCX tests" begin
    include("test_tcx_read_file.jl")
    include("test_tcx_read_dir.jl")
    include("test_tcx.jl")
end
