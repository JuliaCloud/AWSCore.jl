# AWSSDK.MarketplaceMetering

# AWS Marketplace Metering Service

This reference provides descriptions of the low-level AWS Marketplace Metering Service API.

AWS Marketplace sellers can use this API to submit usage data for custom usage dimensions.

**Submitting Metering Records**

*   *MeterUsage*- Submits the metering record for a Marketplace product. MeterUsage is called from an EC2 instance.

*   *BatchMeterUsage*- Submits the metering record for a set of customers. BatchMeterUsage is called from a software-as-a-service (SaaS) application.

**Accepting New Customers**

*   *ResolveCustomer*- Called by a SaaS application during the registration process. When a buyer visits your website during the registration process, the buyer submits a Registration Token through the browser. The Registration Token is resolved through this API to obtain a CustomerIdentifier and Product Code.

This document is generated from
[apis/meteringmarketplace-2016-01-14.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/meteringmarketplace-2016-01-14.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.MarketplaceMetering.md"]
```

```@autodocs
Modules = [AWSSDK.MarketplaceMetering]
```
