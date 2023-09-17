package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestOutputsHost(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./outputs",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	host := terraform.Output(t, terraformOptions, "host")
  assert.Equal(t, host, "https://128.140.25.64:6443")
}

func TestOutputsClusterCaCertificate(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./outputs",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	host := terraform.Output(t, terraformOptions, "cluster_ca_certificate")
  assert.Equal(t, host, "certificate-authority-data-test")
}

func TestOutputsClientCertificate(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./outputs",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
    },
  })

  defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)

	host := terraform.Output(t, terraformOptions, "client_certificate")
  assert.Equal(t, host, "client-certificate-data-test")
}

func TestOutputsClientKeyData(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./outputs",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
    },
  })

  defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)

	host := terraform.Output(t, terraformOptions, "client_key")
  assert.Equal(t, host, "client-key-data-test")
}
