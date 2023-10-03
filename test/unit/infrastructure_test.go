package test

import (
  "encoding/json"
  "io/ioutil"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/nsf/jsondiff"
  "github.com/yalp/jsonpath"
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
  resourceChanges, err := jsonpath.Read(planParsed, "$.output_changes")
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
