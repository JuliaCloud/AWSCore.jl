# AWSSDK.GameLift

# Amazon GameLift Service

Amazon GameLift is a managed service for developers who need a scalable, dedicated server solution for their multiplayer games. Amazon GameLift provides tools for the following tasks: (1) acquire computing resources and deploy game servers, (2) scale game server capacity to meet player demand, (3) host game sessions and manage player access, and (4) track in-depth metrics on player usage and server performance.

The Amazon GameLift service API includes two important function sets:

*   **Manage game sessions and player access** -- Retrieve information on available game sessions; create new game sessions; send player requests to join a game session.

*   **Configure and manage game server resources** -- Manage builds, fleets, queues, and aliases; set autoscaling policies; retrieve logs and metrics.

This reference guide describes the low-level service API for Amazon GameLift. You can use the API functionality with these tools:

*   The Amazon Web Services software development kit ([AWS SDK](http://aws.amazon.com/tools/#sdk)) is available in [multiple languages](http://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-supported.html#gamelift-supported-clients) including C++ and C#. Use the SDK to access the API programmatically from an application, such as a game client.

*   The [AWS command-line interface](http://aws.amazon.com/cli/) (CLI) tool is primarily useful for handling administrative actions, such as setting up and managing Amazon GameLift settings and resources. You can use the AWS CLI to manage all of your AWS services.

*   The [AWS Management Console](https://console.aws.amazon.com/gamelift/home) for Amazon GameLift provides a web interface to manage your Amazon GameLift settings and resources. The console includes a dashboard for tracking key resources, including builds and fleets, and displays usage and performance metrics for your games as customizable graphs.

*   Amazon GameLift Local is a tool for testing your game's integration with Amazon GameLift before deploying it on the service. This tools supports a subset of key API actions, which can be called from either the AWS CLI or programmatically. See [Testing an Integration](http://docs.aws.amazon.com/gamelift/latest/developerguide/integration-testing-local.html).

**MORE RESOURCES**

*   [Amazon GameLift Developer Guide](http://docs.aws.amazon.com/gamelift/latest/developerguide/) -- Learn more about Amazon GameLift features and how to use them.

*   [Lumberyard and Amazon GameLift Tutorials](https://gamedev.amazon.com/forums/tutorials) -- Get started fast with walkthroughs and sample projects.

*   [GameDev Blog](http://aws.amazon.com/blogs/gamedev/) -- Stay up to date with new features and techniques.

*   [GameDev Forums](https://gamedev.amazon.com/forums/spaces/123/gamelift-discussion.html) -- Connect with the GameDev community.

*   [Amazon GameLift Document History](http://docs.aws.amazon.com/gamelift/latest/developerguide/doc-history.html) -- See changes to the Amazon GameLift service, SDKs, and documentation, as well as links to release notes.

**API SUMMARY**

This list offers a functional overview of the Amazon GameLift service API.

**Managing Games and Players**

Use these actions to start new game sessions, find existing game sessions, track game session status and other information, and enable player access to game sessions.

*   **Discover existing game sessions**

    *   [SearchGameSessions](@ref) -- Retrieve all available game sessions or search for game sessions that match a set of criteria.

*   **Start new game sessions**

    *   Start new games with Queues to find the best available hosting resources across multiple regions, minimize player latency, and balance game session activity for efficiency and cost effectiveness.

        *   [StartGameSessionPlacement](@ref) -- Request a new game session placement and add one or more players to it.

        *   [DescribeGameSessionPlacement](@ref) -- Get details on a placement request, including status.

        *   [StopGameSessionPlacement](@ref) -- Cancel a placement request.

    *   [CreateGameSession](@ref) -- Start a new game session on a specific fleet. *Available in Amazon GameLift Local.*

*   **Start new game sessions with FlexMatch matchmaking**

    *   [StartMatchmaking](@ref) -- Request matchmaking for one players or a group who want to play together.

    *   [DescribeMatchmaking](@ref) -- Get details on a matchmaking request, including status.

    *   [AcceptMatch](@ref) -- Register that a player accepts a proposed match, for matches that require player acceptance.

    *   [StopMatchmaking](@ref) -- Cancel a matchmaking request.

*   **Manage game session data**

    *   [DescribeGameSessions](@ref) -- Retrieve metadata for one or more game sessions, including length of time active and current player count. *Available in Amazon GameLift Local.*

    *   [DescribeGameSessionDetails](@ref) -- Retrieve metadata and the game session protection setting for one or more game sessions.

    *   [UpdateGameSession](@ref) -- Change game session settings, such as maximum player count and join policy.

    *   [GetGameSessionLogUrl](@ref) -- Get the location of saved logs for a game session.

*   **Manage player sessions**

    *   [CreatePlayerSession](@ref) -- Send a request for a player to join a game session. *Available in Amazon GameLift Local.*

    *   [CreatePlayerSessions](@ref) -- Send a request for multiple players to join a game session. *Available in Amazon GameLift Local.*

    *   [DescribePlayerSessions](@ref) -- Get details on player activity, including status, playing time, and player data. *Available in Amazon GameLift Local.*

**Setting Up and Managing Game Servers**

When setting up Amazon GameLift resources for your game, you first [create a game build](http://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html) and upload it to Amazon GameLift. You can then use these actions to configure and manage a fleet of resources to run your game servers, scale capacity to meet player demand, access performance and utilization metrics, and more.

*   **Manage game builds**

    *   [CreateBuild](@ref) -- Create a new build using files stored in an Amazon S3 bucket. (Update uploading permissions with [RequestUploadCredentials](@ref).) To create a build and upload files from a local path, use the AWS CLI command `upload-build`.

    *   [ListBuilds](@ref) -- Get a list of all builds uploaded to a Amazon GameLift region.

    *   [DescribeBuild](@ref) -- Retrieve information associated with a build.

    *   [UpdateBuild](@ref) -- Change build metadata, including build name and version.

    *   [DeleteBuild](@ref) -- Remove a build from Amazon GameLift.

*   **Manage fleets**

    *   [CreateFleet](@ref) -- Configure and activate a new fleet to run a build's game servers.

    *   [ListFleets](@ref) -- Get a list of all fleet IDs in a Amazon GameLift region (all statuses).

    *   [DeleteFleet](@ref) -- Terminate a fleet that is no longer running game servers or hosting players.

    *   View / update fleet configurations.

        *   [DescribeFleetAttributes](@ref) / [UpdateFleetAttributes](@ref) -- View or change a fleet's metadata and settings for game session protection and resource creation limits.

        *   [DescribeFleetPortSettings](@ref) / [UpdateFleetPortSettings](@ref) -- View or change the inbound permissions (IP address and port setting ranges) allowed for a fleet.

        *   [DescribeRuntimeConfiguration](@ref) / [UpdateRuntimeConfiguration](@ref) -- View or change what server processes (and how many) to run on each instance in a fleet.

*   **Control fleet capacity**

    *   [DescribeEC2InstanceLimits](@ref) -- Retrieve maximum number of instances allowed for the current AWS account and the current usage level.

    *   [DescribeFleetCapacity](@ref) / [UpdateFleetCapacity](@ref) -- Retrieve the capacity settings and the current number of instances in a fleet; adjust fleet capacity settings to scale up or down.

    *   Autoscale -- Manage autoscaling rules and apply them to a fleet.

        *   [PutScalingPolicy](@ref) -- Create a new autoscaling policy, or update an existing one.

        *   [DescribeScalingPolicies](@ref) -- Retrieve an existing autoscaling policy.

        *   [DeleteScalingPolicy](@ref) -- Delete an autoscaling policy and stop it from affecting a fleet's capacity.

*   **Manage VPC peering connections for fleets**

    *   [CreateVpcPeeringAuthorization](@ref) -- Authorize a peering connection to one of your VPCs.

    *   [DescribeVpcPeeringAuthorizations](@ref) -- Retrieve valid peering connection authorizations.

    *   [DeleteVpcPeeringAuthorization](@ref) -- Delete a peering connection authorization.

    *   [CreateVpcPeeringConnection](@ref) -- Establish a peering connection between the VPC for a Amazon GameLift fleet and one of your VPCs.

    *   [DescribeVpcPeeringConnections](@ref) -- Retrieve information on active or pending VPC peering connections with a Amazon GameLift fleet.

    *   [DeleteVpcPeeringConnection](@ref) -- Delete a VPC peering connection with a Amazon GameLift fleet.

*   **Access fleet activity statistics**

    *   [DescribeFleetUtilization](@ref) -- Get current data on the number of server processes, game sessions, and players currently active on a fleet.

    *   [DescribeFleetEvents](@ref) -- Get a fleet's logged events for a specified time span.

    *   [DescribeGameSessions](@ref) -- Retrieve metadata associated with one or more game sessions, including length of time active and current player count.

*   **Remotely access an instance**

    *   [DescribeInstances](@ref) -- Get information on each instance in a fleet, including instance ID, IP address, and status.

    *   [GetInstanceAccess](@ref) -- Request access credentials needed to remotely connect to a specified instance in a fleet.

*   **Manage fleet aliases**

    *   [CreateAlias](@ref) -- Define a new alias and optionally assign it to a fleet.

    *   [ListAliases](@ref) -- Get all fleet aliases defined in a Amazon GameLift region.

    *   [DescribeAlias](@ref) -- Retrieve information on an existing alias.

    *   [UpdateAlias](@ref) -- Change settings for a alias, such as redirecting it from one fleet to another.

    *   [DeleteAlias](@ref) -- Remove an alias from the region.

    *   [ResolveAlias](@ref) -- Get the fleet ID that a specified alias points to.

*   **Manage game session queues**

    *   [CreateGameSessionQueue](@ref) -- Create a queue for processing requests for new game sessions.

    *   [DescribeGameSessionQueues](@ref) -- Retrieve game session queues defined in a Amazon GameLift region.

    *   [UpdateGameSessionQueue](@ref) -- Change the configuration of a game session queue.

    *   [DeleteGameSessionQueue](@ref) -- Remove a game session queue from the region.

*   **Manage FlexMatch resources**

    *   [CreateMatchmakingConfiguration](@ref) -- Create a matchmaking configuration with instructions for building a player group and placing in a new game session.

    *   [DescribeMatchmakingConfigurations](@ref) -- Retrieve matchmaking configurations defined a Amazon GameLift region.

    *   [UpdateMatchmakingConfiguration](@ref) -- Change settings for matchmaking configuration. queue.

    *   [DeleteMatchmakingConfiguration](@ref) -- Remove a matchmaking configuration from the region.

    *   [CreateMatchmakingRuleSet](@ref) -- Create a set of rules to use when searching for player matches.

    *   [DescribeMatchmakingRuleSets](@ref) -- Retrieve matchmaking rule sets defined in a Amazon GameLift region.

    *   [ValidateMatchmakingRuleSet](@ref) -- Verify syntax for a set of matchmaking rules.

This document is generated from
[apis/gamelift-2015-10-01.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/gamelift-2015-10-01.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.GameLift.md"]
```

```@autodocs
Modules = [AWSSDK.GameLift]
```
