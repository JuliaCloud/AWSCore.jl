#==============================================================================#
# http.jl
#
# HTTP Requests with retry/back-off and HTTPException.
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

import URIParser: URI, query_params
import Requests: format_query_str, process_response, open_stream,
                 mimetype, text, bytes, OnBody,
                 BodyDone, EarlyEOF
import HttpCommon: Request, Response, STATUS_CODES
import Base: show, UVError


export HTTPException


type HTTPException <: Exception
    request
    response
end


http_status(e::HTTPException) = e.response.status
headers(e::HTTPException) = e.response.headers
http_message(e::HTTPException) = String(e.response.data)
content_type(e::HTTPException) = get(e.response.headers, "Content-Type", "")


function show(io::IO,e::HTTPException)

    println(io, string("HTTP ", http_status(e), " -- ",
                       e.request.method, " ", e.request.uri, " -- ",
                        http_message(e)))
end


function show_data(data)
    if length(data) > 1000
        println(String(data[1:1000]))
        println("...")
    else
        println(String(data))
    end
end


http_ok(r) = r.status in [200, 201, 202, 204, 206]


function http_attempt(request::Request, return_stream=false)

    if debug_level > 1
        println("$(request.method) $(request.uri)")
        @show request.headers
        show_data(request.data)
    end

    # Start HTTP transaction...
    stream = open_stream(request)

    try

        @sync begin 

            @async process_response(stream)

            # Send request data...
            if length(request.data) > 0

                @protected try
                    write(stream, request.data)
                catch e
                    @ignore if isa(e, UVError) && stream.state >= OnBody end
                end
            end
        end

        # Read result...
        response = stream.response
        if !return_stream || !http_ok(response)
            response.data = read(stream)

            if debug_level > 1
                println(response.status)
                @show response.headers
                show_data(response.data)
            end
        end

        # Return on success...
        if stream.state == BodyDone
            if http_ok(response)
                return return_stream ? stream : response
            end
        else
            @assert stream.state == EarlyEOF
            if http_ok(response)
                throw(EOFError())
            end
        end

        # Throw error on failure...
        throw(HTTPException(request, response))

    finally
        if !return_stream
            close(stream)
        end
    end

    assert(false) # Unreachable.
end


function http_request(request::Request, return_stream=false)

    request.headers["Content-Length"] = string(length(request.data))

    @repeat 4 try 

        return http_attempt(request, return_stream)

    catch e
        @delay_retry if typeof(e) == UVError end
        @delay_retry if http_status(e) < 200 ||
                        http_status(e) >= 500 end
    end

    assert(false) # Unreachable.
end


function http_request(host::String, resource::String)

    http_request(Request("GET", resource,
                         Dict{String,String}(), UInt8[],
                         URI(host,resource)))
end



#==============================================================================#
# End of file.
#==============================================================================#
