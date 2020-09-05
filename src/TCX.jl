module TCX
using EzXML, Dates, DataFrames, Geodesy, Mocking
import Base.show

export parse_tcx_dir, parse_tcx_file, getActivityType, getDataFrame, getDistance, getDistance2, getDuration, getAverageSpeed, getAveragePace

const OK = 200
const CLIENT_ERROR = 400
const CLIENT_TCX_ERROR = 401
const NOT_FOUND = 404
const SERVER_ERROR = 500

struct TrackPoint
    Time::DateTime
    Latitude::Float64
    Longtitude::Float64
    HeartRateBpm::Int32
    AltitudeMeter::Float64
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

function parse_tcx(tcxdoc::EzXML.Document)
    root_element = root(tcxdoc)
    # Check if TCX
    if nodename(root_element) != "TrainingCenterDatabase"
        return CLIENT_TCX_ERROR, nothing
    end

    # Type - "/*/*[1]/*[1]/@Sport"
    aType = nodecontent(findfirst("/*/*[1]/*[1]/@Sport", tcxdoc))
    # Id - "/*/*[1]/*/*[1]"
    xid = nodecontent(findfirst("/*/*[1]/*/*[1]", tcxdoc))

    aId = convertToDateTime(xid)
    # Name = "/*/*[1]/*[1]/*[3]"
    aName = nodecontent(findfirst("/*/*[1]/*/*[2]", tcxdoc))
    # Lap - "/*/*[1]/*/*[2]"
    # TotalSeconds - "/*/*[1]/*/*[2]/*[1]"
    aTime = parse(Float64, nodecontent(findfirst("/*/*[1]/*/*[2]/*[1]", tcxdoc)))
    aDistance = parse(Float64, nodecontent(findfirst("/*/*[1]/*/*[2]/*[2]", tcxdoc)))
    # DistanceMeters - "/*/*[1]/*/*[2]/*[2]"
    # AverageHeartRateBpm - "/*/*[1]/*/*[2]/*[5]/*[1]"
    xbpm = findfirst("/*/*[1]/*/*[2]/*[5]/*[1]", tcxdoc)
    if xbpm === nothing
        aHeartRateBpm = 0
    else
        aHeartRateBpm = parse(Int32, nodecontent(xbpm))
    end
    # TrackPoints - "/*/*[1]/*/*[2]/*[9]/*"
    tp_Points = findall("/*/*[1]/*/*[2]/*[9]/*", tcxdoc)
    aTrackPoints = Array{TrackPoint, size(tp_Points, 1)}[]
    for tp in tp_Points
        xtime = nodecontent(findfirst("./*[local-name()='Time']", tp))
        tp_time = convertToDateTime(xtime)
        tp_lat = parseNode(Float64, "./*[local-name()='Position']/*[local-name()='LatitudeDegrees']", tp)
        tp_lont = parseNode(Float64, "./*[local-name()='Position']/*[local-name()='LatitudeDegrees']", tp)
        tp_bpm = parseNode(Int32, "./*[local-name()='HeartRateBpm']/*[1]", tp)
        tp_dist = parseNode(Float64, "./*[local-name()='TPX']", tp)
        tp_alt = parseNode(Float64, "./*[local-name()='AltitudeMeters']", tp)

        aTrackPoints = vcat(aTrackPoints, TrackPoint(tp_time, tp_lat, tp_lont, tp_bpm, tp_dist, tp_alt))
    end

    return OK, TCXRecord(aId, aName, aType, aDistance, aTime, aHeartRateBpm, aTrackPoints)
end

function parse_tcx_str(str::String)
    try
        status, parsed_tcx = parse_tcx(EzXML.parsexml(str))
        warn_on_tcx_error(status, str, false)
        return status, parsed_tcx
    catch e
        if isa(e, EzXML.XMLError)
            @error "Invalid XML string: $str"
            return CLIENT_ERROR, nothing
        end
    end
end

function parse_tcx_file(file::String)
    file_path = abspath(file)
    if isfile(file_path) == false
        return NOT_FOUND, nothing
    end
    xmldoc = try readxml(file_path)
    catch e
       if isa(e, EzXML.XMLError)
           # Not a valid XML document
           @warn "Invalid XML document: $file_path"
           return CLIENT_ERROR, nothing
       else
           return SERVER_ERROR, nothing
       end
    end

    status, parsed_tcx = parse_tcx(xmldoc)
    warn_on_tcx_error(status, file_path, true)

    return status, parsed_tcx
end

function warn_on_tcx_error(status::Int, thing::String, isFile::Bool)
    if status == CLIENT_TCX_ERROR
        @warn "Invalid TCX $(isFile ? document : string): $(thing)"
    end
end

#=
= Parses an XML node based on an XPATH and data type.
=
= If the node is a `nothing` value, the function returns the data
= type's version of 0
=#
function parseNode(dType, path, node)
    node_check = findfirst(path, node)
    if node_check !== nothing
        return parse(dType, nodecontent(node_check))
    else
        return dType(0)
    end
end

function parse_tcx_dir(path::String)
    if ispath(path) == false
        @warn "Invalid path: $path"
        return SERVER_ERROR, nothing
    end

    tcxArray = Array{TCXRecord}[]
    searchdir(path, key) = filter(x->occursin(key, x), readdir(path))

    for f in searchdir(path, ".tcx")
        err, tcx = parse_tcx_file(joinpath(path, f))
        if err == OK
            tcxArray = vcat(tcxArray, tcx)
        end
    end

    if length(tcxArray) > 0
        return OK, tcxArray
    else
        return NOT_FOUND, nothing
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
    total_distance = 0
    df = getDataFrame(record)
    num_of_rows = size(df, 1)
    for i in 1:num_of_rows
        if i < num_of_rows
            total_distance += distance(
                                       LLA(df[i, :Latitude], df[i, :Longtitude], df[i, :AltitudeMeter]),
                                       LLA(df[i+1, :Latitude], df[i+1, :Longtitude], df[i+1, :AltitudeMeter])
               )
        end
    end
    return total_distance
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

#=
= Converts a datetime string into the proper datetime based on string length.
=
= Will assume that an ArgumentError is due to
= https://github.com/JuliaLang/julia/issues/23049 and will attempt to work
= around this.
=#
function convertToDateTime(datestr::String)::DateTime
    m = match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z?|\.\d{1,3}Z?)", datestr)
    format_prefix = "yyyy-mm-ddTHH:MM:SS"
    if m === nothing
        msg = "'$(datestr)' is improperly formatted. Must be in the form "
        msg = msg * "'$(format_prefix)Z' or '$(format_prefix).sssZ'"
        throw(ArgumentError(msg))
    else
        suffix = replace(m.captures[1], r"\d" => "s")
        try
            return @mock DateTime(m.match, format_prefix * suffix)
        catch e
            if isa(e, ArgumentError)
                # OK! FINE! NO Z THEN!
                return DateTime(m.match[1:end-1], format_prefix * (suffix[1:end-1]))
            else
                throw(e)
            end
        end
    end
end

Base.show(io::IO, tcx::TCXRecord) = print(io, "$(tcx.ActivityType) $(tcx.DistanceStatic/1000) km at $(tcx.Id) for $(tcx.DurationStatic) seconds.")
end #module_end
