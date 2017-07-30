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


function service_args(service, name)

    shape = service["shapes"][name]
    @assert shape["type"] == "structure"

    join((name for (name, info) in shape["members"]), ", ")
end
    

function service_shape(service, name, isrequired=false, pad="")

    shape = service["shapes"][name]
    t = shape["type"]

    @assert pad != "" || t == "structure"

    padmore = pad * "    "

    result = ""

    if t == "structure"

        if pad == ""
            return join(
                ["- `$m` = $(service_shape(service,
                                            i["shape"],
                                            haskey(shape, "required")
                                               && m in shape["required"],
                                            padmore))\n"
                 for (m, i) in shape["members"]], "\n")
        end

        if length(shape["members"]) == 1
            m, i = first(shape["members"])
            required = haskey(shape, "required") && m in shape["required"]
            return service_shape(service, i["shape"], required, pad)
        else 
            result = "Dict(\n$padmore$(join(
                ["\"$m\" => $(service_shape(service,
                                            i["shape"],
                                            haskey(shape, "required")
                                                && m in shape["required"],
                                            padmore))"
                 for (m, i) in shape["members"]], ",\n$padmore"))\n$pad)"
        end
    end

    if t == "list"
        result = "[\n$padmore$(service_shape(service,
                                             shape["member"]["shape"],
                                             false,
                                             padmore))...]"
    end

    if t == "string"
        if haskey(shape, "enum")
            result = orjoin(["\"$v\"" for v in shape["enum"]])
        else
            result = "::String"
        end
    end

    if t == "boolean"
        result = "::Bool"
    end

    if isrequired
        result *= " *"
    end

    if pad == "    "
        if contains(result, "\n")
            return "\n$pad```\n$pad$result\n$pad```"
        else
            return "`$result`"
        end
    else
        return result
    end
end

function service_operation(service, operation, info)

    @assert !haskey(info, "input") || isa(info["input"], OrderedDict)
    @assert !haskey(info, "output") || isa(info["output"], OrderedDict)

    name = uncamel(operation)
    input = ""
    inputdoc = ""
    if haskey(info, "input")
        input = " $(service_args(service, info["input"]["shape"]))"
        inputdoc = string("\n\n# Arguments\n\n",
                          service_shape(service, info["input"]["shape"]))
    end

    output = ""
    if haskey(info, "output")
        output = "\n\n# Returns\n\n`$(info["output"]["shape"])`"
    end

    errors = ""
    if haskey(info, "errors")
        errors = orjoin(["`$(e["shape"])`" for e in (info["errors"])])
        errors = "\n\n# Exceptions\n\n$errors."
    end

    api_ref = service_api_reference_url(service, operation)

    request = "$(service["metadata"]["endpointPrefix"])_request"
    method = "\"$(info["http"]["method"])\""
    resource = "\"$(info["http"]["requestUri"])\""
    """
    \"\"\"
        $name(::AWSConfig;$input)

    $(info["documentation"])$inputdoc$output$errors
    See also: [AWS API Documentation]($api_ref)
    \"\"\"

    function $name(aws::AWSConfig; args...)
        $request(aws, $method, $resource, \"$operation\", args)
    end


    """
end


function service_request_function(service)

    meta = service["metadata"]

"""
function $(meta["endpointPrefix"])_request(
    aws::AWSConfig, verb::String, resource::String, args)

    meta = $meta

    service_request(aws, meta, verb, resource, args)
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

    service_request_function(service),

   (service_operation(service, o, i) for (o, i) in service["operations"])...,

"""
#===============================================================================
# End of file
#===============================================================================
"""
    )
end


function service_api_reference_url(service, operation)

    uid = service["metadata"]["uid"]
    "https://docs.aws.amazon.com/goto/WebAPI/$uid/$operation"
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
