#==============================================================================#
# http.jl
#
# HTTP Requests with retry/back-off and HTTPException.
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

import Base: show, UVError


export HTTPException


type HTTPException <: Exception
    response
end

http_status(e::HTTPException) = HTTP.status(e.response)
headers(e::HTTPException) = HTTP.headers(e.response)
http_message(e::HTTPException) = String(HTTP.body(e.response))
content_type(e::HTTPException) = get(headers(e), "Content-Type", "")
show(io::IO,e::HTTPException) = show(io, e.response)


http_ok(r) = HTTP.status(r) in [200, 201, 202, 204, 206]


function http_attempt(request::AWSRequest)


    response = HTTP.request(HTTP.Client(STDOUT),
                            HTTP.Request(request[:verb],
                                         Int16(1), Int16(1),
                                         HTTP.URI(request[:url]),
                                         request[:headers],
                                         FIFOBuffer(request[:content])),
                            HTTP.RequestOptions(connecttimeout = 600,
                                                readtimeout = 600,
                                                allowredirects = false,
                                                retries = 0),
                            stream = get(request, :return_stream, false),
                            verbose = debug_level > 1)

    if !http_ok(response)
        throw(HTTPException(response))
    end

    return response
end


function http_request(request::AWSRequest)

    @repeat 4 try 

        return http_attempt(request)

    catch e
        @delay_retry if typeof(e) == HTTP.RetryException end
        @delay_retry if http_status(e) < 200 ||
                        http_status(e) >= 500 end
    end

    assert(false) # Unreachable.
end


function http_request(host::String, resource::String)

    http_request(@SymDict(verb = "GET",
                          url = "$host$resource",
                          headers = Dict("Host" => host),
                          content = UInt8[]))
end



#==============================================================================#
# End of file.
#==============================================================================#
