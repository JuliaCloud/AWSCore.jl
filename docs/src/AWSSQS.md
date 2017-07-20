# AWS SQS 

```@meta
CurrentModule = AWSSQS
```
```@setup AWSSQS
using AWSSQS
```

[https://github.com/samoconnor/AWSSQS.jl](https://github.com/samoconnor/AWSSQS.jl)

```@index
Pages = ["AWSSQS.md"]
```

## SQS Queues

```@docs
sqs_list_queues
sqs_get_queue
sqs_create_queue
sqs_set_policy
sqs_delete_queue
```

## SQS Messages

```@docs
sqs_send_message
sqs_send_message_batch
sqs_receive_message
sqs_messages
sqs_delete_message
sqs_flush
```

## SQS Metadata

```@docs
sqs_name
sqs_arn
sqs_get_queue_attributes
sqs_count
sqs_busy_count
```
