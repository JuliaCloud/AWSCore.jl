#==============================================================================#
# AWSCredentials.jl
#
# Load AWS Credentials from:
# - EC2 Instance Profile,
# - Environment variables, or
# - ~/.aws/credentials file.
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

export AWSCredentials,
       localhost_is_lambda,
       localhost_is_ec2,
       localhost_maybe_ec2,
       aws_user_arn,
       aws_account_number,
       check_credentials

"""
When you interact with AWS, you specify your [AWS Security Credentials](http://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html)
to verify who you are and whether you have permission to access the resources that you are requesting.
AWS uses the security credentials to authenticate and authorize your requests.

The fields `access_key_id` and `secret_key` hold the access keys used to authenticate API requests
(see [Creating, Modifying, and Viewing Access Keys](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey)).

[Temporary Security Credentials](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html) require the extra session `token` field.

The `user_arn` and `account_number` fields are used to cache the result of the [`aws_user_arn`](@ref) and [`aws_account_number`](@ref) functions.

AWSCore searches for credentials in a series of possible locations and stop as soon as it finds credentials.
The order of precedence for this search is as follows:

1. Passing credentials directly to the `AWSCredentials` constructor
2. [Environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
3. Shared credential file [(~/.aws/credentials)](http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
4. AWS config file [(~/.aws/config)](http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
5. Assume Role provider via the aws config file
6. Instance metadata service on an Amazon EC2 instance that has an IAM role configured.

Once the credentials are found, the method by which they were accessed is stored in the `renew` field
and the DateTime at which they will expire is stored in the `expiry` field.
This allows the credentials to be refreshed as needed using [`check_credentials`](@ref).
If `renew` is set to `nothing`, no attempt will be made to refresh the credentials.

Any renewal function is expected to return `nothing` on failure or a populated `AWSCredentials` object on success.
The `renew` field of the returned `AWSCredentials` will be discarded and does not need to be set.

To specify the profile to use from `~/.aws/credentials`, do, for example, `AWSCredentials(profile="profile-name")`.
"""
mutable struct AWSCredentials
    access_key_id::String
    secret_key::String
    token::String
    user_arn::String
    account_number::String
    expiry::DateTime
    renew::Union{Function, Nothing}

    function AWSCredentials(access_key_id,secret_key,
                            token="", user_arn="", account_number="";
                            expiry=typemax(DateTime),
                            renew=nothing)
        new(access_key_id, secret_key, token, user_arn, account_number, expiry, renew)
    end
end

function AWSCredentials(;profile=nothing)
    creds = nothing
    renew = Nothing

    # Define our search options
    functions = [
        env_instance_credentials,
        () -> dot_aws_credentials(profile),
        () -> dot_aws_config(profile),
        instance_credentials,
    ]

    # Loop through our search locations until we get credentials back
    for f in functions
        renew = f
        creds = renew()
        creds === nothing || break
    end

    creds === nothing && error("Can't find AWS credentials!")
    creds.renew = renew

    if debug_level > 0
        display(creds)
        println()
    end

    return creds
end

will_expire(cr::AWSCredentials) = now(UTC) >= cr.expiry - Minute(5)

"""
    check_credentials(cr::AWSCredentials; force_refresh::Bool=false)

Checks current AWSCredentials, refreshing them if they are soon to expire.
If force_refresh is `true` the credentials will be renewed immediately.
"""
function check_credentials(cr::AWSCredentials; force_refresh::Bool=false)
    if force_refresh || will_expire(cr)
        if debug_level > 0
            println("Renewing credentials... ")
        end
        renew = cr.renew

        if renew !== nothing
            new_creds = renew()

            new_creds === nothing && error("Can't find AWS credentials!")
            copyto!(cr, new_creds)

            # Ensure renewal function is not overwritten by the new credentials
            cr.renew = renew
        else
            if debug_level > 0
                println("Credentials cannot be renewed...")
            end
        end
    end

    return cr
end

function Base.show(io::IO,c::AWSCredentials)
    println(io, string(c.user_arn,
                       c.user_arn == "" ? "" : " ",
                       "(",
                       c.account_number,
                       c.account_number == "" ? "" : ", ",
                       c.access_key_id,
                       c.secret_key == "" ? "" : ", $(c.secret_key[1:3])...",
                       c.token == "" ? "" : ", $(c.token[1:3])..."),
                       ")")
end

function Base.copyto!(dest::AWSCredentials, src::AWSCredentials)
    for f in fieldnames(typeof(dest))
        setfield!(dest, f, getfield(src, f))
    end
end
import Base: copy!
Base.@deprecate copy!(dest::AWSCredentials, src::AWSCredentials) copyto!(dest, src)


"""
Is Julia running in an AWS Lambda sandbox?
"""
localhost_is_lambda() = haskey(ENV, "LAMBDA_TASK_ROOT")


"""
Is Julia running on an EC2 virtual machine?
"""
function localhost_is_ec2()

    if localhost_is_lambda()
        return false
    end

    if isfile("/sys/hypervisor/uuid") &&
       String(read("/sys/hypervisor/uuid",3)) == "ec2"
        return true
    end

    if isfile("/sys/devices/virtual/dmi/id/product_uuid")
        try
            # product_uuid is not world readable!
            # https://patchwork.kernel.org/patch/6461521/
            # https://github.com/JuliaCloud/AWSCore.jl/issues/24
            if String(read("/sys/devices/virtual/dmi/id/product_uuid")) == "EC2"
                return true
            end
        catch
        end
    end

    return false
end

localhost_maybe_ec2() = localhost_is_ec2() ||
                        isfile("/sys/devices/virtual/dmi/id/product_uuid")

"""
    aws_user_arn(::AWSConfig)

Unique
[Amazon Resource Name]
(http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)
for configrued user.

e.g. `"arn:aws:iam::account-ID-without-hyphens:user/Bob"`
"""
function aws_user_arn(aws::AWSConfig)
    creds = aws[:creds]
    if creds.user_arn == ""
        r = Services.sts(aws, "GetCallerIdentity", [])
        creds.user_arn = r["Arn"]
        creds.account_number = r["Account"]
    end
    return creds.user_arn
end


"""
    aws_account_number(::AWSConfig)

12-digit [AWS Account Number](http://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html).
"""
function aws_account_number(aws::AWSConfig)
    creds = aws[:creds]
    if creds.account_number == ""
        aws_user_arn(aws)
    end
    return creds.account_number
end


"""
    ec2_metadata(key)

Fetch [EC2 meta-data]
(http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)
for `key`.
"""
function ec2_metadata(key)

    @assert localhost_maybe_ec2()

    String(http_get("http://169.254.169.254/latest/meta-data/$key").body)
end

function instance_credentials()
    if haskey(ENV, "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")
        return ecs_instance_credentials()
    elseif localhost_maybe_ec2()
        return ec2_instance_credentials()
    else
        return nothing
    end
end

"""
Load [Instance Profile Credentials]
(http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#instance-metadata-security-credentials)
for EC2 virtual machine.
"""
function ec2_instance_credentials()

    @assert localhost_maybe_ec2()

    info  = ec2_metadata("iam/info")
    info  = LazyJSON.value(info)

    name  = ec2_metadata("iam/security-credentials/")
    creds = ec2_metadata("iam/security-credentials/$name")
    new_creds = LazyJSON.value(creds)

    if debug_level > 0
        print("Loading AWSCredentials from EC2 metadata... ")
    end

    expiry = DateTime(strip(new_creds["Expiration"], 'Z'))

    AWSCredentials(new_creds["AccessKeyId"],
                   new_creds["SecretAccessKey"],
                   new_creds["Token"],
                   info["InstanceProfileArn"];
                   expiry = expiry)
end


"""
Load [ECS Task Credentials]
(http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
"""
function ecs_instance_credentials()

    @assert haskey(ENV, "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")

    uri = ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]

    new_creds = String(http_get("http://169.254.170.2$uri").body)
    new_creds = LazyJSON.value(new_creds)

    if debug_level > 0
        print("Loading AWSCredentials from ECS metadata... ")
    end

    expiry = DateTime(strip(new_creds["Expiration"], 'Z'))

    AWSCredentials(new_creds["AccessKeyId"],
                   new_creds["SecretAccessKey"],
                   new_creds["Token"],
                   new_creds["RoleArn"];
                   expiry = expiry)
end


"""
Load Credentials from [environment variables]
(http://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html)
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` etc.
(e.g. in Lambda sandbox).
"""
function env_instance_credentials()

    if haskey(ENV, "AWS_ACCESS_KEY_ID")
        if debug_level > 0
            print("Loading AWSCredentials from ENV[\"AWS_ACCESS_KEY_ID\"]... ")
        end

        return AWSCredentials(
            ENV["AWS_ACCESS_KEY_ID"],
            ENV["AWS_SECRET_ACCESS_KEY"],
            get(ENV, "AWS_SESSION_TOKEN", ""),
            get(ENV, "AWS_USER_ARN", "");
            renew = env_instance_credentials
        )
    else
        return nothing
    end
end


using IniFile

function dot_aws_credentials_file()
    get(ENV, "AWS_SHARED_CREDENTIALS_FILE", joinpath(homedir(), ".aws", "credentials"))
end

"""
Try to load Credentials from [AWS CLI ~/.aws/credentials file]
(http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
"""
function dot_aws_credentials(profile = nothing)
    creds = nothing
    credential_file = dot_aws_credentials_file()

    ini = nothing
    if isfile(credential_file)
        ini = read(Inifile(), credential_file)
        key, key_id, token = aws_get_credential_details(
            profile === nothing ? aws_get_profile() : profile,
            ini,
            false
        )

        if key !== :notfound
            creds = AWSCredentials(key_id, key, token)
        end
    end

    return creds
end

dot_aws_config_file() = get(ENV, "AWS_CONFIG_FILE", joinpath(homedir(), ".aws", "config"))

"""
Try to load Credentials or assume a role via the [AWS CLI ~/.aws/config file]
(http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
"""
function dot_aws_config(profile = nothing)
    creds = nothing
    config_file = dot_aws_config_file()

    ini = nothing
    if isfile(config_file)
        ini = read(Inifile(), config_file)
        p = profile === nothing ? aws_get_profile() : profile
        key, key_id, token = aws_get_credential_details(p, ini, true)

        if key !== :notfound
            creds = AWSCredentials(key_id, key, token)
        else
            creds = aws_get_role(p, ini)
        end
    end

    return creds
end

function aws_get_role_details(profile::AbstractString, ini::Inifile)
    if debug_level > 0
        println("Loading \"$profile\" Profile from " *
                dot_aws_config_file() * "... ")
    end

    role_arn = get(ini, profile, "role_arn")
    source_profile = get(ini, profile, "source_profile")

    profile = "profile $profile"
    role_arn = get(ini, profile, "role_arn", role_arn)
    source_profile = get(ini, profile, "source_profile", source_profile)

    (source_profile, role_arn)
end

function aws_get_credential_details(profile::AbstractString, ini::Inifile, config::Bool)
    if debug_level > 0
        filename = config ? dot_aws_config_file() : dot_aws_credentials_file()
        println("Loading \"$profile\" AWSCredentials from " * filename
                * "... ")
    end

    key_id = get(ini, profile, "aws_access_key_id")
    key = get(ini, profile, "aws_secret_access_key")
    token = get(ini, profile, "aws_session_token", "")

    if config
        profile = "profile $profile"
        key_id = get(ini, profile, "aws_access_key_id", key_id)
        key = get(ini, profile, "aws_secret_access_key", key)
        token = get(ini, profile, "aws_session_token", token)
    end

    (key, key_id, token)
end

function aws_get_profile()
    get(ENV, "AWS_DEFAULT_PROFILE", get(ENV, "AWS_PROFILE", "default"))
end

function aws_get_region(profile::AbstractString, ini::Inifile)
    region = get(ENV, "AWS_DEFAULT_REGION", "us-east-1")

    region = get(ini, profile, "region", region)
    region = get(ini, "profile $profile", "region", region)
end

function aws_get_role(role::AbstractString, ini::Inifile)
    source_profile, role_arn = aws_get_role_details(role, ini)
    source_profile === :notfound && return nothing

    if debug_level > 0
        println("Assuming \"$source_profile\"... ")
    end
    credentials = nothing

    for f in [dot_aws_credentials, dot_aws_config]
        credentials = f(source_profile)
        credentials === nothing || break
    end

    credentials === nothing && return nothing

    config = AWSConfig(:creds=>credentials, :region=>aws_get_region(source_profile, ini))

    role = Services.sts(
        config,
        "AssumeRole",
        RoleArn=role_arn,
        RoleSessionName=replace(role, r"[^\w+=,.@-]" => s"-"),
    )
    role_creds = role["Credentials"]

    AWSCredentials(role_creds["AccessKeyId"],
        role_creds["SecretAccessKey"],
        role_creds["SessionToken"];
        expiry = unix2datetime(role_creds["Expiration"]))
end

#==============================================================================#
# End of file.
#==============================================================================#
