#==============================================================================#
# http.jl
#
# HTTP Requests with retry/back-off and HTTPException.
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

import Base: show, IOError


http_status(e::HTTP.StatusError) = e.status
header(e::HTTP.StatusError, k, d="") = HTTP.header(e.response, k, d)
http_message(e::HTTP.StatusError) = String(copy(e.response.body))
content_type(e::HTTP.StatusError) = HTTP.header(e.response, "Content-Type")


function http_request(request::AWSRequest)

    @repeat 4 try

        options = []
        if get(request, :return_stream, false)
            io = Base.BufferStream()
            request[:response_stream] = io
            push!(options, (:response_stream, io))
        end

        if haskey(request, :http_options)
            for v in request[:http_options]
                push!(options, v)
            end
        end

        verbose = debug_level - 1

        http_stack = HTTP.stack(redirect=false,
                                retry=false,
                                aws_authorization=false,
                                verbose=verbose)

        return HTTP.request(http_stack,
                            request[:verb],
                            HTTP.URI(request[:url]),
                            HTTP.mkheaders(request[:headers]),
                            request[:content];
                            #aws_service = request[:service],
                            #aws_region = request[:region],
                            #aws_access_key_id = request[:creds].access_key_id,
                            #aws_secret_access_key = request[:creds].secret_key,
                            #aws_session_token = request[:creds].token,
                            verbose = verbose,
                            require_ssl_verification=false,
                            options...)

    catch e
        # Base.IOError is needed because HTTP.jl can often have errors that aren't
        # caught and wrapped in an HTTP.IOError
        # https://github.com/JuliaWeb/HTTP.jl/issues/382
        @delay_retry if isa(e, Sockets.DNSError) ||
                        isa(e, HTTP.ParseError) ||
                        isa(e, HTTP.IOError) ||
                        isa(e, Base.IOError) ||
                        #isa(e, EOFError) || FIXME needed ?
                       (isa(e, HTTP.StatusError) && http_status(e) >= 500)
            if debug_level > 1
                println("Caught $e during HTTP request, retrying...")
            end
        end
    end

    assert(false) # Unreachable.
end


function http_get(url::String)

    host = HTTP.URI(url).host

    http_request(@SymDict(verb = "GET",
                          url = url,
                          headers = ["Host" => host],
                          content = UInt8[]))
end



#==============================================================================#
# End of file.
#==============================================================================#
