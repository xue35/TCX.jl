using Test, Dates, Mocking

Mocking.activate()

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

    @testset "CASE: Test parsing an improperly formatted string" begin
        invalid_datestr = "01-01-2020"
        try
            TCX.convertToDateTime(invalid_datestr)
        catch err
            @test err isa ArgumentError
            @test occursin(
                "'$(invalid_datestr)' is improperly formatted.",
                sprint(showerror, err)
            )
        end
    end

    @testset "CASE: Test successfully catching and recovering from an argument error" begin
        datestr = "2020-05-20T21:58:03Z"
        patch = @patch throw(e) = fn(throw(ArgumentError("I'm being unreasonably difficult")))
        apply(patch) do
            datetime = TCX.convertToDateTime(datestr)
            @test 3 == second(datetime)
            @test 58 == minute(datetime)
            @test 21 == hour(datetime)
            @test 20 == day(datetime)
            @test 5 == month(datetime)
            @test 2020 == year(datetime)
        end
    end
end
