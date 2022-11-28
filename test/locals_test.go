package test

import (
	"testing"
  "os"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestDefaultPublicSshKeyList(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./locals",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	outputPublicSshKeyList := terraform.OutputList(t, terraformOptions, "public_ssh_key_list")
  dirname, _ := os.UserHomeDir()
  publicKey, _ := os.ReadFile(dirname + "/.ssh/id_rsa.pub")

  assert.Equal(t, outputPublicSshKeyList, []string{string(publicKey)})
}

func TestPublicSshKeyList(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./locals",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
      "ssh_public_keys": []map[string]string{
        {"name": "first", "key": "test_key1" },
        {"name": "second", "key": "test_key2" },
      },
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	outputPublicSshKeyList := terraform.OutputList(t, terraformOptions, "public_ssh_key_list")
  assert.Equal(t, outputPublicSshKeyList, []string{"test_key1", "test_key2"})
}

func TestTransformedMasterNodes(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./locals",
    Vars: map[string]interface{} {
      "hcloud_token": "test_token",
      "master_nodes": []map[string]string{
        { "name": "master1", "image": "20.04", "location": "fsn1" },
        { "name": "master2", "image": "20.04", "location": "nbg1" },
      },
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	outputTransformedMasterNodes := terraform.OutputMapOfObjects(t, terraformOptions, "transformed_master_nodes")
  assert.Equal(t, outputTransformedMasterNodes, map[string]interface{}{
    "master1": map[string]interface{}{
      "image": "20.04",
      "location": "fsn1",
    },
    "master2": map[string]interface{}{
      "image": "20.04",
      "location": "nbg1",
    },
  })
}
