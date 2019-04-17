module TCX
using EzXML, Dates, DataFrames, Geodesy
import Base.show

export parse_tcx_dir, parse_tcx_file, getActivityType, getDataFrame, getDistance, getDistance2, getDuration, getAverageSpeed, getAveragePace

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
    DistanceStatic::Float64
    DurationStatic::Float64
    HeartRate::Int32
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
           @warn "Invalid XML document: $file_path"
           return 400, nothing
       else
           return 500, nothing
       end
    end

    root_element = root(xmldoc)
    # Check if TCX
    if nodename(root_element) != "TrainingCenterDatabase"
        @warn "Invalid TCX document: $file_path"
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
    aTime = parse(Float64, nodecontent(findfirst("/*/*[1]/*/*[2]/*[1]", xmldoc)))
    aDistance = parse(Float64, nodecontent(findfirst("/*/*[1]/*/*[2]/*[2]", xmldoc)))
    # DistanceMeters - "/*/*[1]/*/*[2]/*[2]"
    # AverageHeartRateBpm - "/*/*[1]/*/*[2]/*[5]/*[1]"
    aHeartRateBpm = parse(Int32, nodecontent(findfirst("/*/*[1]/*/*[2]/*[5]/*[1]", xmldoc)))
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

    return 200, TCXRecord(aId, aName, aType, aDistance, aTime, aHeartRateBpm, aTrackPoints)
end

function parse_tcx_dir(path::String)
    if ispath(path) == false
        @warn "Invalid path: $path"
        return 500, nothing
    end

    tcxArray = Array{TCXRecord}[]
    searchdir(path, key) = filter(x->occursin(key, x), readdir(path))

    for f in searchdir(path, ".tcx")
        err, tcx = parse_tcx_file(joinpath(path, f))
        if err == 200
            tcxArray = vcat(tcxArray, tcx)
        end
    end

    if length(tcxArray) > 0
        return 200, tcxArray
    else
        return 404, nothing
    end
end

function getActivityType(record::TCXRecord)
    return record.ActivityType
end

function getDataFrame(record::TCXRecord)
    return DataFrame(record.TrackPoints)
end

function getDataFrame(tcxArray::Array{Any, 1})
    aTP = Array{TrackPoint}[]
    for t in tcxArray
        aTP = vcat(aTP, t.TrackPoints)
    end
    return DataFrame(aTP)
end

function getDistance(record::TCXRecord)
    return record.DistanceStatic
end

function getDistance2(record::TCXRecord)
    # Calculate distance from track points using Geodesty
    return 0
end
function getAverageSpeed(record::TCXRecord)
    return (record.DistanceStatic /1000) / (record.DurationStatic / 3600)  # km/h
end

function getAveragePace(record::TCXRecord)
    return (record.DurationStatic / 60) / (record.DistanceStatic / 1000) # min/km
end

function getDuration(record::TCXRecord)
    return record.DurationStatic
end

Base.show(io::IO, tcx::TCXRecord) = print(io, "$(tcx.ActivityType) $(tcx.DistanceStatic/1000) km at $(tcx.Id) for $(tcx.DurationStatic) seconds.")
end #module_end

