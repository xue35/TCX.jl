using Test, Dates

@testset "TESTSETS: Test conversion of datestring to date time" begin
    the_last_year = DateTime(2020, 1, 1, 0, 0, 0) # Begining of the end

    @testset "CASE: Test parsing of a datestring without milliseconds" begin
        valid_20_ch_datestr = "2020-01-01T00:00:00"
        @test TCX.convertToDateTime(valid_20_ch_datestr) == the_last_year
        @test TCX.convertToDateTime(valid_20_ch_datestr * "Z") == the_last_year
    end

    for i in 1:3
        @testset "CASE: Test parsing of a string with $(i) ms digits" begin
            valid_datestr = "2020-01-01T00:00:00." * ("0" ^ i)
            @test TCX.convertToDateTime(valid_datestr) == the_last_year
            @test TCX.convertToDateTime(valid_datestr * "Z") == the_last_year
        end
    end
end
