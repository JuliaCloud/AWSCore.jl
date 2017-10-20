#==============================================================================#
# AWSCore.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


__precompile__()


module AWSCore


export AWSException, AWSConfig, AWSRequest,
       aws_config, default_aws_config

using Retry
using SymDict
using XMLDict
using HTTP
using URIParser: URI, query_params


"""
Most `AWSCore` functions take a `AWSConfig` dictionary as the first argument.
This dictionary holds [`AWSCredentials`](@ref) and AWS region configuration.

```julia
aws = AWSConfig(:creds => AWSCredentials(), :region => "us-east-1")`
```
"""

const AWSConfig = SymbolDict


"""
The `AWSRequest` dictionary describes a single API request:
It contains the following keys:

- `:creds` => [`AWSCredentials`](@ref) for authentication.
- `:verb` => `"GET"`, `"PUT"`, `"POST"` or `"DELETE"`
- `:url` => service endpoint url (returned by [`aws_endpoint`](@ref))
- `:headers` => HTTP headers
- `:content` => HTTP body
- `:resource` => HTTP request path
- `:region` => AWS region
- `:service` => AWS service name
"""
const AWSRequest = SymbolDict


include("http.jl")
include("AWSException.jl")
include("AWSCredentials.jl")
include("names.jl")
include("mime.jl")



#------------------------------------------------------------------------------#
# Configuration.
#------------------------------------------------------------------------------#

"""
The `aws_config` function provides a simple way to creates an
[`AWSConfig`](@ref) configuration dictionary.

```julia
>aws = aws_config()
>aws = aws_config(creds = my_credentials)
>aws = aws_config(region = "ap-southeast-2")
```

By default, the `aws_config` attempts to load AWS credentials from:

 - `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` [environemnt variables](http://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html),
 - [`~/.aws/credentials`](http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html) or
 - [EC2 Instance Credentials](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#instance-metadata-security-credentials).

A `~/.aws/credentials` file can be created using the
[AWS CLI](https://aws.amazon.com/cli/) command `aws configrue`.
Or it can be created manually:

```ini
[default]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

If your `~/.aws/credentials` file contains multiple profiles you can
select a profile by setting the `AWS_DEFAULT_PROFILE` environment variable.

`aws_config` understands the following [AWS CLI environment
variables](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment):
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`,
`AWS_DEFAULT_REGION`, `AWS_DEFAULT_PROFILE` and `AWS_CONFIG_FILE`.


An configuration dictionary can also be created directly from a key pair
as follows. However, putting access credentials in source code is discouraged.

```julia
aws = aws_config(creds = AWSCredentials("AKIAXXXXXXXXXXXXXXXX",
                                        "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"))
```

"""
function aws_config(;creds=AWSCredentials(),
                     region=get(ENV, "AWS_DEFAULT_REGION", "us-east-1"),
                     args...)
    @SymDict(creds, region, args...)
end


global _default_aws_config = Nullable{AWSConfig}()


"""
`default_aws_config` returns a global shared [`AWSConfig`](@ref) object
obtained by calling [`aws_config`](@ref) with no optional arguments.
"""
function default_aws_config()
    global _default_aws_config
    if isnull(_default_aws_config)
        _default_aws_config = Nullable(aws_config())
    end
    return get(_default_aws_config)
end


"""
    aws_args_dict(args)

Convert nested `Vector{Pair}` maps in `args` into `Dict{String,Any}` maps.
"""

function aws_args_dict(args)

    result = stringdict(args)

    dictlike(t) = (t <: Associative
                || t <: Vector && t.parameters[1] <: Pair{String})

    for (k, v) in result
        if dictlike(typeof(v))
            result[k] = aws_args_dict(v)
        elseif isa(v, Vector)
            result[k] = [dictlike(typeof(i)) ? aws_args_dict(i) : i for i in v]
        end
    end

    return result
end


"""
    flatten_query(service, query, prefix="")

Recursivly flatten tree of `Dicts` and `Arrays` into a 1-level deep Dict.
"""

# FIXME handle map.flattened and list.flattened (see SQS and SDB)
function flatten_query(service, query, prefix="")

    result = Dict{String,Any}()

    for (k, v) in query

        if typeof(v) <: Associative

            merge!(result, flatten_query(service, v, "$prefix$k."))

        elseif typeof(v) <: Array

            for (i, x) in enumerate(v)

                suffix = service == "ec2" ? "" : ".member"
                pk = "$prefix$k$suffix.$i"

                if typeof(x) <: Associative
                    merge!(result, flatten_query(service, x, "$pk."))
                else
                    result[pk] = x
                end
            end
        else
            result["$prefix$k"] = v
        end
    end

    return result
end


"""
    service_url(aws::AWSConfig; request)

Service endpoint URL for `request`.
"""

function service_url(aws, request)
    endpoint = get(request, :endpoint, request[:service])
    region = "." * aws[:region]
    if endpoint == "iam" || (endpoint == "sdb" && region == ".us-east-1")
        region = ""
    end
    string("https://", endpoint, region, ".amazonaws.com",
           request[:resource])
end


"""
    service_query(aws::AWSConfig; args...)

Process request for AWS "query" service protocol.
"""

function service_query(aws::AWSConfig; args...)

    request = Dict{Symbol,Any}(args)

    request[:verb] = "POST"
    request[:resource] = get(aws, :resource, "/") #FIXME AWSSQS.jl aws[:resource]
    request[:url] = service_url(aws, request)
    request[:headers] = Dict("Content-Type" =>
                             "application/x-www-form-urlencoded; charset=utf-8")

    request[:query] = aws_args_dict(request[:args])
    request[:query]["Action"] = request[:operation]
    request[:query]["Version"] = request[:version]

    if request[:service] == "iam"
        aws = merge(aws, Dict(:region => "us-east-1"))
    end
    if request[:service] in ["iam", "sts", "sqs", "sns"]
        request[:query]["ContentType"] = "JSON"
    end

    request[:content] = HTTP.escape(flatten_query(request[:service],
                                    request[:query]))
    do_request(merge(request, aws))
end


"""
    service_json(aws::AWSConfig; args...)

Process request for AWS "json" service protocol.
"""

function service_json(aws::AWSConfig; args...)

    request = Dict{Symbol,Any}(args)

    request[:verb] = "POST"
    request[:resource] = "/"
    request[:url] = service_url(aws, request)
    request[:headers] = Dict(
        "Content-Type" => "application/x-amz-json-$(request[:json_version])",
        "X-Amz-Target" => "$(request[:target]).$(request[:operation])")
    request[:content] = json(aws_args_dict(request[:args]))

    do_request(merge(request, aws))
end


"""
   rest_resource(request, args)

Replace {Arg} placeholders in `request[:resource]` with arg values.
"""

function rest_resource(request, args)

    r = request[:resource]

    for (k,v) in args
        if contains(r, "{$k}")
            r = replace(r, "{$k}", v)
            delete!(args, k)
        elseif contains(r, "{$k+}")
            r = replace(r, "{$k+}", escape_path(v))
            delete!(args, k)
        end
    end

    return r
end


"""
    service_rest_json(aws::AWSConfig; args...)

Process request for AWS "rest_json" service protocol.
"""

function service_rest_json(aws::AWSConfig; args...)

    request = Dict{Symbol,Any}(args)
    args = Dict(request[:args])

    request[:resource] = rest_resource(request, args)
    request[:url] = service_url(aws, request)
    request[:headers] = Dict("Content-Type" => "application/json")
    request[:content] = json(aws_args_dict(args))

    do_request(merge(request, aws))
end


"""
    service_rest_xml(aws::AWSConfig; args...)

Process request for AWS "rest_xml" service protocol.
"""

function service_rest_xml(aws::AWSConfig; args...)

    request = Dict{Symbol,Any}(args)
    args = stringdict(request[:args])

    request[:content] = get(args, "Body", "")
    delete!(args, "Body")

    request[:resource] = rest_resource(request, args)

    query_str  = HTTP.escape(args)

    if query_str  != ""
        request[:resource] *= "?$query_str"
    end

    #FIXME deal with bucket prefix
    request[:url] = service_url(aws, request)

    do_request(merge(request, aws))
end


"""
Convert AWSRequest dictionary into Requests.Request (Requests.jl)
"""

function Request(r::AWSRequest)
    println(r)
    Request(r[:verb], r[:resource], r[:headers], r[:content], URI(r[:url]))
end


"""
Call http_request for AWSRequest.
"""

function http_request(request::AWSRequest, args...)
    http_request(Request(request), get(request, :return_stream, false))
end


"""
Pretty-print AWSRequest dictionary.
"""

function dump_aws_request(r::AWSRequest)

    action = r[:verb]
    name = r[:resource]
    if name == "/"
        name = ""
    end
    if haskey(r, :query) && haskey(r[:query], "Action")
        action = r[:query]["Action"]
    end
    if haskey(r[:headers], "X-Amz-Target")
        action = split(r[:headers]["X-Amz-Target"], ".")[end]
        q = JSON.parse(r[:content])
        for k in keys(q)
            if ismatch(r"[^.]Name$", k)
                name *= " "
                name *= q[k]
            end
        end
    end
    if haskey(r, :query)
        for k in keys(r[:query])
            if ismatch(r"[^.]Name$", k)
                name *= " "
                name *= r[:query][k]
            end
        end
    end
    println("$(r[:service]).$action $name")
end


include("sign.jl")


pathencode(c) = c != UInt8('/') && true #HTTP.URIs.shouldencode(c)
escape_path(path) = HTTP.escape(path, pathencode)


"""
    do_request(::AWSRequest)

Submit an API request, return the result.
"""

function do_request(r::AWSRequest)

    response = nothing

    # Try request 3 times to deal with possible Redirect and ExiredToken...
    @repeat 3 try

        # Default headers...
        if !haskey(r, :headers)
            r[:headers] = Dict{String,String}()
        end
        r[:headers]["User-Agent"] = "AWSCore.jl/0.0.0"
        r[:headers]["Host"]       = URI(r[:url]).host

        # Load local system credentials if needed...
        if !haskey(r, :creds) || r[:creds].token == "ExpiredToken"
            r[:creds] = AWSCredentials()
        end

        # Use credentials to sign request...
        sign!(r)

        if debug_level > 0
            dump_aws_request(r)
        end

        # Send the request...
        response = http_request(r)

    catch e

        # Handle HTTP Redirect...
        @retry if http_status(e) in [301, 302, 307] &&
                  haskey(headers(e), "Location")
            r[:url] = headers(e)["Location"]
        end

        e = AWSException(e)

        if debug_level > 0
            println("Warning: AWSCore.do_request() exception: $(typeof(e))")
        end

        # Handle expired signature...
        @retry if ismatch(r"Signature expired", e.message) end

        # Handle ExpiredToken...
        @retry if typeof(e) == ExpiredToken
            r[:creds].token = "ExpiredToken"
        end
    end

    # Return response stream if requested...
    if get(r, :return_stream, false)
        return HTTP.body(response)
    end

    # Return raw data if requested...
    if get(r, :return_raw, false)
        return take!(response)
    end

    # Parse response data according to mimetype...
    mime = get(HTTP.headers(response), "Content-Type", "")
    if mime == ""
        body = HTTP.body(response)
        if length(body) > 5 && String(body)[1:5] == "<?xml"
            mime = "text/xml"
        end
    end

    if ismatch(r"/xml", mime)
        return parse_xml(String(take!(response)))
    end

    if ismatch(r"/x-amz-json-1.[01]$", mime)
        return JSON.parse(String(take!(response)))
    end

    if ismatch(r"json$", mime)
        info = JSON.parse(String(take!(response)))
        @protected try
            action = r[:query]["Action"]
            info = info[action * "Response"]
            info = info[action * "Result"]
        catch e
            @ignore if typeof(e) == KeyError end
        end
        return info
    end

    if ismatch(r"^text/", mime)
        return String(take!(response))
    end

    # If there is no reponse data, return raw response object...
    if length(mime == "" && HTTP.body(response)) < 1
        return response
    end

    # Return raw data by default...
    return take!(response)
end


global debug_level = 0

function set_debug_level(n)
    global debug_level = n
end


include("Services.jl")


end # module AWSCore


#==============================================================================#
# End of file.
#==============================================================================#
