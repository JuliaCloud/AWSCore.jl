#==============================================================================#
# AWSException.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


import JSON: json


export AWSException

abstract type AWSException <: Exception end

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
    if ismatch(r"json$", content_type(e))
        info = JSON.parse(http_message(e))
        message = get(info, "message", message)
    end

    # Extract API error code from JSON error message...
    if ismatch(r"^application/x-amz-json-1.[01]$", content_type(e))
        info = JSON.parse(http_message(e))
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

    # Create specialised exception object based on "code"...
    etype = Symbol(code)
    @repeat 2 try
        e = eval(:($etype($code, $message, $info, $e)))
    catch x
        @retry if isa(x, UndefVarError)
            eval(:(type $etype <: AWSException code; message; info; cause end))
        end
    end
end


AWSException(e) = e


#==============================================================================#
# End of file.
#==============================================================================#

