#==============================================================================#
# AWSService.jl
#
# Copyright OC Technology Pty Ltd 2017 - All rights reserved
#==============================================================================#

using Requests.get
using DataStructures

json_parse(d) = JSON.parse(d, dicttype=DataStructures.OrderedDict)


"""
    aws_js_sdk_ls(dirname)

List contents of `dirname` in the AWS JavaScript SDK on GitHub.
"""

function aws_sdk_js_ls(dirname)

    r = get(URI(string("https://api.github.com",
                       "/repos/aws/aws-sdk-js/contents/",
                       dirname)))
    @assert r.status == 200

    r = json_parse(String(r.data))
end


"""
    aws_js_sdk(filename)

Get `filename` from the AWS JavaScript SDK on GitHub.
"""

function aws_sdk_js(filename)

    r = get(URI(string("https://raw.githubusercontent.com",
                       "/aws/aws-sdk-js/master/",
                       filename)))

    @assert r.status == 200

    String(r.data)
end


"""
    services()

Dict of services supported by the AWS JavaScript SDK.
"""

function service_list()

    # Get CamelCase names from metadata.json...
    meta = json_parse(aws_sdk_js("apis/metadata.json"))
    names = Dict(get(info, "prefix", name) => info["name"]
                 for (name, info) in meta)

    # Get list of API filenames...
    files = aws_sdk_js_ls("apis")
    filter!(f -> ismatch(r".normal.json$", f["name"]), files)

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

    return OrderedDict(l)
end



"""
    service_definition(service)

Get `service-2.json` file for `service`.
    
e.g.  `service_definition(services()["sqs"])`
"""

function service_definition(service)

    filename = "apis/$(service["prefix"])-$(service["version"]).normal.json"
    definition = json_parse(aws_sdk_js(filename))
    @assert definition["version"] == "2.0"

    meta = definition["metadata"]
    @assert meta["apiVersion"] == service["version"]
    @assert haskey(meta, "serviceFullName")

    if !haskey(meta, "signingName")
        meta["signingName"] = meta["endpointPrefix"]
    end
    meta["juliaModule"] = "AWS$(service["name"])"
    meta["sourceFile"] = filename
    meta["sourceURL"] = 
        "https://github.com/aws/aws-sdk-js/blob/master/$filename"
    
    return definition
end

function service_shape(service, name)

    shape = service["shapes"][name]

    if shape["type"] == "structure"
        return "Dict($(join(["$m => $(service_shape(service, i["shape"]))"
                      for (m, i) in shape["members"]], "\n")))\n"
    end

    if shape["type"] == "list"
        return "[$(service_shape(service, shape["member"]["shape"]))...]"
    end

    if shape["type"] == "string"
        return "::String"
    end
end

function service_operation(service, operation, info)

    @assert !haskey(info, "input") || isa(info["input"], OrderedDict)
    @assert !haskey(info, "output") || isa(info["output"], OrderedDict)

    name = uncamel(operation)
    input = ""
    inputdoc = ""
    if haskey(info, "input")
        input = "::$(info["input"]["shape"])"
        inputdoc = "$input = $(service_shape(service, info["input"]["shape"]))"
    end

    output = ""
    if haskey(info, "output")
        output = "\n\nReturns `$(info["output"]["shape"])`"
    end

    errors = ""
    if haskey(info, "errors")
        errors = orjoin(["`$(e["shape"])`" for e in (info["errors"])])
        errors = "\n\nMay throw: $errors."
    end

    """
    \"\"\"
        $name($input)

    $inputdoc

    $(info["documentation"])$output$errors
    \"\"\"

    function $name(in)
    end


    """
end

function service_interface(service)

    meta = service["metadata"]
    m = meta["juliaModule"]

    string(
"""
#===============================================================================
# $m.jl
#
# This file is generated from:
# $(meta["sourceURL"])
#===============================================================================
""",

   (service_operation(service, o, i) for (o, i) in service["operations"])...,

"""
#===============================================================================
# End of file
#===============================================================================
"""
    )
end


function service_documentation(service)

    meta = service["metadata"]
    m = meta["juliaModule"]
    
    """
    # $m

    $(service["documentation"])

    This document is generated from
    [$(meta["sourceFile"])]($(meta["sourceURL"])).

    ```@meta
    CurrentModule = $m
    ```

    ```@index
    Pages = ["$m.md"]
    ```

    ```@autodocs
    Modules = [$m]
    ```
    """

end


uncamel(s) = lowercase(replace(s, r"([a-z])([A-Z])", s"\1_\2"))

orjoin(l) = length(l) == 1 ? l[1] : "$(join(l[1:end-1], ", ")) or $(l[end])"


#==============================================================================#
# End of file.
#==============================================================================#
