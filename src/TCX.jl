module TCX
using EzXML, Dates, DataFrames

export parse_tcx_file, activity_Type, activity_Id, start_Time, distance, duration, avg_HeartRateBpm, get_DataFrame

struct TrackPoint
    Time::String
    Latitude::String
    Longtitude::String
    HeartRateBpm::String
    AltitueMeter::String
    DistanceMeter::String
end

struct TCXRecord
    Id::String
    Name::String
    ActivityType::String
    TrackPoints::Array{TrackPoint}
end

function parse_tcx_file(file::String)
    file_path = abspath(file)
    if isfile(file_path) == false
        return 404, nothing
    end

    xmldoc = try readxml(file_path)
    catch e
       if isa(e, XMLError)
           # Not a valid XML document
           println("An invalid XML document that fails EzXML::readxml().")
           return 400, nothing
       else
           return 500, nothing
       end
    end

    root_element = root(xmldoc)
    # Check if TCX
    if nodename(root_element) != "TrainingCenterDatabase"
        println("An invalid TCX document that has wrong root node name.")
        return 400, nothing
    end

    # Type - "/*/*[1]/*[1]/@Sport"
    aType = nodecontent(findfirst("/*/*[1]/*[1]/@Sport", xmldoc))  
    # Id - "/*/*[1]/*/*[1]"
    aId = nodecontent(findfirst("/*/*[1]/*/*[1]", xmldoc))
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
        tp_time = nodecontent(findfirst("./*[1]", tp))
        tp_lat = nodecontent(findfirst("./*[2]/*[1]", tp))
        tp_lont = nodecontent(findfirst("./*[2]/*[2]", tp))
        tp_bpm = nodecontent(findfirst("./*[5]/*[1]", tp))
        tp_dist = nodecontent(findfirst("./*[4]", tp))
        tp_alt = nodecontent(findfirst("./*[3]", tp))

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

