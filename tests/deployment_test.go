package test

import (
	"testing"
    "context"
	"flag"
	"fmt"
	"path/filepath"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
    "k8s.io/client-go/util/homedir"
	"github.com/stretchr/testify/assert"
	"net/http"
	"encoding/json"
)

type Payload struct {
	Message string
	Timestamp int64
}

func TestDeployment(t *testing.T) {
    var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}
	flag.Parse()

	// use the current context in kubeconfig
	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		panic(err.Error())
	}

	// create the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

    deploymentsClient := clientset.AppsV1().Deployments("xyz")
    deploy, err := deploymentsClient.Get(context.Background(), "xyz-deployment", metav1.GetOptions{})
    if err != nil {
        panic(err)
    }
    fmt.Println("Checking if xyz-deployment is healthy...")
	assert.NotNil(t, deploy)
	assert.NotNil(t, deploy.Spec.Replicas)
	assert.Equal(t, *deploy.Spec.Replicas, deploy.Status.ReadyReplicas)	

	// Test the API via public endpoint
	requestURL := "http://xyz.zyonash.com/payload"
	want := "Automate all the things!"
	res, err := http.Get(requestURL)
	if err != nil {
		fmt.Printf("error making http request: %s\n", err)
		panic(err)
	}
    defer res.Body.Close()
    var j Payload
    json.NewDecoder(res.Body).Decode(&j)
	fmt.Println("Checking if the service is returning a valid payload...")
    assert.Equal(t, j.Message, want)
    assert.NotNil(t, j.Timestamp)

}