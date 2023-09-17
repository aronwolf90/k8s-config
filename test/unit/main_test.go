package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TesMain(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./nodes",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "hcloud_token": "123456789_123456789_123456789_123456789_123456789_123456789_1234",
    },
  })

  terraform.InitAndPlan(t, terraformOptions)
}
