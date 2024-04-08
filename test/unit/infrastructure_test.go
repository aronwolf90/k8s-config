package test

import (
  "encoding/json"
  "io/ioutil"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/nsf/jsondiff"
  "github.com/oliveagle/jsonpath"
	"github.com/stretchr/testify/assert"
)

func TestInfrastructure(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./infrastructure",
    PlanFilePath: "./.tmp", 
  })

  plan := terraform.InitAndPlanAndShow(t, terraformOptions)
  var planParsed interface{}
  err := json.Unmarshal([]byte(plan), &planParsed)
  if err != nil {
    panic(err)
  }
  resourceChanges, err := jsonpath.JsonPathLookup(planParsed, "$.output_changes")
  if err != nil {
    panic(err)
  }
  resourceChangesJson, err := json.Marshal(resourceChanges)
  if err != nil {
    panic(err)
  }
  expectedPlan, err := ioutil.ReadFile("./infrastructure/output_changes.json")
  if err != nil {
    panic(err)
  }
  
  diffOpts := jsondiff.DefaultConsoleOptions()
  res, diff := jsondiff.Compare([]byte(resourceChangesJson), []byte(expectedPlan), &diffOpts)

	if res != jsondiff.FullMatch {
		t.Errorf("the expected result is not equal to what we have: %s", diff)
	}
}

func TestEveryControllerHasALoadBalancerTarget(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./infrastructure",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "nodes": map[string]interface{} {
        "node1": map[string]interface{} { "image": "ubuntu-22.04", "location": "fsn1", "server_type": "cx21", "role": "controller" },
        "node2": map[string]interface{} { "image": "ubuntu-22.04", "location": "fsn1", "server_type": "cx21", "role": "controller+worker" },
        "node3": map[string]interface{} { "image": "ubuntu-22.04", "location": "fsn1", "server_type": "cx21", "role": "worker" },
      },
    },
  })
  plan := terraform.InitAndPlanAndShow(t, terraformOptions)

  var planParsed interface{}
  err := json.Unmarshal([]byte(plan), &planParsed)
  if err != nil {
    panic(err)
  }
  nodeBalancerTargets, err := jsonpath.JsonPathLookup(planParsed, "$.resource_changes[?(@.type == 'hcloud_load_balancer_target')]")
  if err != nil {
    panic(err)
  }

  assert.Equal(t, 2, len(nodeBalancerTargets.([]interface{})))
}

func TestOutputNodesHasIp(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./infrastructure",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "nodes": map[string]interface{} {
        "node1": map[string]interface{} { "image": "ubuntu-22.04", "location": "fsn1", "server_type": "cx21", "role": "controller+worker" },
      },
    },
  })
  plan := terraform.InitAndPlanAndShow(t, terraformOptions)

  var planParsed interface{}
  err := json.Unmarshal([]byte(plan), &planParsed)
  if err != nil {
    panic(err)
  }
  ipv4, err := jsonpath.JsonPathLookup(planParsed, "$.output_changes.nodes.after_unknown.node1.ipv4")
  if err != nil {
    panic(err)
  }

  assert.Equal(t, true, ipv4)
}
