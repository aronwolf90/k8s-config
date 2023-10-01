package test

import (
  "io/ioutil"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestManifestCcmNetworks(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./manifest_ccm_networks/",
  })
  terraform.InitAndApply(t, terraformOptions)

  defer terraform.Destroy(t, terraformOptions)

  expectedKubeconfig, err := ioutil.ReadFile("./manifest_ccm_networks/tmp/kubeconfig")
  if err != nil {
    panic(err)
  }

  actualKubeconfig, err := ioutil.ReadFile("./manifest_ccm_networks/kubeconfig")
  if err != nil {
    panic(err)
  }

  assert.Equal(t, expectedKubeconfig, actualKubeconfig)
}
