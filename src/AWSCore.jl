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

# NOTE: This needs to be defined before AWSConfig. Methods defined on AWSCredentials are
# in src/AWSCredentials.jl.
"""
    AWSCredentials

A type which holds AWS credentials.
When you interact with AWS, you specify your
[AWS Security Credentials](http://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html)
to verify who you are and whether you have permission to access the resources that you are
requesting. AWS uses the security credentials to authenticate and authorize your requests.

The fields `access_key_id` and `secret_key` hold the access keys used to authenticate API
requests (see [Creating, Modifying, and Viewing Access
Keys](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey)).

[Temporary Security Credentials](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html)
require the extra session `token` field.

The `user_arn` and `account_number` fields are used to cache the result of the
[`aws_user_arn`](@ref) and [`aws_account_number`](@ref) functions.

The `AWSCredentials()` constructor tries to load local credentials from:

* `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  [environment variables](http://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html),
* [`~/.aws/credentials`](http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html), or
* [EC2 Instance Credentials](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#instance-metadata-security-credentials).

To specify the profile to use from `~/.aws/credentials`, do, for example,
`AWSCredentials(profile="profile-name")`.

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
"""
mutable struct AWSCredentials
    access_key_id::String
    secret_key::String
    token::String
    user_arn::String
    account_number::String

    function AWSCredentials(access_key_id, secret_key,
                            token="", user_arn="", account_number="")
        new(access_key_id, secret_key, token, user_arn, account_number)
    end
end

"""
    AWSConfig

Most `AWSCore` functions take an `AWSConfig` object as the first argument.
This type holds [`AWSCredentials`](@ref), region, and output configuration.

# Constructors

    AWSConfig(; profile, creds, region, output)

Construct an `AWSConfig` object with the given profile, credentials, region, and output
format. All keyword arguments have default values and are thus optional.

* `profile`: Profile name passed to [`AWSCredentials`](@ref), or `nothing` (default)
* `creds`: `AWSCredentials` object, constructed using `profile` if not provided
* `region`: Region, read from `AWS_DEFAULT_REGION` if present, otherwise `"us-east-1"`
* `output`: Output format, defaulting to JSON (`"json"`)

# Examples

```julia-repl
julia> AWSConfig(profile="example", region="ap-southeast-2")
AWSConfig((AKIDEXAMPLE, wJa...)
, "ap-southeast-2", "json", NamedTuple())

julia> AWSConfig(creds=AWSCredentials("AKIDEXAMPLE", "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"))
AWSConfig((AKIDEXAMPLE, wJa...)
, "us-east-1", "json", NamedTuple())
```
"""
mutable struct AWSConfig
    creds::AWSCredentials
    region::String
    output::String
    # XXX: The `_extras` field will be removed after the deprecation period
    _extras::Dict{Symbol,Any}
end

function AWSConfig(; profile=nothing,
                     creds=AWSCredentials(profile=profile),
                     region=get(ENV, "AWS_DEFAULT_REGION", ""),
                     output="json",
                     kwargs...)
    AWSConfig(creds, region, output, kwargs)
end

# Relics of using SymbolDict

_isfield(x::Symbol) = (x === :creds || x === :region || x === :output)

Base.@deprecate AWSConfig(pairs::Pair...) AWSConfig(; pairs...)
Base.@deprecate aws_config AWSConfig

function Base.setindex!(conf::AWSConfig, val, var::Symbol)
    if _isfield(var)
        Base.depwarn("`setindex!(conf::AWSConfig, val, var::Symbol)` is deprecated, " *
                     "use `setfield!(conf, var, val)` instead.", :setindex!)
        setfield!(conf, var, val)
    else
        Base.depwarn("storing information other than credentials, region, and output " *
                     "format in an `AWSConfig` object is deprecated; use another data " *
                     "structure to store this information.", :setindex!)
        conf._extras[var] = val
    end
end

function Base.getindex(conf::AWSConfig, x::Symbol)
    if _isfield(x)
        Base.depwarn("`getindex(conf::AWSConfig, x::Symbol)` is deprecated, use " *
                     "`getfield(conf, x)` instead.", :getindex)
        getfield(conf, x)
    else
        Base.depwarn("retrieving information other than credentials, region, and output " *
                     "format from an `AWSConfig` object is deprecated; use another data " *
                     "structure to store this information.", :getindex)
        conf._extras[x]
    end
end

function Base.get(conf::AWSConfig, field::Symbol, alternative)
    if _isfield(field)
        Base.depwarn("`get(conf::AWSConfig, field::Symbol, alternative)` is deprecated, " *
                     "use `getfield(conf, field)` instead.", :get)
        getfield(conf, field)
    else
        Base.depwarn("retrieving information other than credentials, region, and output " *
                     "format from an `AWSConfig` object is deprecated; use another data " *
                     "structure to store this information.", :get)
        get(conf._extras, field, alternative)
    end
end

function Base.haskey(conf::AWSConfig, field::Symbol)
    Base.depwarn("`haskey(conf::AWSConfig, field::Symbol)` is deprecated; in the future " *
                 "no information other than credentials, region and output format will " *
                 "be stored in an `AWSConfig` object.", :haskey)
    _isfield(field) ? true : haskey(conf._extras, field)
end

function Base.merge(conf::AWSConfig, d::AbstractDict{Symbol,<:Any})
    for (k, v) in d
        if _isfield(k)
            Base.depwarn("`merge(conf::AWSConf, d::AbstractDict)` is deprecated, set fields " *
                         "directly instead", :merge)
            setfield!(conf, k, v)
        else
            Base.depwarn("storing information other than credentials, region, and output " *
                         "format in an `AWSConfig` object is deprecated; use another data " *
                         "structure to store this information.", :merge)
            conf._extras[k] = v
        end
    end
    conf
end

function Base.merge(d::AbstractDict{K,V}, conf::AWSConfig) where {K,V}
    Base.depwarn("`merge(d::AbstractDict, conf::AWSConfig)` is deprecated; in the future " *
                 "no information other than credentials, region and output format will " *
                 "be stored in an `AWSConfig` object and it will not behave like a " *
                 "dictionary.", :merge)
    m = merge(d, conf._extras)
    for f in [:creds, :region, :output]
        m[convert(K, f)] = getfield(conf, f)
    end
    m
end

function Base.iterate(conf::AWSConfig, state...)
    Base.depwarn("in the future, `AWSConfig` objects will not be iterable", :iterate)
    x = [:creds => conf.creds,
         :region => conf.region,
         :output => conf.output,
         conf._extras...]
    iterate(x, state...)
end

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

global _default_aws_config = Ref{Union{AWSConfig,Nothing}}(nothing)

"""
    default_aws_config()

Return the global shared [`AWSConfig`](@ref) object obtained by calling
[`AWSConfig()`](@ref) with no arguments.
"""
function default_aws_config()
    global _default_aws_config
    if _default_aws_config[] === nothing
        _default_aws_config[] = AWSConfig()
    end
    return _default_aws_config[]
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
    region = "." * aws.region
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
        aws.region = "us-east-1"
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

        # Load local system credentials if needed...
        if r[:creds].token == "ExpiredToken"
            copyto!(r[:creds], AWSCredentials())
        end

        # Use credentials to sign request...
        sign!(r)

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
                  occursin(r"Signature expired", e.message) end

        # Handle ExpiredToken...
        # See `credsExpiredCodes` in
        # https://github.com/aws/aws-sdk-go/blob/master/aws/request/retryer.go
        @retry if ecode(e) in ("ExpiredToken",
                               "ExpiredTokenException",
                               "RequestExpired")

            r[:creds].token = "ExpiredToken"
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
                  header(e.cause, "crc32body") == "x-amz-crc32") end
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
