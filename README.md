# AWS Lambda Web Adapter Example

[AWS LWA](https://github.com/awslabs/aws-lambda-web-adapter) allows running any web application on supported deployment platforms without having to adapt them to Lambda.

This example demonstrates LWA usage by deploying a simple [HonoJS](https://hono.dev/) web application using [OpenTofu](https://opentofu.org/).

## Requirements

* `NodeJS 22.x`
* `OpenTofu`
* `AWS Account`

## Setup

After cloning, run the following commands:

```sh
make app-install
make tf-init
```

## Development

* Run the application: `make app-dev`
* Build the application: `make app-build`
* Run the built application in *preview* mode. LWA will use the `run.sh` file to start the application: `make app-preview`

## Deployment

* Assume a role in an AWS account.
* Create and validate plan: `make tf-plan`
* Deploy the infrastructure: `make tf-apply`
* Destroy the infrastructure: `make tf-destroy`
