package tests

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestParseBootstrapConfig tests parsing of bootstrap Terraform configuration
func TestParseBootstrapConfig(t *testing.T) {
	// This is an example test to demonstrate the helper functions
	// It will be used as a template for actual unit tests

	config, err := ParseTerraformConfig(GetBootstrapPath())
	assert.NoError(t, err, "Should parse bootstrap configuration without errors")
	assert.NotNil(t, config, "Configuration should not be nil")

	// Verify S3 bucket resource exists
	s3Buckets := config.FindAllResources("aws_s3_bucket")
	assert.NotEmpty(t, s3Buckets, "Should find at least one S3 bucket")

	// Verify DynamoDB table resource exists
	dynamoTables := config.FindAllResources("aws_dynamodb_table")
	assert.NotEmpty(t, dynamoTables, "Should find at least one DynamoDB table")
}

// TestResourceHelpers tests the resource helper functions
func TestResourceHelpers(t *testing.T) {
	// Create a mock resource for testing
	resource := Resource{
		Type: "aws_s3_bucket",
		Name: "test_bucket",
		Attributes: map[string]interface{}{
			"bucket": "test-bucket-name",
			"tags": map[string]interface{}{
				"ManagedBy":   "Terraform",
				"Project":     "AWS-Security-Setup",
				"Environment": "Production",
			},
		},
	}

	// Test GetAttributeString
	bucketName := resource.GetAttributeString("bucket")
	assert.Equal(t, "test-bucket-name", bucketName)

	// Test HasTag
	assert.True(t, resource.HasTag("ManagedBy"))
	assert.True(t, resource.HasTag("Project"))
	assert.False(t, resource.HasTag("NonExistent"))

	// Test GetTag
	assert.Equal(t, "Terraform", resource.GetTag("ManagedBy"))
	assert.Equal(t, "AWS-Security-Setup", resource.GetTag("Project"))
	assert.Equal(t, "", resource.GetTag("NonExistent"))

	// Test ValidateRequiredTags
	requiredTags := []string{"ManagedBy", "Project", "Environment"}
	missingTags := ValidateRequiredTags(resource, requiredTags)
	assert.Empty(t, missingTags, "Should have all required tags")

	// Test with missing tag
	resource.Attributes["tags"] = map[string]interface{}{
		"ManagedBy": "Terraform",
		"Project":   "AWS-Security-Setup",
	}
	missingTags = ValidateRequiredTags(resource, requiredTags)
	assert.Contains(t, missingTags, "Environment", "Should detect missing Environment tag")
}

// TestFindResource tests finding specific resources
func TestFindResource(t *testing.T) {
	config := &TerraformConfig{
		Resources: map[string][]Resource{
			"aws_s3_bucket": {
				{Type: "aws_s3_bucket", Name: "bucket1"},
				{Type: "aws_s3_bucket", Name: "bucket2"},
			},
			"aws_dynamodb_table": {
				{Type: "aws_dynamodb_table", Name: "table1"},
			},
		},
	}

	// Test FindResource
	bucket := config.FindResource("aws_s3_bucket", "bucket1")
	assert.NotNil(t, bucket)
	assert.Equal(t, "bucket1", bucket.Name)

	// Test FindResource with non-existent resource
	nonExistent := config.FindResource("aws_s3_bucket", "bucket3")
	assert.Nil(t, nonExistent)

	// Test FindAllResources
	buckets := config.FindAllResources("aws_s3_bucket")
	assert.Len(t, buckets, 2)

	tables := config.FindAllResources("aws_dynamodb_table")
	assert.Len(t, tables, 1)
}

// TestPathHelpers tests the path helper functions
func TestPathHelpers(t *testing.T) {
	// Test module path
	modulePath := GetModulePath("cloudtrail")
	assert.Contains(t, modulePath, "modules/cloudtrail")

	// Test bootstrap path
	bootstrapPath := GetBootstrapPath()
	assert.Contains(t, bootstrapPath, "bootstrap")

	// Test root module path
	rootPath := GetRootModulePath()
	assert.NotEmpty(t, rootPath)
}

// TestValidateS3BucketEncryption tests S3 encryption validation
func TestValidateS3BucketEncryption(t *testing.T) {
	config := &TerraformConfig{
		Resources: map[string][]Resource{
			"aws_s3_bucket": {
				{
					Type: "aws_s3_bucket",
					Name: "test_bucket",
					Attributes: map[string]interface{}{
						"bucket": "test-bucket-name",
					},
				},
			},
			"aws_s3_bucket_server_side_encryption_configuration": {
				{
					Type: "aws_s3_bucket_server_side_encryption_configuration",
					Name: "test_bucket",
					Attributes: map[string]interface{}{
						"bucket": "test-bucket-name",
						"rule": []interface{}{
							map[string]interface{}{
								"apply_server_side_encryption_by_default": []interface{}{
									map[string]interface{}{
										"sse_algorithm": "AES256",
									},
								},
							},
						},
					},
				},
			},
		},
	}

	// Test encryption validation
	hasEncryption, algorithm := ValidateS3BucketEncryption(config, "test-bucket-name")
	assert.True(t, hasEncryption, "Should find encryption configuration")
	assert.Equal(t, "AES256", algorithm, "Should use AES256 encryption")

	// Test with non-existent bucket
	hasEncryption, _ = ValidateS3BucketEncryption(config, "non-existent-bucket")
	assert.False(t, hasEncryption, "Should not find encryption for non-existent bucket")
}

// TestValidateS3BucketPublicAccessBlock tests S3 public access block validation
func TestValidateS3BucketPublicAccessBlock(t *testing.T) {
	config := &TerraformConfig{
		Resources: map[string][]Resource{
			"aws_s3_bucket_public_access_block": {
				{
					Type: "aws_s3_bucket_public_access_block",
					Name: "test_bucket",
					Attributes: map[string]interface{}{
						"bucket":                   "test-bucket-name",
						"block_public_acls":        true,
						"block_public_policy":      true,
						"ignore_public_acls":       true,
						"restrict_public_buckets":  true,
					},
				},
			},
		},
	}

	// Test public access block validation
	hasBlock, settings := ValidateS3BucketPublicAccessBlock(config, "test-bucket-name")
	assert.True(t, hasBlock, "Should find public access block configuration")
	assert.True(t, settings["block_public_acls"], "Should block public ACLs")
	assert.True(t, settings["block_public_policy"], "Should block public policy")
	assert.True(t, settings["ignore_public_acls"], "Should ignore public ACLs")
	assert.True(t, settings["restrict_public_buckets"], "Should restrict public buckets")

	// Test with non-existent bucket
	hasBlock, _ = ValidateS3BucketPublicAccessBlock(config, "non-existent-bucket")
	assert.False(t, hasBlock, "Should not find public access block for non-existent bucket")
}
