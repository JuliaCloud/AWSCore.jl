#==============================================================================#
# AWSException.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


import JSON: json


export AWSException

abstract AWSException <: Exception

function Base.show(io::IO,e::AWSException)
    println(io, string(e.code,
                       e.message == "" ? "" : (" -- " * e.message), "\n",
                       e.cause))
end


function AWSException(e::HTTPException)

    code = string(http_status(e))
    message = "AWSException"
    info = Dict()

    # Extract API error code from Lambda-style JSON error message...
    if ismatch(r"json$", content_type(e))
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

