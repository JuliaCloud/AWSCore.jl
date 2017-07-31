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


api_module_name(service_name) = "Amazon$(service_name)"


"""
    uncamel(s)

Transform CamelCase to lowercase_with_underscores.
"""

uncamel(s) = lowercase(replace(s, r"([a-z])([A-Z])", s"\1_\2"))


"""
    orjoin(words)

Join `words` with commas and "or". e.g. "one, two or three".
"""

orjoin(words) = isempty(words) ? "" :
                length(words) == 1 ? words[1] :
                "$(join(words[1:end-1], ", ")) or $(words[end])"


function service_args(service, name)

    shape = service["shapes"][name]
    @assert shape["type"] == "structure"

    m = filter((n, i) -> (n in get(shape, "required", [])), shape["members"])


    args = join(["$name=" for (name, info) in m], ", ")
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
                s = service_shape_doc(service, i["shape"], padmore, stack)
                d = html2md(get(i, "documentation", ""))
                r = haskey(shape, "required") && m in shape["required"]
                if s[1] != ':'
                    m = "$m: "
                end
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
            return string(service_shape_doc(service, i["shape"], pad, stack),
                          r ? " *" : "")
        end

        members = []
        for (m, i) in shape["members"]
            s = service_shape_doc(service, i["shape"], padmore, stack)
            r = haskey(shape, "required") && m in shape["required"]
            push!(members, "$m $(r ? "*" : "") => $s")
        end

        return "Dict(\n$padmore$(join(members, ",\n$padmore"))\n$pad)"
    end

    if t == "list"
        s = service_shape_doc(service, shape["member"]["shape"], pad, stack)
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

    return t

    finally pop!(stack) end
end


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

    prefix = replace(service["metadata"]["endpointPrefix"], r"[.-]", "_")
    request = "$(prefix)_request"
    method = "\"$(info["http"]["method"])\""
    resource = "\"$(info["http"]["requestUri"])\""

    if haskey(info, "input")
        sig1 = "$name(::AWSConfig, arguments::Dict)"
        sig2 = "$name(::AWSConfig; $input)"
    else
        sig1 = "$name(::AWSConfig)\n"
        sig2 = ""
    end

    """
    \"\"\"
        $sig1
        $sig2

    # $operation Operation

    $(html2md(get(info, "documentation", "")))$inputdoc$output$errors

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
    prefix = replace(meta["endpointPrefix"], r"[.-]", "_")

    meta = filter((k, v) -> !(k in ["sourceURL", "sourceFile"]), meta)

"""
const service_meta = $meta

function $(prefix)_request(aws::AWSConfig, verb::String, resource::String, operation::String, args)

    global service_meta

    AWSCore.service_$protocol(aws, service_meta, verb, resource, operation, args)
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

    $(html2md(get(service, "documentation", "")))

    This document is generated from
    [$(meta["sourceFile"])]($(meta["sourceURL"])).
    See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

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

    service = AWSMetadata.service_list()[name]
    definition = AWSMetadata.service_definition(service)
    meta = definition["metadata"]
    m = api_module_name(name)
    meta["juliaModule"] = m

    println(meta["serviceFullName"])

    pkg_dir = joinpath(Pkg.dir(), m)
    src_path = joinpath(pkg_dir, "src", "$m.jl")
    mkpath(dirname(src_path))
    write(src_path, service_interface(definition))
    write(joinpath(pkg_dir, "REQUIRE"),
        """
        julia 0.5
        AWSCore
        DataStructures
        """)
    write(joinpath(pkg_dir, "README.md"),
        """
        # $m.jl

        Julia interface for [$(meta["serviceFullName"])](https://docs.aws.amazon.com/goto/WebAPI/$(meta["uid"]))

        See [$m.jl API Reference](https://juliacloud.github.io/AWSCore.jl/build/$m.html).

        See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).


        Please file issues under [JuliaCloud/AWSCore.jl/issues](https://github.com/JuliaCloud/AWSCore.jl/issues).

        This module is generated from
        [$(meta["sourceFile"])]($(meta["sourceURL"])).

        ---

        $(html2md(get(definition, "documentation", "")))
        """)
    cp(joinpath(@__DIR__, "..", "LICENSE.md"),
       joinpath(pkg_dir, "LICENSE.md"),
       remove_destination=true)

    write(joinpath(@__DIR__, "..", "docs", "src", "$m.md"),
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
        doc *= "using $(api_module_name(s))\n"
    end

    doc *= """
    makedocs(modules = [AWSCore, AWSS3, AWSSES, AWSSQS, AWSSNS,
                        $(join([api_module_name(s) for s in services], ","))],
             format = :html,
             sitename = "AWSCore.jl",
             pages = ["AWSCore.jl" => "index.md",
                      "AWSS3.jl" => "AWSS3.md",
                      "AWSSQS.jl" => "AWSSQS.md",
                      "AWSSES.jl" => "AWSSES.md",
                      "AWSSNS.jl" => "AWSSNS.md",
                      $(join(["\"$m.jl\" => \"$m.md\""
                              for m in map(api_module_name, services)], ","))
             ])
    """

    return (doc)
end


function generate_all()

    services = keys(AWSMetadata.service_list())

    for s in services
        service_generate(s)
    end

    write(joinpath(@__DIR__, "..", "docs", "make.jl"), generate_doc(services))
end




end # module AWSAPI

#==============================================================================#
# End of file.
#==============================================================================#
