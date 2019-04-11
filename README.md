https://travis-ci.com/xue35/TCX.jl.svg?branch=master

# TCX.jl
TCX.jl intends to provide an list of Julia modules to access Training Center XML(TCX) files. This project is inspired by [vkurup/python-tcxparser](https://github.com/vkurup/python-tcxparser).

# Installation
```julia
julia> using Pkg; Pkg.add("TCX");
```

# Usage

### Basic usage
```julia
using TCX

err, tcx = TCX.parse_tcx_file("my_marathon.tcx")
# TODO
println(tcx.distance)
println(tcx.duration)
println(tcx.average_speed)
println(tcx.average_pace)

```

### Load multiple TCX for analysis
```julia
using TCX, DataFrames
err, tcx = TCX.parse_tcx_file("/my_running_logs/")
get_DataFrame(tcx)

```
# License
MIT License

# Contact
Please contact me if any question or comment.

# Ref
* [Garmin's Training Center Database XML (TCX) Schema](http://www8.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd)
* [User profile extension Schema](http://www8.garmin.com/xmlschemas/UserProfileExtensionv1.xsd)
* [Activity extension schema](Activity extension Schema)

