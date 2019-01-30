# Setting up a test environment

## Prerequisites

An AWS account is required.
Setting up the test stack will require permissions for IAM and CloudFormation.

Some instructions below will use the [AWS CLI](https://aws.amazon.com/cli/).

[Invenia](https://www.invenia.ca) has a dedicated AWS account for public CI, the use
of which is granted for AWSCore.
The actions described below should be performed as an administrator of such an account.

## Setting up the account

### Creating a test user

This user will be responsible for actually running the tests.
The user will be passed to CloudFormation on stack creation and given permission to
assume the stack's testing role.
This approach allows the same user to be used for multiple testing stacks in the same
account, which is useful for iterating on stack design.

Since the user is given permissions by CloudFormation, it needs no permissions set upon
creation.
It will, however, need access keys.
These should be saved for running tests, ideally as a profile in an
[AWS credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html).

Invenia has set up a user dedicated to the AWSCore project, called AWSCoreJL.

### Creating a dedicated stack creation role (optional)

For greater control and visibility over stack creation, create a dedicated administrator
role which will manage the creation of resources in the test stack.
Edit the Trust Relationship for this role in the IAM console to allow access from
CloudFormation.
Adding the following to role's policy statement will accomplish this:

```yaml
{
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudformation.amazonaws.com"
  },
  "Action": "sts:AssumeRole"
}
```

## Creating the stack

A CloudFormation template resides in the `test/aws` directory in the AWSCore source
tree.
This will be used for creating the stack.

### Environment variables

```sh
# Relative to the root of the package directory
export TEMPLATE=file://test/aws/awscore_test.yml

# The testing user created above
export PUBLIC_CI_USER=AWSCoreJL

# The name of the stack. All stack names used by this package are named using the
# scheme AWSCore-jl-#####, where ##### begins with 00001 and counts up. Do not
# attempt to give two stacks the same name.
export STACK_NAME=AWSCore-jl-00011
```

### AWS CLI commands

To create a basic stack using the current profile, use the below.
Note that a particular profile can be passed to this command using `--profile`.

```sh
aws cloudformation create-stack \
    --template-body $TEMPLATE \
    --parameters ParameterKey=PublicCIUser,ParameterValue=$PUBLIC_CI_USER \
    --stack-name $STACK_NAME
```

If a dedicated stack creation role was created in the previous step, use this:

```sh
export STACK_ROLE_ARN=arn:aws:iam::263813748431:role/CloudFormationAdmin

aws cloudformation create-stack \
    --template-body $TEMPLATE \
    --capabilities CAPABILITY_NAMED_IAM \
    --role-arn $STACK_ROLE_ARN \
    --parameters ParameterKey=PublicCIUser,ParameterValue=$PUBLIC_CI_USER \
    --stack-name $STACK_NAME
```

The status of the stack creation can be verified using the AWS CloudFormation console
or with the AWS CLI.

## Running tests

The testing user must be authenticated, either through the use of
[environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html)
or using an AWS profile.
The environment variables for Invenia's stack are privately in the Travis CI
repository settings.

Running Julia tests normally should now work!
