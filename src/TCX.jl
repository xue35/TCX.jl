module TCX
using EzXML, Dates, DataFrames

export parse_tcx_file, activity_Type, activity_Id, start_Time, distance, duration, avg_HeartRateBpm, get_DataFrame

struct TrackPoint
    Time::DateTime
    Latitude::Float64
    Longtitude::Float64
    HeartRateBpm::Int32
    AltitueMeter::Float64
    DistanceMeter::Float64
end

struct TCXRecord
    Id::DateTime
    Name::String
    ActivityType::String
    TrackPoints::Array{TrackPoint}
end

function parse_tcx_file(file_path::String)
    if isfile(file_path) == false
        return 404, nothing
    end

    xmldoc = try readxml(file_path)
    catch e
       if isa(e, XMLError)
           # Not a valid XML document
           println("Invalid XML document: ", file_path)
           return 400, nothing
       else
           return 500, nothing
       end
    end

    root_element = root(xmldoc)
    # Check if TCX
    if nodename(root_element) != "TrainingCenterDatabase"
        println("Invalid TCX document: ", file_path)
        return 400, nothing
    end

    # Type - "/*/*[1]/*[1]/@Sport"
    aType = nodecontent(findfirst("/*/*[1]/*[1]/@Sport", xmldoc))  
    # Id - "/*/*[1]/*/*[1]"
    aId = DateTime(nodecontent(findfirst("/*/*[1]/*/*[1]", xmldoc)),"yyyy-mm-ddTHH:MM:SS.sssZ")
    # Name = "/*/*[1]/*[1]/*[3]"
    aName = nodecontent(findfirst("/*/*[1]/*/*[2]", xmldoc))
    # Lap - "/*/*[1]/*/*[2]"
    # TotalSeconds - "/*/*[1]/*/*[2]/*[1]"
    # DistanceMeters - "/*/*[1]/*/*[2]/*[2]"
    # AverageHeartRateBpm - "/*/*[1]/*/*[2]/*[5]/*[1]"
    # TrackPoints - "/*/*[1]/*/*[2]/*[9]/*"
    tp_Points = findall("/*/*[1]/*/*[2]/*[9]/*", xmldoc)
    aTrackPoints = Array{TrackPoint, size(tp_Points, 1)}[]
    for tp in tp_Points
        tp_time = DateTime(nodecontent(findfirst("./*[1]", tp)), "yyyy-mm-ddTHH:MM:SS.sssZ")
        tp_lat = parse(Float64, nodecontent(findfirst("./*[2]/*[1]", tp)))
        tp_lont = parse(Float64, nodecontent(findfirst("./*[2]/*[2]", tp)))
        tp_bpm = parse(Int32, nodecontent(findfirst("./*[5]/*[1]", tp)))
        tp_dist = parse(Float64, nodecontent(findfirst("./*[4]", tp)))
        tp_alt = parse(Float64, nodecontent(findfirst("./*[3]", tp)))

        aTrackPoints = vcat(aTrackPoints, TrackPoint(tp_time, tp_lat, tp_lont, tp_bpm, tp_dist, tp_alt))
    end

    return 200, TCXRecord(aId, aName, aType, aTrackPoints)
end

function activity_Type(record)
    return record.ActivityType
end

function get_DataFrame(record)
    return DataFrame(record.TrackPoints)
end

end # module:w

