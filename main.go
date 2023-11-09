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
	fmt.Println("Endpoint Hit: getPayload")
	t := time.Now()
	p := Payload {
		Message: "It Follows is a cinema masterpiece.",
		Timestamp: t.Unix(),
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(p)
}

func handleRequests() {
    http.HandleFunc("/getPayload", timestampedPayload)
    log.Fatal(http.ListenAndServe(":8080", nil))
}

func main() {
    handleRequests()
}