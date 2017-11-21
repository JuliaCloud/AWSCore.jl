#==============================================================================#
# http.jl
#
# HTTP Requests with retry/back-off and HTTPException.
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

import Base: show, UVError


http_status(e::HTTP.StatusError) = e.status
headers(e::HTTP.StatusError) = HTTP.headers(e.response)
http_message(e::HTTP.StatusError) = String(HTTP.body(e.response))
content_type(e::HTTP.StatusError) = get(headers(e), "Content-Type", "")


function http_request(request::AWSRequest)

    @repeat 4 try 

        return HTTP.request(HTTP.DEFAULT_CLIENT,
                            request[:verb],
                            HTTP.URI(request[:url]);
                            headers = request[:headers],
                            body = FIFOBuffer(request[:content]),
                            stream = get(request, :return_stream, false),
                            verbose = debug_level > 1,
                            connecttimeout = Inf,
                            readtimeout = Inf,
                            allowredirects = false,
                            statusraise = true,
                            retries = 0,
                            canonicalizeheaders = false)

    catch e
        @delay_retry if isa(e, HTTP.HTTPError) &&
                       !isa(e, HTTP.StatusError) end
        @delay_retry if isa(e, HTTP.StatusError) && (
                        http_status(e) < 200 ||
                        http_status(e) >= 500) end
    end

    assert(false) # Unreachable.
end


function http_get(url::String)

    host = HTTP.URIs.hostname(HTTP.URI(url))

    http_request(@SymDict(verb = "GET",
                          url = url,
                          headers = Dict("Host" => host),
                          content = UInt8[]))
end



#==============================================================================#
# End of file.
#==============================================================================#
