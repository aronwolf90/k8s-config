package test

import (
  "io/ioutil"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestManifestHcloudSecret(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./manifest_hcloud_secret/",
  })
  terraform.InitAndApply(t, terraformOptions)

  defer terraform.Destroy(t, terraformOptions)

  expectedKubeconfig, err := ioutil.ReadFile("./manifest_hcloud_secret/tmp/kubeconfig")
  if err != nil {
    panic(err)
  }

  actualKubeconfig, err := ioutil.ReadFile("./manifest_hcloud_secret/kubeconfig")
  if err != nil {
    panic(err)
  }

  assert.Equal(t, expectedKubeconfig, actualKubeconfig)
}
