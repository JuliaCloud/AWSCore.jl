#==============================================================================#
# AWSCore.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


module AWSCore


export AWSException, AWSConfig, AWSRequest,
       aws_config, default_aws_config

using Base64
using Dates
using Sockets
using Retry
using SymDict
using XMLDict
using HTTP
using DataStructures: OrderedDict
using JSON
using LazyJSON


"""
Most `AWSCore` functions take a `AWSConfig` dictionary as the first argument.
This dictionary holds [`RenewableAWSCredentials`](@ref) and AWS region configuration.

```julia
aws = AWSConfig(:creds => RenewableAWSCredentials(), :region => "us-east-1")`
```
"""
const AWSConfig = SymbolDict


"""
The `AWSRequest` dictionary describes a single API request:
It contains the following keys:

- `:creds` => [`RenewableAWSCredentials`](@ref) for authentication.
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
>aws = aws_config(profile = "profile-name")
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

If your `~/.aws/credentials` file contains multiple profiles you can pass the
profile name as a string to the `profile` keyword argument (`nothing` by
default) or select a profile by setting the `AWS_PROFILE` environment variable.

`aws_config` understands the following [AWS CLI environment
variables](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment):
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`,
`AWS_DEFAULT_REGION`, `AWS_PROFILE` and `AWS_CONFIG_FILE`.


An configuration dictionary can also be created directly from a key pair
as follows. However, putting access credentials in source code is discouraged.

```julia
aws = aws_config(creds = AWSCredentials("AKIAXXXXXXXXXXXXXXXX",
                                        "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"))
```

"""
function aws_config(;profile=nothing,
                     creds=AWSCredentials(profile=profile),
                     region=get(ENV, "AWS_DEFAULT_REGION", "us-east-1"),
                     args...)
    @SymDict(creds, region, args...)
end


global _default_aws_config = nothing # Union{AWSConfig,Nothing}


"""
`default_aws_config` returns a global shared [`AWSConfig`](@ref) object
obtained by calling [`aws_config`](@ref) with no optional arguments.
"""
function default_aws_config()
    global _default_aws_config
    if _default_aws_config === nothing
        _default_aws_config = aws_config()
    end
    return _default_aws_config
end


"""
    aws_args_dict(args)

Convert nested `Vector{Pair}` maps in `args` into `Dict{String,Any}` maps.
"""
function aws_args_dict(args)

    result = stringdict(args)

    dictlike(t) = (t <: AbstractDict
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


# FIXME handle map.flattened and list.flattened (see SQS and SDB)
"""
    flatten_query(service, query, prefix="")

Recursivly flatten tree of `Dicts` and `Arrays` into a 1-level deep Dict.
"""
function flatten_query(service, query, prefix="")

    result = Dict{String,String}()

    for (k, v) in query

        if typeof(v) <: AbstractDict

            merge!(result, flatten_query(service, v, "$prefix$k."))

        elseif typeof(v) <: Array

            for (i, x) in enumerate(v)

                suffix = service in ["ec2", "sqs"] ? "" : ".member"
                pk = "$prefix$k$suffix.$i"

                if typeof(x) <: AbstractDict
                    merge!(result, flatten_query(service, x, "$pk."))
                else
                    result[pk] = string(x)
                end
            end
        else
            result["$prefix$k"] = string(v)
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
    request[:resource] = get(aws, :resource, "/")
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

    request[:content] = HTTP.escapeuri(flatten_query(request[:service],
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
        if occursin("{$k}", r)
            r = replace(r, "{$k}" => v)
            delete!(args, k)
        elseif occursin("{$k+}", r)
            r = replace(r, "{$k+}" => HTTP.escapepath(v))
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

    request[:headers] = Dict{String,String}(get(args, "headers", []))
    delete!(args, "headers")
    request[:headers]["Content-Type"] = "application/json"
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

    request[:headers] = Dict{String,String}(get(args, "headers", []))
    delete!(args, "headers")
    request[:content] = get(args, "Body", "")
    delete!(args, "Body")

    request[:resource] = rest_resource(request, args)

    query_str  = HTTP.escapeuri(args)

    if query_str  != ""
        if occursin("?", request[:resource])
            request[:resource] *= "&$query_str"
        else
            request[:resource] *= "?$query_str"
        end
    end

    #FIXME deal with bucket prefix
    request[:url] = service_url(aws, request)

    do_request(merge(request, aws))
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
            if occursin(r"[^.]Name$", k)
                name *= " "
                name *= q[k]
            end
        end
    end
    if haskey(r, :query)
        for k in keys(r[:query])
            if occursin(r"[^.]Name$", k)
                name *= " "
                name *= r[:query][k]
            end
        end
    end
    println("$(r[:service]).$action $name")
end


include("sign.jl")


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
        r[:headers]["Host"]       = HTTP.URI(r[:url]).host

        # If existing, use credentials to sign request...
        r[:creds] === nothing || sign!(r)

        if debug_level > 0
            dump_aws_request(r)
        end

        # Send the request...
        response = http_request(r)

        if response.status in [301, 302, 307] &&
           HTTP.header(response, "Location") != ""
            r[:url] = HTTP.header(response, "Location")
            continue
        end

    catch e
        if e isa HTTP.StatusError
            e = AWSException(e)
        end

        # Handle expired signature...
        @retry if :message in fieldnames(typeof(e)) &&
                  occursin(r"Signature expired", e.message)
            if debug_level > 1
                println("Caught $e during request $(dump_aws_request(r)), retrying due to expired signature...")
            end
        end

        # Handle ExpiredToken...
        # See `credsExpiredCodes` in
        # https://github.com/aws/aws-sdk-go/blob/master/aws/request/retryer.go
        @retry if ecode(e) in ("ExpiredToken",
                               "ExpiredTokenException",
                               "RequestExpired")

            # Reload local system credentials if needed...
            check_credentials(r[:creds], force_refresh=true)
            if debug_level > 1
                println("Caught $e during request $(dump_aws_request(r)), retrying due to expired credentials...")
            end
        end

        # Handle throttling
        # see botocore for list of codes:
        # https://github.com/boto/botocore/blob/master/botocore/data/_retry.json
        # Recommended for SDKs at:
        # https://docs.aws.amazon.com/general/latest/gr/api-retries.html
        # Also BadDigest error and CRC32 thing
        @retry if e isa AWSException && (
                  http_status(e.cause) == 429 ||
                  ecode(e) in ("Throttling",
                               "ThrottlingException",
                               "ThrottledException",
                               "RequestThrottledException",
                               "TooManyRequestsException",
                               "ProvisionedThroughputExceededException",
                               "LimitExceededException",
                               "RequestThrottled",
                               "RequestTimeout",
                               "BadDigest",
                               "RequestTimeoutException",
                               "PriorRequestNotComplete") ||
                  header(e.cause, "crc32body") == "x-amz-crc32")
            if debug_level > 1
                cause = "throttling"

                if header(e.cause, "crc32body") == "x-amz-crc32"
                    cause = "CRC32"
                elseif ecode(e) in ("RequestTimeout",
                                    "BadDigest",
                                    "RequestTimeoutException",
                                    "PriorRequestNotComplete")
                    cause = ecode(e)
                end
                println("Caught $e during request $(dump_aws_request(r)), retrying due to $cause...")
            end
        end
    end

    if debug_level > 1
        display(response)
        println()
    end

    # For HEAD request, return headers...
    if r[:verb] == "HEAD"
        return Dict(response.headers)
    end

    # Return response stream if requested...
    if get(r, :return_stream, false)
        return r[:response_stream]
    end

    # Return raw data if requested...
    if get(r, :return_raw, false)
        return response.body
    end

    # Parse response data according to mimetype...
    mime = HTTP.header(response, "Content-Type", "")
    if mime == ""
        if length(response.body) > 5 && String(response.body[1:5]) == "<?xml"
            mime = "text/xml"
        end
    end

    body = String(copy(response.body))

    if occursin(r"/xml", mime)
        return parse_xml(body)
    end

    if occursin(r"/x-amz-json-1.[01]$", mime)
        if isempty(response.body)
            return nothing
        end
        if get(r, :ordered_json_dict, true)
            return JSON.parse(body, dicttype=OrderedDict)
        else
            return JSON.parse(body)
        end
    end

    if occursin(r"json$", mime)
        if isempty(response.body)
            return nothing
        end
        if get(r, :ordered_json_dict, true)
            info = JSON.parse(body, dicttype=OrderedDict)
        else
            info = JSON.parse(body)
        end
        @protected try
            action = r[:query]["Action"]
            info = info[action * "Response"]
            info = info[action * "Result"]
        catch e
            @ignore if typeof(e) == KeyError end
        end
        return info
    end

    if occursin(r"^text/", mime)
        return body
    end

    # Return raw data by default...
    return response.body
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
