#==============================================================================#
# http.jl
#
# HTTP Requests with retry/back-off and HTTPException.
#
# Copyright Sam O'Connor 2014 - All rights reserved
#==============================================================================#

import URIParser: URI, query_params
import Requests: format_query_str, process_response, open_stream,
                 mimetype, text, bytes, OnBody,
                 BodyDone, EarlyEOF
import HttpCommon: Request, Response, STATUS_CODES
import Base: show, UVError


export HTTPException, data


type HTTPException <: Exception
    request
    response
end


http_status(e::HTTPException) = e.response.status
headers(e::HTTPException) = e.response.headers
http_message(e::HTTPException) = bytestring(e.response.data)
content_type(e::HTTPException) = get(e.response.headers, "Content-Type", "")


function show(io::IO,e::HTTPException)

    println(io, string("HTTP ", http_status(e), " -- ",
                       e.request.method, " ", e.request.uri, " -- ",
                        http_message(e)))
end


function show_data(data)
    if length(data) > 1000
        println(UTF8String(data[1:1000]))
        println("...")
    else
        println(UTF8String(data))
    end
end


http_ok(r) = r.status in [200, 201, 202, 204, 206]


function http_attempt(request::Request, return_stream=false)

    if debug_level > 1
        println("$(request.method) $(request.uri)")
        dump(request.headers)
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
                dump(response.headers)
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


function http_request(request::Request, return_stream::Bool=false)

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


function http_request(host::ASCIIString, resource::ASCIIString)

    http_request(Request("GET", resource,
                         Dict{ASCIIString,ASCIIString}(), UInt8[],
                         URI(host,resource)))
end


istext(r::Response) = any(p->ismatch(p, get(mimetype(r))),
                         [r"^text/", r"/xml$", r"/json$"])
data(r::Response) = istext(r) ? utf8(r.data) : r.data


#==============================================================================#
# End of file.
#==============================================================================#
