package test

import (
  "context"
  "fmt"
  "regexp"
	"testing"
  "time"

  "k8s.io/client-go/kubernetes"
  "k8s.io/client-go/rest"

  apiv1 "k8s.io/api/core/v1"
  appsv1 "k8s.io/api/apps/v1"
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
  "github.com/hetznercloud/hcloud-go/hcloud"
)

func CreateDeployment(clientset *kubernetes.Clientset) {
  deploymentsClient := clientset.AppsV1().Deployments(apiv1.NamespaceDefault)
	deployment := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
      Name: "demo-deployment",
	  },
    Spec: appsv1.DeploymentSpec{
      Selector: &metav1.LabelSelector{
        MatchLabels: map[string]string{
          "app": "demo",
        },
      },
      Template: apiv1.PodTemplateSpec{
        ObjectMeta: metav1.ObjectMeta{
          Labels: map[string]string{
            "app": "demo",
          },
        },
        Spec: apiv1.PodSpec{
          Containers: []apiv1.Container{
            {
              Name:  "web",
              Image: "nginx",
              Ports: []apiv1.ContainerPort{
                {
                  Name:          "http",
                  Protocol:      apiv1.ProtocolTCP,
                  ContainerPort: 80,
                },
              },
            },
          },
        },
      },
    },
  }
	fmt.Println("Creating deployment...")
	result, err := deploymentsClient.Create(context.TODO(), deployment, metav1.CreateOptions{})
	if err != nil {
		panic(err)
	}
	fmt.Printf("Created deployment %q.\n", result.GetObjectMeta().GetName())
}

func CheckDeployment(clientset *kubernetes.Clientset) {
  pods, err := clientset.CoreV1().Pods("default").List(context.TODO(), metav1.ListOptions{})
  if err != nil {
	  panic(err.Error())
  }
  fmt.Printf("There are %d pods in the cluster\n", len(pods.Items))
  count := 0
  for {
    pods, err = clientset.CoreV1().Pods("default").List(context.TODO(), metav1.ListOptions{})
    if err != nil {
      panic(err)
    }

    if pods.Items[0].Status.Phase == apiv1.PodPhase("Running")  {
      break
    }

    if count > 360 {
       panic("Could not create a working pod")
    }
    count += 1
    time.Sleep(time.Second)
  }
}

func CheckNodes(clientset *kubernetes.Clientset) {
  count := 0
  for {
    nodes, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
    if err != nil {
      panic(err.Error())
    }
    fmt.Printf("There are %d nodes in the cluster\n", len(nodes.Items))
    count += 1

    if len(nodes.Items) > 1 {
      break
    }

    if count > 420 {
       panic("No worker node created")
    }
	  time.Sleep(time.Second)
  }
}

func ScaleMasterNodesUp(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{} {
		  "master_nodes": []map[string]string{
			  {"name": "master", "image": "ubuntu-20.04" },
			  {"name": "master2", "image": "ubuntu-20.04" },
			},
		},
	})
	terraform.Apply(t, terraformOptions)
	// TODO: Find a way to check every second if the master is in sycron instead of this.
	time.Sleep(time.Second * 120)
}

func RemoveMasterNode(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{} {
		  "master_nodes": []map[string]string{
			  {"name": "master2", "image": "ubuntu-20.04" },
			},
		},
	})
	terraform.Apply(t, terraformOptions)
}

func CreateClientset(host string, token string) *kubernetes.Clientset {
  config := &rest.Config{
    BearerToken: token,
    Host: host,
    TLSClientConfig: rest.TLSClientConfig{
      Insecure: true,
    },
  }
  clientset, err := kubernetes.NewForConfig(config)
  if err != nil {
    panic(err.Error())
  }
  return clientset
}

func ChangeWorkerNodeType(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: map[string]interface{} {
		  "worker_node_type": "CPX11",
		},
	})
	terraform.Apply(t, terraformOptions)
}

func GetWorkerNodeType(hcloudToken string) string {
  client := hcloud.NewClient(hcloud.WithToken(hcloudToken))

  servers, err := client.Server.All(context.Background())
	var server *hcloud.Server
  if err != nil {
		panic(err)
  }
  if servers != nil {
    regex := regexp.MustCompile("pool.+")
    for _, localServer := range servers {
		  if regex.MatchString(localServer.Name) {
			  server = localServer
			}
		}
    if server == nil {
      return ""
    } else {
      return server.ServerType.Name
    }
  } else {
		panic("Server not found")
  }
}

func TestTerraform(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: ".",
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

  outputToken := terraform.Output(t, terraformOptions, "token")
  assert.Regexp(t, regexp.MustCompile(`.+`), outputToken)

  outputHost := terraform.Output(t, terraformOptions, "host")
  assert.Regexp(t, regexp.MustCompile(`.+`), outputHost)

  outputMasterNodes := terraform.OutputMapOfObjects(t, terraformOptions, "master_nodes")
  assert.Regexp(t, regexp.MustCompile(`.+`), outputMasterNodes["master"].(map[string]interface {})["ipv4_address"])

  outputHcloudToken := terraform.Output(t, terraformOptions, "hcloud_token")
  assert.Regexp(t, regexp.MustCompile(`.+`), outputHcloudToken)

  clientset := CreateClientset(outputHost, outputToken)
  CheckNodes(clientset)
  CreateDeployment(clientset)
  CheckDeployment(clientset)
  ScaleMasterNodesUp(t)
  RemoveMasterNode(t)
  CheckDeployment(clientset)
  time.Sleep(time.Second * 10)
  assert.Equal(t, GetWorkerNodeType(outputHcloudToken), "cx21")
  ChangeWorkerNodeType(t)
  clientset   = CreateClientset(
    terraform.Output(t, terraformOptions, "host"),
    terraform.Output(t, terraformOptions, "token"),
  )
  CheckNodes(clientset)
  assert.Equal(t, GetWorkerNodeType(outputHcloudToken), "cpx11")
}

func TestTerraformWithMultipleInitialMasters(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: ".",
    Vars: map[string]interface{} {
      "master_nodes": []map[string]string{
        {"name": "master", "image": "ubuntu-20.04" },
        {"name": "master2", "image": "ubuntu-20.04" },
      },
    },
  })

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

	outputHost := terraform.Output(t, terraformOptions, "host")
	outputToken := terraform.Output(t, terraformOptions, "token")
  clientset := CreateClientset(outputHost, outputToken)
  CheckNodes(clientset)
	CreateDeployment(clientset)
}
