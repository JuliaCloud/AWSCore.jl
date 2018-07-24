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
       aws_account_number


"""
When you interact with AWS, you specify your [AWS Security Credentials](http://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html) to verify who you are and whether you have permission to access the resources that you are requesting. AWS uses the security credentials to authenticate and authorize your requests.

The fields `access_key_id` and `secret_key` hold the access keys used to authenticate API requests (see [Creating, Modifying, and Viewing Access Keys](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey)).

[Temporary Security Credentials](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html) require the extra session `token` field.


The `user_arn` and `account_number` fields are used to cache the result of the [`aws_user_arn`](@ref) and [`aws_account_number`](@ref) functions.

The `AWSCredentials()` constructor tries to load local Credentials from
environment variables, `~/.aws/credentials`, `~/.aws/config` or EC2 instance credentials.
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

function AWSCredentials()

    if haskey(ENV, "AWS_ACCESS_KEY_ID")

        creds = env_instance_credentials()

    elseif isfile(dot_aws_credentials_file()) || isfile(dot_aws_config_file())

        creds = dot_aws_credentials()

    elseif haskey(ENV, "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")

        creds = ecs_instance_credentials()

    elseif localhost_maybe_ec2()

        creds = ec2_instance_credentials()

    else
        error("Can't find AWS credentials!")
    end

    if debug_level > 0
        display(creds)
        println()
    end

    return creds
end


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


using JSON

"""
Load [Instance Profile Credentials]
(http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#instance-metadata-security-credentials)
for EC2 virtual machine.
"""
function ec2_instance_credentials()

    @assert localhost_maybe_ec2()

    info  = ec2_metadata("iam/info")
    info  = JSON.parse(info, dicttype=Dict{String,String})

    name  = ec2_metadata("iam/security-credentials/")
    creds = ec2_metadata("iam/security-credentials/$name")
    new_creds = JSON.parse(creds, dicttype=Dict{String,String})

    if debug_level > 0
        print("Loading AWSCredentials from EC2 metadata... ")
    end

    AWSCredentials(new_creds["AccessKeyId"],
                   new_creds["SecretAccessKey"],
                   new_creds["Token"],
                   info["InstanceProfileArn"])
end


"""
Load [ECS Task Credentials]
(http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
"""
function ecs_instance_credentials()

    @assert haskey(ENV, "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")

    uri = ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]

    new_creds = JSON.parse(String(http_get("http://169.254.170.2$uri").body))

    if debug_level > 0
        print("Loading AWSCredentials from ECS metadata... ")
    end

    AWSCredentials(new_creds["AccessKeyId"],
                   new_creds["SecretAccessKey"],
                   new_creds["Token"],
                   new_creds["RoleArn"])
end


"""
Load Credentials from [environment variables]
(http://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html)
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` etc.
(e.g. in Lambda sandbox).
"""
function env_instance_credentials()

    if debug_level > 0
        print("Loading AWSCredentials from ENV[\"AWS_ACCESS_KEY_ID\"]... ")
    end

    AWSCredentials(ENV["AWS_ACCESS_KEY_ID"],
                   ENV["AWS_SECRET_ACCESS_KEY"],
                   get(ENV, "AWS_SESSION_TOKEN", ""),
                   get(ENV, "AWS_USER_ARN", ""))
end


using IniFile

dot_aws_credentials_file() = get(ENV, "AWS_SHARED_CREDENTIALS_FILE",
                                 joinpath(homedir(), ".aws", "credentials"))

dot_aws_config_file() = get(ENV, "AWS_CONFIG_FILE",
                                 joinpath(homedir(), ".aws", "config"))


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

    if config
        profile = "profile $profile"
        key_id = get(ini, profile, "aws_access_key_id", key_id)
        key = get(ini, profile, "aws_secret_access_key", key)
    end

    (key, key_id)
end

function aws_get_region(profile::AbstractString, ini::Inifile)
    region = get(ENV, "AWS_DEFAULT_REGION", "us-east-1")

    region = get(ini, profile, "region", region)
    region = get(ini, "profile $profile", "region", region)
end

function aws_get_role(role::AbstractString, ini::Inifile)
    source_profile, role_arn = aws_get_role_details(role, ini)

    if source_profile == :notfound
        error("Can't find AWS credentials!")
    end

    if debug_level > 0
        println("Assuming \"$source_profile\"... ")
    end
    credentials = dot_aws_credentials(source_profile)

    config = AWSConfig(:creds=>credentials, :region=>aws_get_region(source_profile, ini))

    role = Services.sts(
        config,
        "AssumeRole",
        RoleArn=role_arn,
        RoleSessionName=replace(role, r"[^\w+=,.@-]", s"-"),
    )
    role_creds = role["Credentials"]

    credentials = AWSCredentials(role_creds["AccessKeyId"],
        role_creds["SecretAccessKey"],
        role_creds["SessionToken"]
    )
end

"""
Load Credentials from [AWS CLI ~/.aws/credentials file] or [AWS CLI ~/.aws/config file]
(http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html).
"""
function dot_aws_credentials(profile = nothing)
    @assert isfile(dot_aws_credentials_file()) || isfile(dot_aws_config_file())

    if profile == nothing
        profile = get(ENV, "AWS_DEFAULT_PROFILE",
                get(ENV, "AWS_PROFILE", "default"))
    end

    # According to the docs the order of precedence is:
    # 1. credentials in the credential file
    # 2. credentials in the config file
    # 3. roles in the config file
    credential_file = dot_aws_credentials_file()
    ini = nothing
    if isfile(credential_file)
        ini = read(Inifile(), credential_file)
        key, key_id = aws_get_credential_details(profile, ini, false)
        if key != :notfound
            return AWSCredentials(key_id, key)
        end
    end

    config_file = dot_aws_config_file()
    if isfile(config_file)
        ini = read(Inifile(), config_file)
        key, key_id = aws_get_credential_details(profile, ini, true)
        if key != :notfound
            AWSCredentials(key_id, key)
        else
            aws_get_role(profile, ini)
        end
    end
end

#==============================================================================#
# End of file.
#==============================================================================#
