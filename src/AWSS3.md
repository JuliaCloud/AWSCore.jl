# AWS S3 

```@meta
CurrentModule = AWSS3
```
```@setup AWSS3
using AWSS3
```

[https://github.com/samoconnor/AWSS3.jl](https://github.com/samoconnor/AWSS3.jl)

```@index
Pages = ["AWSS3.md"]
```

## AWS S3 Objects

```@docs
s3_get
s3_get_file
s3_get_meta
s3_exists
s3_put
s3_purge_versions
s3_delete
s3_copy
s3_sign_url
```

## AWS S3 Buckets

```@docs
s3_list_buckets
s3_list_objects
s3_list_versions
s3_create_bucket
s3_put_cors
s3_enable_versioning
s3_delete_bucket
```

## AWS S3 Bucket and Object Tagging

```@docs
s3_put_tags
s3_get_tags
s3_delete_tags
```

## AWSS3 Internals

```@docs
s3_arn
```
```@example AWSS3
s3_arn("my_bucket/foo/bar.txt")
```
```@example AWSS3
s3_arn("my_bucket","foo/bar.txt")
```
