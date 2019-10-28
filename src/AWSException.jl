#==============================================================================#
# AWSException.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


export AWSException

struct AWSException <: Exception
    code
    message
    info
    cause
end

function Base.show(io::IO,e::AWSException)
    println(io, string(e.code,
                       e.message == "" ? "" : (" -- " * e.message), "\n",
                       e.cause))
end


function AWSException(e::HTTP.StatusError)
    code = string(http_status(e))
    message = "AWSException"
    info = Dict()

    # Extract API error code from Lambda-style JSON error message...
    if occursin(r"json$", content_type(e))
        info = LazyJSON.value(http_message(e))
    end

    # Extract API error code from JSON error message...
    if occursin(r"^application/x-amz-json-1.[01]$", content_type(e))
        info = LazyJSON.value(http_message(e))
        if haskey(info, "__type")
            code = split(info["__type"], "#")[end]
        end
    end

    # Extract API error code from XML error message...
    if (content_type(e) in ["", "application/xml", "text/xml"]
    &&  length(http_message(e)) > 0)
        info = parse_xml(http_message(e))
    end

    info = get(info, "Errors", info)
    info = get(info, "Error", info)
    code = get(info, "Code", code)
    message = get(info, "Message", message)
    message = get(info, "message", message)

    AWSException(code, message, info, e)
end


#==============================================================================#
# End of file.
#==============================================================================#

