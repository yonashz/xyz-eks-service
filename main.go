package main

import (
    "fmt"
    "log"
    "net/http"
	"time"
	"encoding/json"
)

type Payload struct {
	Message string
	Timestamp int64
}

func timestampedPayload(w http.ResponseWriter, r *http.Request){
	t := time.Now()
	p := Payload {
		Message: "It Follows is a cinema masterpiece.",
		Timestamp: t.Unix(),
	}
	jsonData, err := json.Marshal(p)
	if err != nil {
		fmt.Printf("could not marshal json: %s\n", err)
		return
	}
	fmt.Printf("json data: %s\n", jsonData)
}

func handleRequests() {
    http.HandleFunc("/getPayload", timestampedPayload)
    log.Fatal(http.ListenAndServe(":8080", nil))
}

func main() {
    handleRequests()
}