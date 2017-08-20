# AWSSDK.ELB

# Elastic Load Balancing

A load balancer distributes incoming traffic across your EC2 instances. This enables you to increase the availability of your application. The load balancer also monitors the health of its registered instances and ensures that it routes traffic only to healthy instances. You configure your load balancer to accept incoming traffic by specifying one or more listeners, which are configured with a protocol and port number for connections from clients to the load balancer and a protocol and port number for connections from the load balancer to the instances.

Elastic Load Balancing supports two types of load balancers: Classic Load Balancers and Application Load Balancers (new). A Classic Load Balancer makes routing and load balancing decisions either at the transport layer (TCP/SSL) or the application layer (HTTP/HTTPS), and supports either EC2-Classic or a VPC. An Application Load Balancer makes routing and load balancing decisions at the application layer (HTTP/HTTPS), supports path-based routing, and can route requests to one or more ports on each EC2 instance or container instance in your virtual private cloud (VPC). For more information, see the [Elastic Load Balancing User Guide](http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html).

This reference covers the 2012-06-01 API, which supports Classic Load Balancers. The 2015-12-01 API supports Application Load Balancers.

To get started, create a load balancer with one or more listeners using [CreateLoadBalancer](@ref). Register your instances with the load balancer using [RegisterInstancesWithLoadBalancer](@ref).

All Elastic Load Balancing operations are *idempotent*, which means that they complete at most one time. If you repeat an operation, it succeeds with a 200 OK response code.

This document is generated from
[apis/elasticloadbalancing-2012-06-01.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/elasticloadbalancing-2012-06-01.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.ELB.md"]
```

```@autodocs
Modules = [AWSSDK.ELB]
```
