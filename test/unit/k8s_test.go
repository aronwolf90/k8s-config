package test

import (
  "encoding/json"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
  "github.com/yalp/jsonpath"
)

func TestK0sV1_21_14_k0s_0(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./k8s",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "k0s_version": "v1.21.14+k0s.0",
    },
  })

  plan := terraform.InitAndPlanAndShow(t, terraformOptions)
  var planParsed interface{}
  err := json.Unmarshal([]byte(plan), &planParsed)
  if err != nil {
    panic(err)
  }
  noTaints, err := jsonpath.Read(planParsed, "$.resource_changes[0].change.after.hosts[0].no_taints")
  if err != nil {
    panic(err)
  }

  assert.Equal(t, nil, noTaints)
}

func TestK0sV1_22_17_k0s_0(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./k8s",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "k0s_version": "v1.22.17+k0s.0",
    },
  })

  plan := terraform.InitAndPlanAndShow(t, terraformOptions)
  var planParsed interface{}
  err := json.Unmarshal([]byte(plan), &planParsed)
  if err != nil {
    panic(err)
  }
  noTaints, err := jsonpath.Read(planParsed, "$.resource_changes[0].change.after.hosts[0].no_taints")
  if err != nil {
    panic(err)
  }

  assert.Equal(t, nil, noTaints)
}

func TestK0sV1_23_17_k0s_0(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./k8s",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "k0s_version": "v1.23.17+k0s.0",
    },
  })

  plan := terraform.InitAndPlanAndShow(t, terraformOptions)
  var planParsed interface{}
  err := json.Unmarshal([]byte(plan), &planParsed)
  if err != nil {
    panic(err)
  }
  noTaints, err := jsonpath.Read(planParsed, "$.resource_changes[0].change.after.hosts[0].no_taints")
  if err != nil {
    panic(err)
  }

  assert.Equal(t, true, noTaints)
}
