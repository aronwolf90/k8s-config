package test

import (
  "encoding/json"
  "io/ioutil"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/nsf/jsondiff"
	"github.com/stretchr/testify/assert"
  "github.com/yalp/jsonpath"
)

func TestK0s(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./k0s",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "k0s_version": "v1.21.14+k0s.0",
      "load_balancer_ipv4": "localhost",
      "private_ssh_key_path": "~/.ssh/id_rsa",
      "nodes": []map[string]string {
        map[string]string{
          "ipv4": "127.0.0.1",
          "role": "controller+worker",
        },
        map[string]string{
          "ipv4": "127.0.0.2",
          "role": "controller+worker",
        },
        map[string]string{
          "ipv4": "127.0.0.3",
          "role": "controller+worker",
        },
      },
    },
  })

  plan := terraform.InitAndPlanAndShow(t, terraformOptions)
  var planParsed interface{}
  err := json.Unmarshal([]byte(plan), &planParsed)
  if err != nil {
    panic(err)
  }
  resourceChanges, err := jsonpath.Read(planParsed, "$.resource_changes[0]")
  if err != nil {
    panic(err)
  }
  resourceChangesJson, err := json.Marshal(resourceChanges)
  if err != nil {
    panic(err)
  }
  expectedPlan, err := ioutil.ReadFile("./k0s/expectedPlan.json")
  if err != nil {
    panic(err)
  }
  
  diffOpts := jsondiff.DefaultConsoleOptions()
  res, diff := jsondiff.Compare([]byte(resourceChangesJson), []byte(expectedPlan), &diffOpts)

	if res != jsondiff.FullMatch {
		t.Errorf("the expected result is not equal to what we have: %s", diff)
	}
}

func TestK0sV1_21_14_k0s_0(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "./k0s",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "k0s_version": "v1.21.14+k0s.0",
      "load_balancer_ipv4": "localhost",
      "private_ssh_key_path": "~/.ssh/id_rsa",
      "nodes": []map[string]string {
        map[string]string{
          "ipv4": "127.0.0.1",
          "role": "controller+worker",
        },
        map[string]string{
          "ipv4": "127.0.0.2",
          "role": "controller+worker",
        },
        map[string]string{
          "ipv4": "127.0.0.3",
          "role": "controller+worker",
        },
      },
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
    TerraformDir: "./k0s",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "k0s_version": "v1.22.17+k0s.0",
      "load_balancer_ipv4": "localhost",
      "private_ssh_key_path": "~/.ssh/id_rsa",
      "nodes": []map[string]string {
        map[string]string{
          "ipv4": "127.0.0.1",
          "role": "controller+worker",
        },
        map[string]string{
          "ipv4": "127.0.0.2",
          "role": "controller+worker",
        },
        map[string]string{
          "ipv4": "127.0.0.3",
          "role": "controller+worker",
        },
      },
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
    TerraformDir: "./k0s",
    PlanFilePath: "./.tmp", 
    Vars: map[string]interface{} {
      "k0s_version": "v1.23.17+k0s.0",
      "load_balancer_ipv4": "localhost",
      "private_ssh_key_path": "~/.ssh/id_rsa",
      "nodes": []map[string]string {
        map[string]string{
          "ipv4": "127.0.0.1",
          "role": "controller+worker",
        },
        map[string]string{
          "ipv4": "127.0.0.2",
          "role": "controller+worker",
        },
        map[string]string{
          "ipv4": "127.0.0.3",
          "role": "controller+worker",
        },
      },
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
