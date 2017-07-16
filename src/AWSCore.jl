#==============================================================================#
# AWSCore.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


__precompile__()


module AWSCore


export AWSException, AWSConfig, aws_config, default_aws_config,
       AWSRequest, post_request, do_request


using Retry
using SymDict
using XMLDict


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
    post_request(::AWSConfig, service, version, query)

Construct a [`AWSRequest`](@ref) dictionary for a HTTP POST request.
"""

function post_request(aws::AWSConfig,
                      service::String,
                      version::String,
                      query::Dict)

    resource = get(aws, :resource, "/")
    url = aws_endpoint(service, aws[:region]) * resource
    if version != ""
        query["Version"] = version
    end
    headers = Dict("Content-Type" =>
                   "application/x-www-form-urlencoded; charset=utf-8")
    content = format_query_str(query)

    @SymDict(verb = "POST", service, resource, url, headers, query, content,
             aws...)
end


"""
Convert AWSRequest dictionary into Requests.Request (Requests.jl)
"""

function Request(r::AWSRequest)
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
    if haskey(r, :query) && haskey(r[:query], "Action")
        action = r[:query]["Action"]
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


const path_esc_chars = filter(c->c!='/', URIParser.unescaped)
escape_path(path) = URIParser.escape_with(path, path_esc_chars)

const resource_esc_chars = Vector{Char}(filter(c->!in(c, "/?=&%"),
                                               URIParser.unescaped))


"""
    do_request(::AWSRequest)

Submit an API request, return the result.
"""

function do_request(r::AWSRequest)

    @assert search(r[:resource], resource_esc_chars) == 0

    response = nothing

    # Try request 3 times to deal with possible Redirect and ExiredToken...
    @repeat 3 try

        # Default headers...
        if !haskey(r, :headers)
            r[:headers] = Dict()
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

    # If there is no reponse data, return raw response object...
    if typeof(response) != Response || length(response.data) < 1
        return response
    end

    # Return raw data if requested...
    if get(r, :return_raw, false)
        return response.data
    end

    # Return raw data if there is no mimetype...
    if !isnull(mimetype(response))
        mime = get(mimetype(response))
    else
        if length(response.data) > 5 && String(response.data[1:5]) == "<?xml"
            mime = "text/xml"
        else
            return response.data
        end
    end

    # Parse response data according to mimetype...
    if ismatch(r"/xml$", mime)
        return parse_xml(String(response.data))
    end

    if ismatch(r"/x-amz-json-1.0$", mime)
        return JSON.parse(String(response.data))
    end

    if ismatch(r"json$", mime)
        info = JSON.parse(String(response.data))
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
        return String(response.data)
    end

    # Return raw data by default...
    return response.data
end


global debug_level = 0

function set_debug_level(n)
    global debug_level = n
end



end # module AWSCore


#==============================================================================#
# End of file.
#==============================================================================#
