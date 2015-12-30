#==============================================================================#
# AWSException.jl
#
# Copyright Sam O'Connor 2014 - All rights reserved
#==============================================================================#


import JSON: json


export AWSException


type AWSException <: Exception
    code::AbstractString
    message::AbstractString
    cause
end


function Base.show(io::IO,e::AWSException)
    println(io, string(e.code,
                       e.message == "" ? "" : (" -- " * e.message), "\n",
                       e.cause))
end


function AWSException(e::HTTPException)

    code = string(http_status(e))
    message = "AWSException"

    # Extract API error code from Lambda-style JSON error message...
    if content_type(e) == "application/json"
        info = JSON.parse(http_message(e))
        message = get(info, "message", message)
    end

    # Extract API error code from JSON error message...
    if content_type(e) == "application/x-amz-json-1.0"
        json = JSON.parse(http_message(e))
        if haskey(json, "__type")
            code = split(json["__type"], "#")[2]
        end
    end

    # Extract API error code from XML error message...
    if (content_type(e) in ["", "application/xml", "text/xml"]
    &&  length(http_message(e)) > 0)
        info = LightXML.parse_string(http_message(e))
    end

    info = get(info, "Errors", info)
    info = get(info, "Error", info)
    code = get(info, "Code", code)
    message = get(info, "Message", message)

    AWSException(code, message, e)
end


AWSException(e) = e


#==============================================================================#
# End of file.
#==============================================================================#

