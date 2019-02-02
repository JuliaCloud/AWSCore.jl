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
AWSConfig(creds=AWSCredentials("AKIDEXAMPLE", "wJa..."), region="ap-southeast-2", output="json")
```
"""
mutable struct AWSConfig <: AbstractDict{Symbol,Any}  # XXX: Remove subtype after deprecation
    creds::AWSCredentials
    region::String
    output::String
    # XXX: The `_extras` field will be removed after the deprecation period
    _extras::Dict{Symbol,Any}
end

function AWSConfig(; profile=nothing,
                     creds=AWSCredentials(profile=profile),
                     region=get(ENV, "AWS_DEFAULT_REGION", "us-east-1"),
                     output="json",
                     kwargs...)
    AWSConfig(creds, region, output, kwargs)
end

function Base.show(io::IO, conf::AWSConfig)
    print(io, "AWSConfig(creds=AWSCredentials(")
    show(io, conf.creds.access_key_id)
    print(io, ", \"", conf.creds.secret_key[1:3], "...\"), region=")
    show(io, conf.region)
    print(io, ", output=")
    show(io, conf.output)
    print(io, ')')
    if !isempty(conf._extras)
        println(io, "\n  Additional contents (SHOULD BE REMOVED):")
        join(io, [string("    :", k, " => ", v) for (k, v) in conf._extras], '\n')
    end
end

# Overrides needed because of the AbstractDict subtyping
Base.summary(io::IO, conf::AWSConfig) = "AWSConfig"
Base.show(io::IO, ::MIME{Symbol("text/plain")}, conf::AWSConfig) = show(io, conf)

function Base.Dict(conf::AWSConfig)
    d = copy(conf._extras)
    for f in [:creds, :region, :output]
        d[f] = getfield(conf, f)
    end
    d
end

# TODO: Implement copy for AWSCredentials
Base.copy(conf::AWSConfig) = AWSConfig(conf.creds, conf.region, conf.output, copy(conf._extras))

# Relics of using `SymbolDict`. We'll implement the entire `AbstractDict` interface
# with informative deprecation messages depending on how the functions are used:
# if users are storing and accessing the information that corresponds to the fields
# of the type, pretend like we're just using `@deprecate`. If they try it with other
# information, tell them it won't be possible soon.

_isfield(x::Symbol) = (x === :creds || x === :region || x === :output)

function _depmsg(store::Bool)
    if store
        verb = "storing"
        preposition = "in"
    else
        verb = "retrieving"
        preposition = "from"
    end
    string(verb, " information other than credentials, region, and output format ",
           preposition, " an `AWSConfig` object is deprecated; use another data ",
           "structure to store this information.")
end

function _depsig(old::String, new::String="")
    s = "`" * old * "` is deprecated"
    if isempty(new)
        s *= "; in the future, no information other than credentials, region, and output " *
             "format will be stored in an `AWSConfig` object."
    else
        s *= ", use `" * new * "` instead."
    end
    s
end

using Base: @deprecate, depwarn
import Base: merge, merge!, keytype, valtype

@deprecate AWSConfig(pairs::Pair...) AWSConfig(; pairs...)
@deprecate aws_config AWSConfig
@deprecate merge(d::AbstractDict, conf::AWSConfig) merge(d, Dict(conf))
@deprecate merge!(d::AbstractDict, conf::AWSConfig) merge!(d, Dict(conf))
@deprecate keytype(conf::AWSConfig) Symbol
@deprecate valtype(conf::AWSConfig) Any

function Base.setindex!(conf::AWSConfig, val, var::Symbol)
    if _isfield(var)
        depwarn(_depsig("setindex!(conf::AWSConfig, val, var::Symbol",
                        "setfield!(conf, var, val)"), :setindex!)
        setfield!(conf, var, val)
    else
        depwarn(_depmsg(true), :setindex!)
        conf._extras[var] = val
    end
end

function Base.getindex(conf::AWSConfig, x::Symbol)
    if _isfield(x)
        depwarn(_depsig("getindex(conf::AWSConfig, x::Symbol)",
                        "getfield(conf, x)"), :getindex)
        getfield(conf, x)
    else
        depwarn(_depmsg(false), :getindex)
        conf._extras[x]
    end
end

function Base.get(conf::AWSConfig, field::Symbol, alternative)
    if _isfield(field)
        depwarn(_depsig("get(conf::AWSConfig, field::Symbol, alternative)",
                        "getfield(conf, field)"), :get)
        getfield(conf, field)
    else
        depwarn(_depmsg(false), :get)
        get(conf._extras, field, alternative)
    end
end

function Base.haskey(conf::AWSConfig, field::Symbol)
    depwarn(_depsig("haskey(conf::AWSConfig, field::Symbol)"), :haskey)
    _isfield(field) || haskey(conf._extras, field)
end

function Base.keys(conf::AWSConfig)
    depwarn(_depsig("keys(conf::AWSConfig)"), :keys)
    keys(Dict(conf))
end

function Base.values(conf::AWSConfig)
    depwarn(_depsig("values(conf::AWSConfig)"), :values)
    values(Dict(conf))
end

function Base.merge(conf::AWSConfig, d::AbstractDict{Symbol,<:Any})
    c = copy(conf)
    for (k, v) in d
        if _isfield(k)
            depwarn("`merge(conf::AWSConf, d::AbstractDict)` is deprecated, set fields " *
                    "directly instead.", :merge)
            setfield!(c, k, v)
        else
            Base.depwarn(_depmsg(true), :merge)
            c._extras[k] = v
        end
    end
    c
end

function Base.merge!(conf::AWSConfig, d::AbstractDict{Symbol,<:Any})
    for (k, v) in d
        if _isfield(k)
            depwarn("`merge!(conf::AWSConf, d::AbstractDict)` is deprecated, set fields " *
                    "directly instead.", :merge!)
            setfield!(conf, k, v)
        else
            depwarn(_depmsg(true), :merge!)
            conf._extras[k] = v
        end
    end
    conf
end

function Base.iterate(conf::AWSConfig, state...)
    depwarn("in the future, `AWSConfig` objects will not be iterable.", :iterate)
    iterate(Dict(conf), state...)
end

function Base.push!(conf::AWSConfig, (k, v)::Pair{Symbol,<:Any})
    if _isfield(conf, k)
        depwarn(_depsig("push!(conf::AWSConfig, p::Pair)",
                        "setfield!(conf, first(p), last(p))"), :push!)
        setfield!(conf, k, v)
    else
        Base.depwarn(_depmsg(true), :push!)
        push!(conf._extras, k => v)
    end
end

function Base.in((k, v)::Pair, conf::AWSConfig)
    depwarn("`in(p::Pair, conf::AWSConfig)` is deprecated.", :in)
    (_isfield(k) && getfield(conf, k) == v) || in(p, conf._extras)
end
