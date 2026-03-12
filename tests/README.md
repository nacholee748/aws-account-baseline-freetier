# Terraform Tests

This directory contains unit tests and property-based tests for the AWS Account Security Setup Terraform configuration.

## Structure

```
tests/
├── go.mod                  # Go module definition with Terratest and gopter dependencies
├── helpers.go              # Helper functions for parsing Terraform configuration
├── unit/                   # Unit tests for specific configurations
│   ├── bootstrap_test.go
│   ├── cloudtrail_test.go
│   ├── budgets_test.go
│   ├── account_security_test.go
│   ├── iam_identity_center_test.go
│   └── sns_test.go
└── property/               # Property-based tests for universal invariants
    ├── cloudtrail_property_test.go
    ├── encryption_property_test.go
    └── tagging_property_test.go
```

## Prerequisites

- Go 1.21 or later
- Terraform installed and in PATH
- AWS credentials configured (for integration tests)

## Installation

Initialize the Go module and download dependencies:

```bash
cd tests
go mod download
```

## Running Tests

### Run all tests
```bash
go test -v ./...
```

### Run unit tests only
```bash
go test -v ./unit/...
```

### Run property-based tests only
```bash
go test -v ./property/...
```

### Run specific test file
```bash
go test -v ./unit/cloudtrail_test.go
```

### Run with verbose output
```bash
go test -v -count=1 ./...
```

## Helper Functions

The `helpers.go` file provides utility functions for testing Terraform configurations:

### Configuration Parsing

- `ParseTerraformConfig(terraformDir string)` - Parse all .tf files in a directory
- `FindResource(resourceType, resourceName string)` - Find a specific resource
- `FindAllResources(resourceType string)` - Find all resources of a type
- `FindAllTaggableResources()` - Find all resources that support tags

### Resource Validation

- `ValidateRequiredTags(resource, requiredTags)` - Check if resource has required tags
- `ValidateS3BucketEncryption(config, bucketName)` - Verify S3 bucket encryption
- `ValidateS3BucketVersioning(config, bucketName)` - Verify S3 bucket versioning
- `ValidateS3BucketPublicAccessBlock(config, bucketName)` - Verify S3 public access block

### Path Helpers

- `GetModulePath(moduleName string)` - Get path to a Terraform module
- `GetBootstrapPath()` - Get path to bootstrap directory
- `GetRootModulePath()` - Get path to root module

## Test Types

### Unit Tests

Unit tests validate specific configurations and examples from the acceptance criteria. They test:

- CloudTrail configuration (multi-region, log validation, S3 bucket settings)
- Budget configuration (zero-dollar budget, free tier monitoring)
- Account security policies (S3 public access block, IAM password policy)
- IAM Identity Center permission sets (Admin, Developer, ReadOnly)
- SNS topics and subscriptions
- Bootstrap resources (S3 state bucket, DynamoDB lock table)

### Property-Based Tests

Property-based tests verify universal invariants that must hold across all resources:

1. **CloudTrail Management Events Coverage** - CloudTrail captures all management events
2. **S3 Bucket Encryption Enforcement** - All S3 buckets have encryption enabled
3. **Resource Tagging Compliance** - All resources have required tags

Property tests use gopter to generate test cases and verify properties hold across all valid configurations.

## Writing New Tests

### Unit Test Template

```go
package unit

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/aws-account-security-setup/tests"
)

func TestMyConfiguration(t *testing.T) {
    // Parse Terraform configuration
    config, err := tests.ParseTerraformConfig(tests.GetModulePath("my-module"))
    assert.NoError(t, err)

    // Find resource
    resource := config.FindResource("aws_resource_type", "resource_name")
    assert.NotNil(t, resource)

    // Validate attributes
    assert.Equal(t, "expected_value", resource.GetAttributeString("attribute_name"))
}
```

### Property Test Template

```go
package property

import (
    "testing"
    "github.com/leanovate/gopter"
    "github.com/leanovate/gopter/prop"
    "github.com/aws-account-security-setup/tests"
)

func TestProperty_MyInvariant(t *testing.T) {
    properties := gopter.NewProperties(nil)

    properties.Property("Description of property",
        prop.ForAll(
            func() bool {
                config, err := tests.ParseTerraformConfig(tests.GetRootModulePath())
                if err != nil {
                    return false
                }

                // Verify property holds for all resources
                resources := config.FindAllResources("aws_resource_type")
                for _, resource := range resources {
                    // Check invariant
                    if !checkInvariant(resource) {
                        return false
                    }
                }

                return true
            },
        ))

    properties.TestingRun(t, gopter.ConsoleReporter(false))
}
```

## CI/CD Integration

These tests are designed to run in CI/CD pipelines. They validate Terraform configuration without requiring AWS deployment.

For integration tests that deploy to AWS, use a separate test AWS account and ensure proper cleanup with `defer terraform.Destroy()`.

## Troubleshooting

### HCL Parsing Errors

If you encounter HCL parsing errors, ensure:
- All .tf files have valid syntax
- Run `terraform fmt` to format files
- Run `terraform validate` to check configuration

### Module Not Found

If Go cannot find modules:
```bash
go mod tidy
go mod download
```

### Test Failures

For test failures:
1. Check the error message for specific assertion failures
2. Verify Terraform configuration matches expected values
3. Run `terraform plan` to see what would be created
4. Use `-v` flag for verbose test output

## References

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [gopter Documentation](https://github.com/leanovate/gopter)
- [Go Testing Package](https://pkg.go.dev/testing)
