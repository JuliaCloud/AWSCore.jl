#==============================================================================#
# AWSAPI.jl
#
# Amazon Web Service API Generation
#
# This module use service definitions from AWSMetadata.jl to generate Julia
# API bindings and documentation.
#
# Copyright OC Technology Pty Ltd 2017 - All rights reserved
#==============================================================================#


module AWSAPI


using AWSMetadata
using HTML2MD
using DataStructures
using JSON


sdk_module_name(service_name) = "AWSSDK.$(service_name)"


"""
    uncamel(s)

Transform CamelCase to lowercase_with_underscores.
"""
uncamel(s) = lowercase(replace(s, r"([a-z])([A-Z])" => s"\1_\2"))


"""
    orjoin(words)

Join `words` with commas and "or". e.g. "one, two or three".
"""
orjoin(words) = join(words, ", ", " or ")


function is_simple_post_service(service)
    return (service["metadata"]["protocol"] in ["json", "query", "ec2"]
        &&  service["metadata"]["endpointPrefix"] != "importexport")
end

is_rest_service(service) = occursin(r"^rest", service["metadata"]["protocol"])


function member_name(service, name, info)

    if haskey(info, "locationName")
        name = info["locationName"]
    else
        shape = service["shapes"][info["shape"]]
        if get(shape, "flattened", false)
            if shape["type"] == "list"
                name = shape["member"]["shape"]
                name = get(shape["member"], "locationName", name)
            end
        end
    end

    if service["metadata"]["signingName"] == "ec2"
        name = string(uppercase(name[1]), name[2:end])
    end

    if get(info, "location", "") in ["header", "headers"]
        name = "*header:* $name"
    end

    return name
end


function service_args(service, name)

    shape = service["shapes"][name]
    @assert shape["type"] == "structure"

    m = filter((n, i)::Pair -> (n in get(shape, "required", [])), shape["members"])

    args = join(["$(member_name(service, name, info))="
                 for (name, info) in m], ", ")
    if length(m) < length(shape["members"])
        if args != ""
            args *= ", "
        end
        args *= "<keyword arguments>"
    end

    return args
end


function service_shape_doc(service, name, pad="", stack=[])

    shape = service["shapes"][name]
    t = shape["type"]

    # No infinite recursion...
    if name in stack
        println("Interrupting recursion to $name from: $(join(stack, " -> "))")
        return t
    end

    push!(stack, name) ; try

    @assert pad != "" || t == "structure"

    padmore = pad * "    "

    if t == "structure"

        if pad == ""

            result = ""

            for (m, i) in shape["members"]
                n = member_name(service, m, i)
                s = service_shape_doc(service, i["shape"], padmore, stack)
                d = html2md(get(i, "documentation", ""))
                r = haskey(shape, "required") && m in shape["required"]
                n = "$n = "
                if !occursin("\n", s)
                    n = "$n$s"
                    s = ""
                else
                    brief = join(map(strip, split(s, "\n")[[1,end]]), " ... ")
                    s = "```\n $n$s\n```"
                    n = "$n$brief"
                end

                result *= "## `$n`$(r ? " -- *Required*" : "")\n$d\n$s\n\n"
            end

            return result
        end

        members = []
        for (m, i) in shape["members"]
            n = member_name(service, m, i)
            s = service_shape_doc(service, i["shape"], padmore, stack)
            r = haskey(shape, "required") && m in shape["required"]
            push!(members, "\"$n\" => $(r ? "<required>" : "") $s")
        end
        if length(members) == 1
            return "[$(members[1])]"
        else
            return "[\n$padmore$(join(members, ",\n$padmore"))\n$pad]"
        end
    end

    if t == "list"
        s = service_shape_doc(service, shape["member"]["shape"], pad, stack)
        return  "[$s, ...]"
    end

    if t == "map"
        return "::Dict{String,String}"
    end

    if t == "string"
        if haskey(shape, "enum")
            return orjoin(["\"$v\"" for v in shape["enum"]])
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

    return t

    finally pop!(stack) end
end


function pretty(d::AbstractDict, dict = "Dict()", pad="")
    dict[1:end-1] * "\n" *
    join([string(pad, "    \"", k, "\" => ", pretty(v, dict, pad * "    "))
          for (k, v) in d], ",\n") *
    "\n$pad" * dict[end:end]
end

function pretty(v::Vector, dict, pad)
    "[\n" *
    join([string(pad, "    ", pretty(i, dict, pad * "    ")) for i in v], ",\n") *
    "\n$pad]"
end

function pretty(s::String, args...)
    s = replace(s, "\$" => "\\\$")

    # Work around for https://github.com/JuliaLang/julia/pull/22800
    s = replace(s, r"([^\\])\\([^ntrebfva\\'\"$`0-9])" => s"\1\\\\\2")

    return "\"$s\""
end


pretty(n, args...) = string(n)


function service_operation(service, operation, info)

    @assert !haskey(info, "input") || isa(info["input"], OrderedDict)
    @assert !haskey(info, "output") || isa(info["output"], OrderedDict)

    name = uncamel(operation)
    input = ""
    inputdoc = ""
    if haskey(info, "input")
        input = service_args(service, info["input"]["shape"])
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

    request = service_request_function_name(service)
    if is_simple_post_service(service)
        @assert info["http"]["method"] == "POST"
        @assert info["http"]["requestUri"] == "/"
        method = ""
        resource = ""
    else
        method = " \"$(info["http"]["method"])\","
        resource = " \"$(info["http"]["requestUri"])\","
    end

    example = ""
    if haskey(service, "examples") && haskey(service["examples"], operation)

        for eg in service["examples"][operation]
            example *= """

            # Example: $(eg["title"])

            $(get(eg,"description", ""))
            """

            if haskey(eg, "input")
                example *= """

                Input:
                ```
                $(pretty(eg["input"], "[]"))
                ```
                """
            end
            if haskey(eg, "output")
                example *= """

                Output:
                ```
                $(pretty(eg["output"]))
                ```
                """
            end
        end
    end

    operation_name = operation
    operation = is_rest_service(service) ? "" : " \"$operation\","
    resource = replace(resource, "\$" => "\\\$")

    if haskey(info, "input")
        sig1 = "$name([::AWSConfig], arguments::Dict)"
        sig2 = "$name([::AWSConfig]; $input)"
        sig3 = "$request([::AWSConfig],$method$resource$operation arguments::Dict)"
        sig4 = "$request([::AWSConfig],$method$resource$operation $input)"
    else
        sig1 = "$name([::AWSConfig])"
        sig2 = ""
        sig3 = "$request([::AWSConfig],$method$resource$operation)"
        sig4 = ""
    end

    @assert !occursin(r"[{][^{}]+[}]", resource) || is_rest_service(service)

    m = service["metadata"]["juliaModule"]

    """
    \"\"\"
        using AWSSDK.$m.$name
        $sig1
        $sig2

        using AWSCore.Services.$request
        $sig3
        $sig4

    # $operation_name Operation

    $(html2md(get(info, "documentation", "")))$inputdoc$output$errors
    $example
    See also: [AWS API Documentation]($api_ref)
    \"\"\"
    @inline $name(aws::AWSConfig=default_aws_config(); args...) = $name(aws, args)

    @inline $name(aws::AWSConfig, args) = AWSCore.Services.$request(aws,$method$resource$operation args)

    @inline $name(args) = $name(default_aws_config(), args)


    """
end


function service_request_function_name(service)

    join(split(service["metadata"]["uid"], ['.', '-'])[1:end-3], "_")
end


function service_request_function(service)

    meta = service["metadata"]

    protocol = replace(meta["protocol"], "-" => "_")
    if protocol == "ec2"
        protocol = "query"
    end
    name = service_request_function_name(service)

    args = ["service      = \"$(meta["signingName"])\"",
            "version      = \"$(meta["apiVersion"])\""]

    if meta["endpointPrefix"] != meta["signingName"]
        push!(args,
            "endpoint     = \"$(meta["endpointPrefix"])\"")
    end

    if is_simple_post_service(service)
        verb = ""
        resource = ""
    else
        push!(args,
            "verb         = verb",
            "resource     = resource")
        verb = "verb, "
        resource = "resource, "
    end

    if meta["protocol"] == "json"
        json_version = get(meta, "jsonVersion", "1.0")
        if json_version == "1"
            json_version = "1.0"
        end
        push!(args,
            "json_version = \"$json_version\"",
            "target       = \"$(get(meta, "targetPrefix", ""))\"")
    end

    if !is_rest_service(service)
        push!(args,
            "operation    = operation")
        operation = "operation, "
    else
        operation = ""
    end
    push!(args,
            "args         = args")

"""
function $name(aws::AWSConfig, $(verb)$(resource)$(operation)args=[])

    AWSCore.service_$protocol(
        aws;
        $(join(args, ",\n        ")))
end

$name($(verb)$(resource)$(operation)args=[]) =
    $name(default_aws_config(), $(verb)$(resource)$(operation)args)

$name(a...; b...) = $name(a..., b)
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


""",

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
    # AWSSDK.$m

    $(html2md(get(service, "documentation", "")))

    This document is generated from
    [$(meta["sourceFile"])]($(meta["sourceURL"])).
    See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

    ```@index
    Pages = ["AWSSDK.$m.md"]
    ```

    ```@autodocs
    Modules = [AWSSDK.$m]
    ```
    """

end

function service_generate(name, definition)

    meta = definition["metadata"]
    println(meta["serviceFullName"])
    meta["juliaModule"] = name

    sdk_dir = joinpath(@__DIR__, "..", "..", "AWSSDK")
    src_path = joinpath(sdk_dir, "src", "$name.jl")
    mkpath(dirname(src_path))
    write(src_path, service_interface(definition))

    write(joinpath(@__DIR__, "..", "..", "AWSCoreDoc", "src", "AWSSDK.$name.md"),
          service_documentation(definition))
end


function generate_doc(services)

    doc = """
        using Documenter
        using AWSCore
        using AWSS3
        using AWSSES
        using AWSSQS
        using AWSSNS
    """

    for s in services
        doc *= "using $(sdk_module_name(s))\n"
    end

    doc *= """
    makedocs(modules = [AWSCore, AWSS3, AWSSES, AWSSQS, AWSSNS,
                        $(join([sdk_module_name(s) for s in services], ","))],
             format = :html,
             sitename = "AWSCore.jl",
             pages = ["AWSCore.jl" => "index.md",
                      "AWSS3.jl" => "AWSS3.md",
                      "AWSSQS.jl" => "AWSSQS.md",
                      "AWSSES.jl" => "AWSSES.md",
                      "AWSSNS.jl" => "AWSSNS.md",
                      $(join(["\"$m.jl\" => \"$m.md\""
                              for m in map(sdk_module_name, services)], ","))
             ])
    """

    return (doc)
end


function generate_all()

    services = keys(AWSMetadata.service_list())

    request_functions = []
    sdk = []

    for name in services
        service = AWSMetadata.service_list()[name]
        definition = AWSMetadata.service_definition(service)
        service_generate(name, definition)
        push!(request_functions, service_request_function(definition))
        push!(sdk, "include(\"$name.jl\")")
    end

    write(joinpath(@__DIR__, "Services.jl"),
"""
#==============================================================================#
# Services.jl
#
# This file is generated by AWSAPI.jl from service decriptions at:
# https://github.com/aws/aws-sdk-js/tree/master/apis
#==============================================================================#

module Services

using ..AWSCore

$(join(request_functions, "\n"))

end # module Services

#==============================================================================#
# End of file
#==============================================================================#
""")

    write(joinpath(@__DIR__, "..", "..", "AWSCoreDoc", "make.jl"),
          generate_doc(services))

    sdk_dir = joinpath(@__DIR__, "..", "..", "AWSSDK")
    src_path = joinpath(sdk_dir, "src", "AWSSDK.jl")
    mkpath(dirname(src_path))
        
    write(src_path,
"""
#==============================================================================#
# AWSSDK.jl
#
# This file is generated by AWSAPI.jl from service decriptions at:
# https://github.com/aws/aws-sdk-js/tree/master/apis
#==============================================================================#

module AWSSDK

$(join(sdk, "\n"))

end # module AWSSDK

#==============================================================================#
# End of file
#==============================================================================#
""")

end




end # module AWSAPI

#==============================================================================#
# End of file.
#==============================================================================#
