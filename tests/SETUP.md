# Test Setup Guide

This guide explains how to set up the testing environment for the AWS Account Security Setup Terraform project.

## Prerequisites

### Required Software

1. **Go 1.21 or later**
   - Download from: https://go.dev/dl/
   - Verify installation: `go version`

2. **Terraform 1.6.0 or later**
   - Download from: https://www.terraform.io/downloads
   - Verify installation: `terraform version`

3. **Git**
   - For version control and cloning the repository
   - Verify installation: `git --version`

### Optional (for integration tests)

4. **AWS CLI**
   - Download from: https://aws.amazon.com/cli/
   - Configure with: `aws configure`
   - Required only if running integration tests that deploy to AWS

## Installation Steps

### 1. Navigate to Tests Directory

```bash
cd tests
```

### 2. Initialize Go Module

Download all required dependencies:

```bash
go mod download
```

This will download:
- **Terratest** (v0.46.8) - Terraform testing framework
- **gopter** (v0.2.9) - Property-based testing library
- **testify** (v1.8.4) - Assertion library
- Various AWS SDK and Terraform dependencies

### 3. Verify Installation

Check that all dependencies are installed:

```bash
go mod verify
```

Expected output: `all modules verified`

### 4. Run Helper Tests

Verify the helper functions work correctly:

```bash
go test -v helpers_test.go helpers.go
```

Expected output: All tests should pass

## Project Structure

After setup, your tests directory should look like:

```
tests/
├── go.mod                  # Go module definition
├── go.sum                  # Dependency checksums (auto-generated)
├── helpers.go              # Helper functions for parsing Terraform
├── helpers_test.go         # Tests for helper functions
├── README.md               # Testing documentation
├── SETUP.md               # This file
├── unit/                   # Unit tests (to be added in tasks 10.2-10.7)
│   └── .gitkeep
└── property/               # Property tests (to be added in task 11)
    └── .gitkeep
```

## Running Tests

### Basic Test Commands

```bash
# Run all tests
go test -v ./...

# Run tests with coverage
go test -v -cover ./...

# Run tests with race detection
go test -v -race ./...

# Run specific test
go test -v -run TestParseBootstrapConfig

# Run tests without cache
go test -v -count=1 ./...
```

### Test Output Flags

- `-v` - Verbose output (shows test names and results)
- `-cover` - Show code coverage percentage
- `-race` - Enable race condition detection
- `-count=1` - Disable test caching (always run fresh)
- `-timeout 30s` - Set test timeout (default: 10m)

## Troubleshooting

### Issue: "go: command not found"

**Solution**: Install Go from https://go.dev/dl/ and add it to your PATH

```bash
# macOS/Linux - Add to ~/.bashrc or ~/.zshrc
export PATH=$PATH:/usr/local/go/bin

# Verify
go version
```

### Issue: "cannot find package"

**Solution**: Download dependencies

```bash
go mod download
go mod tidy
```

### Issue: "HCL parsing errors"

**Solution**: Validate Terraform configuration

```bash
cd ..
terraform fmt -recursive
terraform validate
```

### Issue: "module not found" in tests

**Solution**: Ensure you're running tests from the tests/ directory

```bash
cd tests
go test -v ./...
```

### Issue: Tests fail with "file not found"

**Solution**: Verify Terraform files exist in expected locations

```bash
# From tests/ directory
ls -la ../bootstrap/
ls -la ../modules/
```

## Development Workflow

### 1. Write Test

Create a new test file in `unit/` or `property/`:

```bash
# Example: Create CloudTrail unit test
touch unit/cloudtrail_test.go
```

### 2. Run Test

```bash
go test -v ./unit/cloudtrail_test.go
```

### 3. Debug Test

Add print statements or use Go debugger:

```go
import "fmt"

func TestMyTest(t *testing.T) {
    fmt.Printf("Debug: value = %v\n", value)
    // ... test code
}
```

### 4. Format Code

```bash
go fmt ./...
```

### 5. Run All Tests

```bash
go test -v ./...
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.6.0'
      
      - name: Download Go Dependencies
        run: |
          cd tests
          go mod download
      
      - name: Run Tests
        run: |
          cd tests
          go test -v -cover ./...
```

## Best Practices

1. **Always run tests before committing**
   ```bash
   go test -v ./...
   ```

2. **Keep tests fast**
   - Unit tests should complete in < 1 second
   - Property tests should complete in < 10 seconds
   - Avoid actual AWS deployments in unit tests

3. **Use descriptive test names**
   ```go
   func TestCloudTrailHasMultiRegionEnabled(t *testing.T) { ... }
   ```

4. **Clean up test resources**
   ```go
   defer terraform.Destroy(t, terraformOptions)
   ```

5. **Use table-driven tests for multiple scenarios**
   ```go
   tests := []struct {
       name     string
       input    string
       expected string
   }{
       {"scenario1", "input1", "output1"},
       {"scenario2", "input2", "output2"},
   }
   ```

## Next Steps

After completing this setup:

1. **Task 10.2-10.7**: Write unit tests for each module
2. **Task 11.1-11.3**: Write property-based tests
3. **Task 12**: Configure static analysis tools (tflint, tfsec)
4. **Task 14**: Run complete test suite

## Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [gopter Documentation](https://github.com/leanovate/gopter)
- [Go Testing Package](https://pkg.go.dev/testing)
- [Testify Assertions](https://pkg.go.dev/github.com/stretchr/testify/assert)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review test output for specific error messages
3. Verify Terraform configuration is valid
4. Ensure all prerequisites are installed
