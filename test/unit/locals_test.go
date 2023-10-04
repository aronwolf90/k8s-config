package test

import (
	"testing"
  "os"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestDefaultPublicSshKeys(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./locals",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	outputPublicSshKeys := terraform.OutputListOfObjects(t, terraformOptions, "public_ssh_keys")
  dirname, _ := os.UserHomeDir()
  publicKey, _ := os.ReadFile(dirname + "/.ssh/id_rsa.pub")

  expectedResult := []map[string]interface{}{
    map[string]interface{}{
      "name": "default",
      "key": string(publicKey),
    },
  }
  assert.Equal(t, expectedResult, outputPublicSshKeys)
}

func TestPublicSshKeys(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./locals",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
      "public_ssh_keys": []map[string]string{
        {"name": "first", "key": "test_key1" },
        {"name": "second", "key": "test_key2" },
      },
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	outputPublicSshKeys := terraform.OutputList(t, terraformOptions, "public_ssh_keys")
  assert.Equal(t, outputPublicSshKeys, []string([]string{"map[key:test_key1 name:first]", "map[key:test_key2 name:second]"}))
}
