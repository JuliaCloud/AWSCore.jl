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

    url = "https://api.github.com/repos/aws/aws-sdk-js/contents/$dirname"
    println("GET $url...")
    r = get(URI(url))
    @assert r.status == 200

    r = json_parse(String(r.data))
end


"""
    aws_js_sdk(filename)

Get `filename` from the AWS JavaScript SDK on GitHub.
"""

function aws_sdk_js(filename)

    url = "https://raw.githubusercontent.com/aws/aws-sdk-js/master/$filename"
    println("GET $url...")
    r = get(URI(url))
    @assert r.status == 200

    String(r.data)
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

    _service_list = OrderedDict(l)
    return _service_list
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
    @assert meta["signatureVersion"] == "v4"

    if !haskey(meta, "signingName")
        meta["signingName"] = meta["endpointPrefix"]
    end
    meta["juliaModule"] = "AWS_$(service["name"])"
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


function service_shape_doc(service, name, pad="")

    shape = service["shapes"][name]
    t = shape["type"]

    @assert pad != "" || t == "structure"

    padmore = pad * "    "

    if t == "structure"

        if pad == ""

            result = ""

            for (m, i) in shape["members"]
                s = service_shape_doc(service, i["shape"], padmore)
                d = replace(html2md(get(i, "documentation", "")), "\$", "\\\$")
                r = haskey(shape, "required") && m in shape["required"]
                if !contains(s, "\n")
                    m = "$m$s"
                    s = ""
                else
                    s = "```\n$padmore$s\n```"
                end
                result *= "## `$m` $(r ? "-- *Required*" : "")\n$d\n$s\n\n"
            end

            return result
        end

        if length(shape["members"]) == 1
            m, i = first(shape["members"])
            r = haskey(shape, "required") && m in shape["required"]
            return string(service_shape_doc(service, i["shape"], pad),
                          r ? " *" : "")
        end

        members = []
        for (m, i) in shape["members"]
            s = service_shape_doc(service, i["shape"], padmore)
            r = haskey(shape, "required") && m in shape["required"]
            push!(members, "$m $(r ? "*" : "") => $s")
        end

        return "Dict(\n$padmore$(join(members, ",\n$padmore"))\n$pad)"
    end

    if t == "list"
        s = service_shape_doc(service, shape["member"]["shape"], pad)
        return  "[$s...]"
    end

    if t == "map"
        return "::Dict{String,String}"
    end

    if t == "string"
        if haskey(shape, "enum")
            return ": $(orjoin(["\"$v\"" for v in shape["enum"]]))"
        else
            return "::String"
        end
    end

    if t in ["integer", "long"]
        return "::Int"
    end

    if t == "boolean"
        return "::Bool"
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
                          service_shape_doc(service, info["input"]["shape"]))
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

    $(html2md(info["documentation"]))$inputdoc$output$errors

    See also: [AWS API Documentation]($api_ref)
    \"\"\"

    $name(aws::AWSConfig; args...) = $name(aws, args)

    function $name(aws::AWSConfig, args)
        $request(aws, $method, $resource, \"$operation\", args)
    end

    """
end


function service_request_function(service)

    meta = service["metadata"]

    protocol = replace(meta["protocol"], "-", "_")

"""
function $(meta["endpointPrefix"])_request(
    aws::AWSConfig, verb::String, resource::String, operation::String, args)

    meta = $meta

    AWSCore.service_$protocol(aws, meta, verb, resource, operation, args)
end
"""
end


function service_interface(service)

    meta = service["metadata"]
    m = meta["juliaModule"]

    string(
"""
#==============================================================================#
# $m.jl
#
# This file is generated from:
# $(meta["sourceURL"])
#==============================================================================#

__precompile__()

module $m

using AWSCore
using DataStructures


""",

    service_request_function(service),

    "\n\n",

    (service_operation(service, o, i) for (o, i) in service["operations"])...,

"""


end # module $m


#==============================================================================#
# End of file
#==============================================================================#
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

    $(html2md(service["documentation"]))

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

function service_generate(name)

    service = service_list()[name]
    definition = service_definition(service)
    meta = definition["metadata"]

    write("$(meta["juliaModule"]).jl", service_interface(definition))
    write("$(meta["juliaModule"]).md", service_documentation(definition))
end


function generate_all()

    service_list()

    services = [
        "Athena",
        "Batch",
        "CloudFront",
        "DynamoDB",
        "EC2",
        "SES",
        "CloudWatchLogs",
        "CloudWatchEvents",
        "Glacier",
        "IAM",
        "Lambda",
        "MachineLearning",
        "RDS",
        "Route53",
        "Route53Domains",
        "S3",
        "SimpleDB",
        "SNS",
        "SQS",
        "DynamoDBStreams",
        "XRay"
    ]

#    @sync for s in services
#        @async service_generate(s)
#    end

    doc = ""

    for s in services
        doc *= "using AWS_$s\n"
    end

    doc *= """
    makedocs(modules = [$(join(["AWS_$s" for s in services], ","))],
             format = :html,
             sitename = awscore.jl,
             pages = ["AWSCore.jl" => "index.md",
                      $(join(["\"AWS_$s.jl\" => \"AWS_$s.md\""
                              for s in services], ","))
             ])
    """

    println(doc)
end


uncamel(s) = lowercase(replace(s, r"([a-z])([A-Z])", s"\1_\2"))

orjoin(l) = length(l) == 1 ? l[1] : "$(join(l[1:end-1], ", ")) or $(l[end])"

using NodeJS

function html2md(html)

    #run(`$(npm_cmd()) install to-markdown`)
    #run(`$(npm_cmd()) install get-stdin`)

    p_out, p_in, p = readandwrite(`$(nodejs_cmd()) -e """
        require('get-stdin')().then(str => {
            process.stdout.write(require('to-markdown')(str))
        })
    """`)
    write(p_in, html)
    flush(p_in)
    close(p_in)
    res = readstring(p_out)
    close(p_out)
    return res

end

#==============================================================================#
# End of file.
#==============================================================================#
