package test

import (
  "context"
  "encoding/json"
  "fmt"
  "net/http"
  "os"
  "regexp"
	"testing"
  "time"

  "k8s.io/apimachinery/pkg/api/meta"
  "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
  "k8s.io/apimachinery/pkg/runtime/serializer/yaml"
  "k8s.io/apimachinery/pkg/types"
  "k8s.io/client-go/discovery"
  "k8s.io/client-go/discovery/cached/memory"
  "k8s.io/client-go/dynamic"
  "k8s.io/client-go/kubernetes"
  "k8s.io/client-go/rest"
  "k8s.io/client-go/restmapper"

  apiv1 "k8s.io/api/core/v1"
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func CreateConfig(host string, clusterCaCertificate string, clientCertificate string, clientKey string) *rest.Config {
  return &rest.Config{
    Host: host,
    TLSClientConfig: rest.TLSClientConfig{
      CAData: []byte(clusterCaCertificate),
      CertData: []byte(clientCertificate),
      KeyData: []byte(clientKey),
    },
  }
}

func applyYAML(cfg *rest.Config, deploymentYAML string) {
  ctx := context.TODO()

  decUnstructured := yaml.NewDecodingSerializer(unstructured.UnstructuredJSONScheme)

  // 1. Prepare a RESTMapper to find GVR
  dc, err := discovery.NewDiscoveryClientForConfig(cfg)
  if err != nil {
    panic(err.Error())
  }
  mapper := restmapper.NewDeferredDiscoveryRESTMapper(memory.NewMemCacheClient(dc))

  // 2. Prepare the dynamic client
  dyn, err := dynamic.NewForConfig(cfg)
  if err != nil {
    panic(err.Error())
  }

  // 3. Decode YAML manifest into unstructured.Unstructured
  obj := &unstructured.Unstructured{}
  _, gvk, err := decUnstructured.Decode([]byte(deploymentYAML), nil, obj)
  if err != nil {
    panic(err.Error())
  }

  // 4. Find GVR
  mapping, err := mapper.RESTMapping(gvk.GroupKind(), gvk.Version)
  if err != nil {
    panic(err.Error())
  }

  // 5. Obtain REST interface for the GVR
  var dr dynamic.ResourceInterface
  if mapping.Scope.Name() == meta.RESTScopeNameNamespace {
      // namespaced resources should specify the namespace
      dr = dyn.Resource(mapping.Resource).Namespace(obj.GetNamespace())
  } else {
      // for cluster-wide resources
      dr = dyn.Resource(mapping.Resource)
  }

  // 6. Marshal object into JSON
  data, err := json.Marshal(obj)
  if err != nil {
    panic(err.Error())
  }

  // 7. Create or Update the object with SSA
  //     types.ApplyPatchType indicates SSA.
  //     FieldManager specifies the field owner ID.
  _, err = dr.Patch(ctx, obj.GetName(), types.ApplyPatchType, data, metav1.PatchOptions{
      FieldManager: "sample-controller",
  })

  if err != nil {
    panic(err.Error())
  }
}

func CreateDeployment(config *rest.Config) {
  const statefulSetYAML = `
  apiVersion: apps/v1
  kind: StatefulSet
  metadata:
    name: nginx
    namespace: default
  spec:
    serviceName: "nginx"
    replicas: 1
    selector:
      matchLabels:
        app: nginx
    template:
      metadata:
        labels:
          app: nginx
      spec:
        initContainers:
        - name: init
          image: registry.k8s.io/nginx-slim:0.8
          command: [ "sh", "-c", "echo {} > /usr/share/nginx/html/ok.json" ]
          ports:
          - containerPort: 80
            name: web
          volumeMounts:
          - name: www
            mountPath: /usr/share/nginx/html
        containers:
        - name: nginx
          image: registry.k8s.io/nginx-slim:0.8
          ports:
          - containerPort: 80
            name: web
          volumeMounts:
          - name: www
            mountPath: /usr/share/nginx/html
    volumeClaimTemplates:
    - metadata:
        name: www
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 1Gi
  `
  applyYAML(config, statefulSetYAML)
}

func CreateLoadBalancer(config *rest.Config) {
  const loadBalancerYAML = `
  apiVersion: v1
  kind: Service
  metadata:
    name: nginx
    namespace: default
  spec:
    selector:
      app: nginx
    ports:
      - protocol: TCP
        port: 80
        targetPort: 80
    type: LoadBalancer
  `
  applyYAML(config, loadBalancerYAML)
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

    if len(pods.Items) >= 1 && pods.Items[0].Status.Phase == apiv1.PodPhase("Running")  {
      break
    }

    if count > 180 {
      panic("Could not create a working pod")
    }
    count += 1
    time.Sleep(time.Second)
  }
}

func CheckServices(clientset *kubernetes.Clientset) {
  services, err := clientset.CoreV1().Services("default").List(context.TODO(), metav1.ListOptions{})
  if err != nil {
	  panic(err.Error())
  }
  fmt.Printf("There are %d services in the cluster\n", len(services.Items))
  count := 0
  for {
    services, err = clientset.CoreV1().Services("default").List(context.TODO(), metav1.ListOptions{})
    if err != nil {
      panic(err)
    }

    if len(services.Items[1].Status.LoadBalancer.Ingress) > 0  {
      break
    }

    if count > 60 {
       panic("Could not create a working service")
    }
    count += 1
    time.Sleep(time.Second)
  }

  client := http.Client{
    Timeout: 5 * time.Second,
  }

  count = 0
  for {
    url := "http://" + services.Items[1].Status.LoadBalancer.Ingress[0].IP + "/ok.json"
    fmt.Printf("Try access %s\n", url)
    _, err = client.Get(url)
    if err != nil {
      count += 1
      time.Sleep(time.Second)
    } else {
      break
    }
    if count > 60 {
       panic("Could not use load balancer")
    }
  }
}

func checkNodes(clientset *kubernetes.Clientset, minCount int) {
  count := 0
  for {
    nodes := getNodes(clientset)
    fmt.Printf("There are %d nodes in the cluster\n", len(nodes.Items))
    count += 1

    if len(nodes.Items) >= minCount {
      break
    }

    if count > 420 {
       panic("Not enough nodes created")
    }
	  time.Sleep(time.Second)
  }
}

func getNodes(clientset *kubernetes.Clientset) *apiv1.NodeList {
  nodes, _ := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
  return nodes
}

func RemoveMasterNode(t *testing.T) map[string]interface{} {
  variables := map[string]interface{} {
	  "nodes": map[string]interface{} {
      "controller1": map[string]interface{} {
        "image": "ubuntu-22.04", "location": "fsn1", "server_type": "cx21", "role": "controller+worker",
      },
		},
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Vars: variables,
	})
	terraform.Apply(t, terraformOptions)

  return variables
}

func CreateClientset(host string, clusterCaCertificate string, clientCertificate string, clientKey string) *kubernetes.Clientset {
  config := CreateConfig(host, clusterCaCertificate, clientCertificate, clientKey)
  clientset, err := kubernetes.NewForConfig(config)
  if err != nil {
    panic(err.Error())
  }
  return clientset
}

func deletePersistentVolumeClaims(clientset *kubernetes.Clientset) {
  persistentVolumeClaims, err := clientset.CoreV1().PersistentVolumeClaims("default").List(context.TODO(), metav1.ListOptions{})
  if err != nil {
	  panic(err.Error())
  }

  for _, persistentVolumeClaim := range persistentVolumeClaims.Items {
    clientset.CoreV1().PersistentVolumeClaims("default").Delete(context.TODO(), persistentVolumeClaim.Name, metav1.DeleteOptions{})
  }

  count := 0
  for {
    persistentVolumeClaims, err := clientset.CoreV1().PersistentVolumeClaims("default").List(context.TODO(), metav1.ListOptions{})
    if err != nil {
      panic(err)
    }

    if len(persistentVolumeClaims.Items) == 0  {
      break
    }

    if count > 120 {
       panic("Could not delete persistent volume Claims")
    }
    count += 1
    time.Sleep(time.Second)
  }
}

func deleteVolumes(clientset *kubernetes.Clientset) {
  persistentVolumes, err := clientset.CoreV1().PersistentVolumes().List(context.TODO(), metav1.ListOptions{})
  if err != nil {
	  panic(err.Error())
  }

  for _, persistentVolume := range persistentVolumes.Items {
    clientset.CoreV1().PersistentVolumes().Delete(context.TODO(), persistentVolume.Name, metav1.DeleteOptions{})
  }

  count := 0
  for {
    persistentVolumes, err = clientset.CoreV1().PersistentVolumes().List(context.TODO(), metav1.ListOptions{})
    if err != nil {
      panic(err)
    }

    if len(persistentVolumes.Items) == 0  {
      break
    }

    if count > 60 {
       panic("Could not delete persistent volumes")
    }
    count += 1
    time.Sleep(time.Second)
  }
}

func deleteStatefulSet(clientset *kubernetes.Clientset) {
  statefulSets, err := clientset.AppsV1().StatefulSets("default").List(context.TODO(), metav1.ListOptions{})
  if err != nil {
	  panic(err.Error())
  }

  for _, statefulSets := range statefulSets.Items {
    err := clientset.AppsV1().StatefulSets("default").Delete(context.TODO(), statefulSets.Name, metav1.DeleteOptions{})
    if err != nil {
      panic(err.Error())
    }
  }
  count := 0
  for {
    statefulSets, err := clientset.AppsV1().StatefulSets("default").List(context.TODO(), metav1.ListOptions{})
    if err != nil {
      panic(err)
    }

    if len(statefulSets.Items) == 0  {
      break
    }

    if count > 120 {
       panic("Could not delete statefull sets")
    }
    count += 1
    time.Sleep(time.Second)
  }
}

func deleteServices(clientset *kubernetes.Clientset) {
  services, err := clientset.CoreV1().Services("default").List(context.TODO(), metav1.ListOptions{})
  if err != nil {
	  panic(err.Error())
  }

  for _, service := range services.Items {
    if service.Name == "kubernetes" {
      continue
    } 

    err := clientset.CoreV1().Services("default").Delete(context.TODO(), service.Name, metav1.DeleteOptions{})
    if err != nil {
      panic(err.Error())
    }
  }

  count := 0
  for {
    services, err = clientset.CoreV1().Services("default").List(context.TODO(), metav1.ListOptions{})
    if err != nil {
      panic(err)
    }

    if len(services.Items) <= 1  {
      break
    }

    if count > 120 {
       panic("Could not delete services")
    }
    count += 1
    time.Sleep(time.Second)
  }
}

func deleteK8sResources(t *testing.T, clientset *kubernetes.Clientset, terraformOptions *terraform.Options) {
  deleteStatefulSet(clientset)
  deletePersistentVolumeClaims(clientset)
  deleteServices(clientset)

  time.Sleep(time.Second * 20)
  terraform.Destroy(t, terraformOptions)
}

func TestTerraform(t *testing.T) {
  if os.Getenv("TEST_K8S_VERSIONS") != "" {
    t.Skip("Skipping TestTerraform test")
    return
  }

  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: ".",
  })

  t.Setenv("SSH_KNOWN_HOSTS", "/dev/null")

  terraform.InitAndApply(t, terraformOptions)

  outputHost := terraform.Output(t, terraformOptions, "host")
  assert.Regexp(t, regexp.MustCompile(`.+`), outputHost)

  clusterCaCertificate := terraform.Output(t, terraformOptions, "cluster_ca_certificate")
  assert.Regexp(t,  regexp.MustCompile(`.+`), clusterCaCertificate)

  clientCertificate := terraform.Output(t, terraformOptions, "client_certificate")
  assert.Regexp(t,  regexp.MustCompile(`.+`), clientCertificate)

  clientKey := terraform.Output(t, terraformOptions, "client_key")
  assert.Regexp(t,  regexp.MustCompile(`.+`), clientKey)

  outputHcloudToken := terraform.Output(t, terraformOptions, "hcloud_token")
  assert.Regexp(t, regexp.MustCompile(`.+`), outputHcloudToken)

  config := CreateConfig(outputHost, clusterCaCertificate, clientCertificate, clientKey)
  clientset := CreateClientset(outputHost, clusterCaCertificate, clientCertificate, clientKey)
  defer deleteK8sResources(t, clientset, terraformOptions)

  checkNodes(clientset, 3)
  CreateDeployment(config)
  CheckDeployment(clientset)
  CreateLoadBalancer(config)
  CheckServices(clientset)

  RemoveMasterNode(t)
  checkNodes(clientset, 1)
  CheckDeployment(clientset)
  CheckServices(clientset)

  terraform.InitAndApply(t, terraformOptions)
  checkNodes(clientset, 3)
  CheckDeployment(clientset)
  CheckServices(clientset)
}

func testK8sVersion(t *testing.T, k0sVersion string) {
  if os.Getenv("TEST_K8S_VERSIONS") == "" {
    t.Skip("Skipping k0s version test")
    return
  }

  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: ".",
    Vars: map[string]interface{} {
      "k0s_version": k0sVersion,
    },
  })

  t.Setenv("SSH_KNOWN_HOSTS", "/dev/null")

  terraform.InitAndApply(t, terraformOptions)

  outputHost := terraform.Output(t, terraformOptions, "host")
  assert.Regexp(t, regexp.MustCompile(`.+`), outputHost)

  clusterCaCertificate := terraform.Output(t, terraformOptions, "cluster_ca_certificate")
  assert.Regexp(t,  regexp.MustCompile(`.+`), clusterCaCertificate)

  clientCertificate := terraform.Output(t, terraformOptions, "client_certificate")
  assert.Regexp(t,  regexp.MustCompile(`.+`), clientCertificate)

  clientKey := terraform.Output(t, terraformOptions, "client_key")
  assert.Regexp(t,  regexp.MustCompile(`.+`), clientKey)

  outputHcloudToken := terraform.Output(t, terraformOptions, "hcloud_token")
  assert.Regexp(t, regexp.MustCompile(`.+`), outputHcloudToken)

  config := CreateConfig(outputHost, clusterCaCertificate, clientCertificate, clientKey)
  clientset := CreateClientset(outputHost, clusterCaCertificate, clientCertificate, clientKey)
  defer deleteK8sResources(t, clientset, terraformOptions)

  checkNodes(clientset, 3)
  CreateDeployment(config)
  CheckDeployment(clientset)
  CreateLoadBalancer(config)
  CheckServices(clientset)
}

func TestV_1_21_14(t *testing.T) {
  testK8sVersion(t, "v1.21.14+k0s.0")
}

func TestV_1_22_17(t *testing.T) {
  testK8sVersion(t, "v1.22.17+k0s.0")
}

func TestV_1_23_17(t *testing.T) {
  testK8sVersion(t, "v1.23.17+k0s.1")
}

func TestV_1_24_17(t *testing.T) {
  testK8sVersion(t, "v1.24.17+k0s.0")
}

func TestV_1_25_14(t *testing.T) {
  testK8sVersion(t, "v1.25.14+k0s.0")
}

func TestV_1_26_9(t *testing.T) {
  testK8sVersion(t, "v1.26.9+k0s.0")
}

func TestV_1_27_6(t *testing.T) {
  testK8sVersion(t, "v1.27.6+k0s.0")
}

func TestV_1_28_2(t *testing.T) {
  testK8sVersion(t, "v1.28.2+k0s.0")
}
