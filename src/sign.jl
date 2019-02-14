#==============================================================================#
# sign.jl
#
# AWS Request Signing.
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


using MbedTLS


function sign!(r::AWSRequest, t = now(Dates.UTC))

    if r[:service] in ["sdb", "importexport"]
        sign_aws2!(r, t)
    else
        sign_aws4!(r, t)
    end
end


# Create AWS Signature Version 2 Authentication query parameters.
# http://docs.aws.amazon.com/general/latest/gr/signature-version-2.html

function sign_aws2!(r::AWSRequest, t)

    query = Dict{AbstractString,AbstractString}()
    for elem in split(r[:content], '&', keep=false)
        (n, v) = split(elem, "=")
        query[n] = HTTP.unescapeuri(v)
    end

    r[:headers]["Content-Type"] =
        "application/x-www-form-urlencoded; charset=utf-8"

    creds = check_credentials(r[:creds])
    query["AWSAccessKeyId"] = creds.access_key_id
    query["Expires"] = Dates.format(t + Dates.Second(120),
                                   dateformat"yyyy-mm-dd\THH:MM:SS\Z")
    query["SignatureVersion"] = "2"
    query["SignatureMethod"] = "HmacSHA256"
    if creds.token != ""
        query["SecurityToken"] = creds.token
    end

    query = Pair[k => query[k] for k in sort(collect(keys(query)))]

    u = HTTP.URI(r[:url])
    to_sign = "POST\n$(u.host)\n$(u.path)\n$(HTTP.escapeuri(query))"

    secret = creds.secret_key
    push!(query, "Signature" =>
                  digest(MD_SHA256, to_sign, secret) |> base64encode |> strip)

    r[:content] = HTTP.escapeuri(query)
end



# Create AWS Signature Version 4 Authentication Headers.
# http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html

function sign_aws4!(r::AWSRequest, t)

    # ISO8601 date/time strings for time of request...
    date = Dates.format(t,"yyyymmdd")
    datetime = Dates.format(t, dateformat"yyyymmdd\THHMMSS\Z")

    # Authentication scope...
    scope = [date, r[:region], r[:service], "aws4_request"]

    creds = check_credentials(r[:creds])
    # Signing key generated from today's scope string...
    signing_key = string("AWS4", creds.secret_key)
    for element in scope
        signing_key = digest(MD_SHA256, element, signing_key)
    end

    # Authentication scope string...
    scope = join(scope, "/")

    # SHA256 hash of content...
    content_hash = bytes2hex(digest(MD_SHA256, r[:content]))

    # HTTP headers...
    delete!(r[:headers], "Authorization")
    merge!(r[:headers], Dict(
        "x-amz-content-sha256" => content_hash,
        "x-amz-date"           => datetime,
        "Content-MD5"          => base64encode(digest(MD_MD5, r[:content]))
    ))
    if creds.token != ""
        r[:headers]["x-amz-security-token"] = creds.token
    end

    # Sort and lowercase() Headers to produce canonical form...
    canonical_headers = ["$(lowercase(k)):$(strip(v))" for (k,v) in r[:headers]]
    signed_headers = join(sort([lowercase(k) for k in keys(r[:headers])]), ";")

    # Sort Query String...
    uri = HTTP.URI(r[:url])
    query = HTTP.URIs.queryparams(uri.query)
    query = Pair[k => query[k] for k in sort(collect(keys(query)))]

    # Create hash of canonical request...
    canonical_form = string(r[:verb], "\n",
                            r[:service] == "s3" ? uri.path
                                                : HTTP.escapepath(uri.path), "\n",
                            HTTP.escapeuri(query), "\n",
                            join(sort(canonical_headers), "\n"), "\n\n",
                            signed_headers, "\n",
                            content_hash)
    if debug_level > 2
        println("canonical_form:")
        println(canonical_form)
        println("")
    end

    canonical_hash = bytes2hex(digest(MD_SHA256, canonical_form))

    # Create and sign "String to Sign"...
    string_to_sign = "AWS4-HMAC-SHA256\n$datetime\n$scope\n$canonical_hash"
    signature = bytes2hex(digest(MD_SHA256, string_to_sign, signing_key))

    if debug_level > 2
        println("string_to_sign:")
        println(string_to_sign)
        println("")
        println("signature:")
        println(signature)
        println("")
    end

    # Append Authorization header...
    r[:headers]["Authorization"] = string(
        "AWS4-HMAC-SHA256 ",
        "Credential=$(creds.access_key_id)/$scope, ",
        "SignedHeaders=$signed_headers, ",
        "Signature=$signature"
    )
end



#==============================================================================#
# End of file.
#==============================================================================#
