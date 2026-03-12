package tests

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclparse"
	"github.com/zclconf/go-cty/cty"
)

// TerraformConfig represents a parsed Terraform configuration
type TerraformConfig struct {
	Resources map[string][]Resource
	Variables map[string]Variable
	Outputs   map[string]Output
}

// Resource represents a Terraform resource
type Resource struct {
	Type       string
	Name       string
	Attributes map[string]interface{}
}

// Variable represents a Terraform variable
type Variable struct {
	Name        string
	Type        string
	Description string
	Default     interface{}
}

// Output represents a Terraform output
type Output struct {
	Name        string
	Description string
	Value       interface{}
}

// ParseTerraformConfig parses Terraform configuration files from a directory
func ParseTerraformConfig(terraformDir string) (*TerraformConfig, error) {
	config := &TerraformConfig{
		Resources: make(map[string][]Resource),
		Variables: make(map[string]Variable),
		Outputs:   make(map[string]Output),
	}

	// Find all .tf files in the directory
	files, err := filepath.Glob(filepath.Join(terraformDir, "*.tf"))
	if err != nil {
		return nil, fmt.Errorf("failed to find .tf files: %w", err)
	}

	parser := hclparse.NewParser()

	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			return nil, fmt.Errorf("failed to read file %s: %w", file, err)
		}

		parsedFile, diags := parser.ParseHCL(content, file)
		if diags.HasErrors() {
			return nil, fmt.Errorf("failed to parse HCL in %s: %s", file, diags.Error())
		}

		// Parse resources, variables, and outputs from the file
		if err := parseHCLFile(parsedFile.Body, config); err != nil {
			return nil, fmt.Errorf("failed to parse file %s: %w", file, err)
		}
	}

	return config, nil
}

// parseHCLFile extracts resources, variables, and outputs from HCL body
func parseHCLFile(body hcl.Body, config *TerraformConfig) error {
	content, _, diags := body.PartialContent(&hcl.BodySchema{
		Blocks: []hcl.BlockHeaderSchema{
			{Type: "resource", LabelNames: []string{"type", "name"}},
			{Type: "variable", LabelNames: []string{"name"}},
			{Type: "output", LabelNames: []string{"name"}},
		},
	})

	if diags.HasErrors() {
		return fmt.Errorf("failed to parse body: %s", diags.Error())
	}

	// Parse resources
	for _, block := range content.Blocks {
		switch block.Type {
		case "resource":
			resource := parseResource(block)
			config.Resources[resource.Type] = append(config.Resources[resource.Type], resource)
		case "variable":
			variable := parseVariable(block)
			config.Variables[variable.Name] = variable
		case "output":
			output := parseOutput(block)
			config.Outputs[output.Name] = output
		}
	}

	return nil
}

// parseResource extracts resource information from HCL block
func parseResource(block *hcl.Block) Resource {
	resource := Resource{
		Type:       block.Labels[0],
		Name:       block.Labels[1],
		Attributes: make(map[string]interface{}),
	}

	attrs, _ := block.Body.JustAttributes()
	for name, attr := range attrs {
		val, _ := attr.Expr.Value(nil)
		resource.Attributes[name] = ctyToInterface(val)
	}

	return resource
}

// parseVariable extracts variable information from HCL block
func parseVariable(block *hcl.Block) Variable {
	variable := Variable{
		Name: block.Labels[0],
	}

	attrs, _ := block.Body.JustAttributes()
	for name, attr := range attrs {
		val, _ := attr.Expr.Value(nil)
		switch name {
		case "type":
			variable.Type = ctyToString(val)
		case "description":
			variable.Description = ctyToString(val)
		case "default":
			variable.Default = ctyToInterface(val)
		}
	}

	return variable
}

// parseOutput extracts output information from HCL block
func parseOutput(block *hcl.Block) Output {
	output := Output{
		Name: block.Labels[0],
	}

	attrs, _ := block.Body.JustAttributes()
	for name, attr := range attrs {
		val, _ := attr.Expr.Value(nil)
		switch name {
		case "description":
			output.Description = ctyToString(val)
		case "value":
			output.Value = ctyToInterface(val)
		}
	}

	return output
}

// ctyToInterface converts cty.Value to Go interface{}
func ctyToInterface(val cty.Value) interface{} {
	if val.IsNull() {
		return nil
	}

	switch val.Type() {
	case cty.String:
		return val.AsString()
	case cty.Number:
		f, _ := val.AsBigFloat().Float64()
		return f
	case cty.Bool:
		return val.True()
	default:
		// For complex types, convert to JSON
		jsonBytes, _ := json.Marshal(val)
		var result interface{}
		json.Unmarshal(jsonBytes, &result)
		return result
	}
}

// ctyToString converts cty.Value to string
func ctyToString(val cty.Value) string {
	if val.IsNull() {
		return ""
	}
	if val.Type() == cty.String {
		return val.AsString()
	}
	return fmt.Sprintf("%v", ctyToInterface(val))
}

// FindResource finds a specific resource by type and name
func (c *TerraformConfig) FindResource(resourceType, resourceName string) *Resource {
	resources, exists := c.Resources[resourceType]
	if !exists {
		return nil
	}

	for _, resource := range resources {
		if resource.Name == resourceName {
			return &resource
		}
	}

	return nil
}

// FindAllResources finds all resources of a specific type
func (c *TerraformConfig) FindAllResources(resourceType string) []Resource {
	return c.Resources[resourceType]
}

// FindAllTaggableResources finds all resources that support tags
func (c *TerraformConfig) FindAllTaggableResources() []Resource {
	taggableTypes := []string{
		"aws_s3_bucket",
		"aws_cloudtrail",
		"aws_dynamodb_table",
		"aws_sns_topic",
		"aws_budgets_budget",
		"aws_ssoadmin_permission_set",
	}

	var taggableResources []Resource
	for _, resourceType := range taggableTypes {
		resources := c.FindAllResources(resourceType)
		taggableResources = append(taggableResources, resources...)
	}

	return taggableResources
}

// GetAttribute safely retrieves an attribute from a resource
func (r *Resource) GetAttribute(key string) (interface{}, bool) {
	val, exists := r.Attributes[key]
	return val, exists
}

// GetAttributeString retrieves an attribute as string
func (r *Resource) GetAttributeString(key string) string {
	val, exists := r.Attributes[key]
	if !exists {
		return ""
	}
	if str, ok := val.(string); ok {
		return str
	}
	return fmt.Sprintf("%v", val)
}

// GetAttributeBool retrieves an attribute as bool
func (r *Resource) GetAttributeBool(key string) bool {
	val, exists := r.Attributes[key]
	if !exists {
		return false
	}
	if b, ok := val.(bool); ok {
		return b
	}
	return false
}

// GetAttributeMap retrieves an attribute as map
func (r *Resource) GetAttributeMap(key string) map[string]interface{} {
	val, exists := r.Attributes[key]
	if !exists {
		return nil
	}
	if m, ok := val.(map[string]interface{}); ok {
		return m
	}
	return nil
}

// HasTag checks if a resource has a specific tag
func (r *Resource) HasTag(tagKey string) bool {
	tags := r.GetAttributeMap("tags")
	if tags == nil {
		return false
	}
	_, exists := tags[tagKey]
	return exists
}

// GetTag retrieves a tag value from a resource
func (r *Resource) GetTag(tagKey string) string {
	tags := r.GetAttributeMap("tags")
	if tags == nil {
		return ""
	}
	val, exists := tags[tagKey]
	if !exists {
		return ""
	}
	if str, ok := val.(string); ok {
		return str
	}
	return fmt.Sprintf("%v", val)
}

// GetTerraformOptions creates standard Terratest options for a module
func GetTerraformOptions(terraformDir string, vars map[string]interface{}) *terraform.Options {
	return &terraform.Options{
		TerraformDir: terraformDir,
		Vars:         vars,
		NoColor:      true,
	}
}

// GetModulePath returns the absolute path to a Terraform module
func GetModulePath(moduleName string) string {
	// Assuming tests are in tests/ directory and modules are in ../modules/
	return filepath.Join("..", "modules", moduleName)
}

// GetBootstrapPath returns the absolute path to the bootstrap directory
func GetBootstrapPath() string {
	return filepath.Join("..", "bootstrap")
}

// GetRootModulePath returns the absolute path to the root module
func GetRootModulePath() string {
	return filepath.Join("..")
}

// ValidateRequiredTags checks if a resource has all required tags
func ValidateRequiredTags(resource Resource, requiredTags []string) []string {
	var missingTags []string

	for _, tagKey := range requiredTags {
		if !resource.HasTag(tagKey) {
			missingTags = append(missingTags, tagKey)
		}
	}

	return missingTags
}

// ValidateS3BucketEncryption checks if an S3 bucket has encryption configured
func ValidateS3BucketEncryption(config *TerraformConfig, bucketName string) (bool, string) {
	// Find encryption configuration resource
	encryptionResources := config.FindAllResources("aws_s3_bucket_server_side_encryption_configuration")

	for _, resource := range encryptionResources {
		bucket := resource.GetAttributeString("bucket")
		if strings.Contains(bucket, bucketName) || bucket == bucketName {
			// Check for encryption algorithm
			if rule, exists := resource.GetAttribute("rule"); exists {
				if ruleList, ok := rule.([]interface{}); ok && len(ruleList) > 0 {
					if ruleMap, ok := ruleList[0].(map[string]interface{}); ok {
						if applyDefault, ok := ruleMap["apply_server_side_encryption_by_default"].([]interface{}); ok && len(applyDefault) > 0 {
							if defaultMap, ok := applyDefault[0].(map[string]interface{}); ok {
								if algo, ok := defaultMap["sse_algorithm"].(string); ok {
									return true, algo
								}
							}
						}
					}
				}
			}
		}
	}

	return false, ""
}

// ValidateS3BucketVersioning checks if an S3 bucket has versioning enabled
func ValidateS3BucketVersioning(config *TerraformConfig, bucketName string) bool {
	versioningResources := config.FindAllResources("aws_s3_bucket_versioning")

	for _, resource := range versioningResources {
		bucket := resource.GetAttributeString("bucket")
		if strings.Contains(bucket, bucketName) || bucket == bucketName {
			if versioningConfig, exists := resource.GetAttribute("versioning_configuration"); exists {
				if configList, ok := versioningConfig.([]interface{}); ok && len(configList) > 0 {
					if configMap, ok := configList[0].(map[string]interface{}); ok {
						if status, ok := configMap["status"].(string); ok {
							return status == "Enabled"
						}
					}
				}
			}
		}
	}

	return false
}

// ValidateS3BucketPublicAccessBlock checks if an S3 bucket blocks public access
func ValidateS3BucketPublicAccessBlock(config *TerraformConfig, bucketName string) (bool, map[string]bool) {
	blockResources := config.FindAllResources("aws_s3_bucket_public_access_block")

	settings := map[string]bool{
		"block_public_acls":       false,
		"block_public_policy":     false,
		"ignore_public_acls":      false,
		"restrict_public_buckets": false,
	}

	for _, resource := range blockResources {
		bucket := resource.GetAttributeString("bucket")
		if strings.Contains(bucket, bucketName) || bucket == bucketName {
			for key := range settings {
				settings[key] = resource.GetAttributeBool(key)
			}
			return true, settings
		}
	}

	return false, settings
}
