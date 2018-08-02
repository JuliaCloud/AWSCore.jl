#==============================================================================#
# AWSMetadata.jl
#
# Amazon Web Service Metadata
#
# This module extracts JSON service metadata from the AWS JavaScript SDK.
#
# Copyright OC Technology Pty Ltd 2017 - All rights reserved
#==============================================================================#


module AWSMetadata


using JSON
using HTTP
using DataStructures
using Retry


github_headers = ["User-Agent" => "https://github.com/JuliaCloud/AWSCore.jl/blob/master/src/AWSMetadata.jl"]

"""
    json_parse(d)

Parse JSON to OrderedDict to preserve API and documentation order.
"""
json_parse(d) = JSON.parse(d, dicttype=DataStructures.OrderedDict)


"""
    cachehas(file)
    cacheget(file)
    cacheput(file, data)

Cache for files downloaded from the AWS JavaScript SDK on GitHub.
"""
cachedir() = joinpath(@__DIR__, "aws-sdk-js")
cachehas(file) = isfile(joinpath(cachedir(), file))
cacheget(file) = read(joinpath(cachedir(), file), String)

function cacheput(file, data)
    p = joinpath(cachedir(), file)
    mkpath(dirname(p))
    write(p, data)
end


"""
    aws_js_sdk_ls(dirname)

List contents of `dirname` in the AWS JavaScript SDK on GitHub.
"""
function aws_sdk_js_ls(dirname)

    cachename = dirname * ".contents"
    if cachehas(cachename)
        return json_parse(cacheget(cachename))
    end

    url = "https://api.github.com/repos/aws/aws-sdk-js/contents/$dirname"
    println("GET $url...")
    r = HTTP.get(url, github_headers)
    @assert r.status == 200

    r = String(copy(r.body))
    cacheput(cachename, r)
    return json_parse(r)
end


"""
    aws_js_sdk(filename)

Get `filename` from the AWS JavaScript SDK on GitHub.
"""
function aws_sdk_js(filename)

    if cachehas(filename * ".404")
        throw(HTTP.Response(404))
    end
    if cachehas(filename)
        return cacheget(filename)
    end

    url = "https://raw.githubusercontent.com/aws/aws-sdk-js/master/$filename"
    println("GET $url...")
    r = HTTP.get(url, github_headers)
    if r.status != 200
        if r.status == 404
            cacheput(filename * ".404", "")
        end
        throw(r)
    end

    r = String(copy(r.body))
    cacheput(filename, r)
    return r
end


_service_list = OrderedDict()


"""
    services()

Dict of services supported by the AWS JavaScript SDK.
"""
function service_list()

    global _service_list

    if !isempty(_service_list)
        return _service_list
    end

    # Get CamelCase names from metadata.json...
    meta = json_parse(aws_sdk_js("apis/metadata.json"))
    names = Dict(get(info, "prefix", name) => info["name"]
                 for (name, info) in meta)

    # Get list of API filenames...
    files = aws_sdk_js_ls("apis")
    filter!(f -> occursin(r".normal.json$", f["name"]), files)

    l = Pair[]

    for file in files

        # Parse prefix and version from filename...
        filename = join(split(file["name"], '.')[1:end-2],'.')
        filename = split(filename, '-')
        version = join(filename[end-2:end], '-')
        prefix = join(filename[1:end-3], '-')

        push!(l, names[prefix] => Dict("name" => names[prefix],
                                       "version" => version,
                                       "prefix" => prefix))
    end

    _service_list = OrderedDict(l)
    return _service_list
end



"""
    service_definition(service)

Get `service-2.json` file for `service`.

e.g.  `service_definition(services()["SQS"])`
"""
function service_definition(service)

    # Fetch ".normal.json" service definition from AWS JavaScript SDK...
    filename = "apis/$(service["prefix"])-$(service["version"]).normal.json"
    definition = json_parse(aws_sdk_js(filename))

    meta = definition["metadata"]

    # Check that service version matches definition metadata...
    @assert meta["apiVersion"] == service["version"]

    # Check that service definition JSON version is 2.0...
    @assert service["prefix"] in ["sdb", "greengrass", "pinpoint"] ||
            !haskey(definition, "version") ||
            definition["version"] == "2.0"

    # Check that signature version is v4...
    @assert service["prefix"] in ["s3", "sdb", "importexport"] ||
            meta["signatureVersion"] == "v4"

    @assert service["prefix"] in ["sdb", "mobileanalytics", "pinpoint"] ||
            haskey(meta, "uid")

    if !haskey(meta, "uid")
        meta["uid"] = meta["endpointPrefix"] * "-" * meta["apiVersion"]
    end

    # Set signing name to endpoint prefix by default...
    if !haskey(meta, "signingName")
        meta["signingName"] = meta["endpointPrefix"]
    end

    # Add source file info...
    meta["sourceFile"] = filename
    meta["sourceURL"] =
        "https://github.com/aws/aws-sdk-js/blob/master/$filename"

    @protected try
        # Fetch examples...
        filename = "apis/$(service["prefix"])-$(service["version"]).examples.json"
        definition["examples"] = json_parse(aws_sdk_js(filename))["examples"]
    catch e
        @ignore if e.status == 404 end
    end

    @protected try
        # Fetch paginators...
        filename = "apis/$(service["prefix"])-$(service["version"]).paginators.json"
        definition["pagination"] = json_parse(aws_sdk_js(filename))["pagination"]
    catch e
        @ignore if e.status == 404 end
    end

    return definition
end


"""
    service_summary()

Print summary information about available services.
"""
function service_summary()

    services = service_list()

    println("$(length(services)) services:")
    println(join(keys(services), ", "))
    println("")

    protocols = Dict{String,Vector{String}}()
    sigs = Dict{String,Vector{String}}()

    for (name, service) in services

        sd = service_definition(service)
        meta = sd["metadata"]
        pr = meta["protocol"]
        sv = meta["signatureVersion"]

        haskey(protocols, pr) || (protocols[pr] = String[])
        push!(protocols[pr], name)

        haskey(sigs, sv) || (sigs[sv] = String[])
        push!(sigs[sv], name)
    end

    println("$(length(protocols)) protocols: $(join(keys(protocols), ", "))")
    for (p, l) in protocols
        println("$p: ")
        println(join(l, ", "))
        println("")
    end

    println("$(length(sigs)) signature versions: $(join(keys(sigs), ", "))")
    for (s, l) in sigs
        println("$s: ")
        println(join(l, ", "))
        println("")
    end
end



end # module AWSMetadata


#==============================================================================#
# End of file.
#==============================================================================#
