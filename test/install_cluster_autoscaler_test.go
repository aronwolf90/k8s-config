package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTemplateWithDefaultValues(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./install_cluster_autoscaler",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	template := terraform.Output(t, terraformOptions, "template")

  assert.Contains(t, template, "- --nodes=1:10:CPX21:fsn1:pool")
}

func TestTemplateWithMuliplePools(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./install_cluster_autoscaler",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
      "node_pools": []map[string]string{
        { "name": "pool1", "node_type": "CPX11", "location": "fsn1" },
        { "name": "pool2", "node_type": "CPX21", "location": "nbg1" },
      },
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	template := terraform.Output(t, terraformOptions, "template")

  assert.Contains(t, template, "- --nodes=1:10:CPX11:fsn1:pool1")
  assert.Contains(t, template, "- --nodes=1:10:CPX21:nbg1:pool2")
}
