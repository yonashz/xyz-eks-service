package main

import (
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
	log.Println("Endpoint Hit: payload")
	t := time.Now()
	p := Payload {
		Message: "Automate all the things!",
		Timestamp: t.Unix(),
	}
	w.Header().Set("Content-Type", "application/json")
	log.Println(p)
	json.NewEncoder(w).Encode(p)
}

func handleRequests() {
    http.HandleFunc("/payload", timestampedPayload)
    log.Fatal(http.ListenAndServe(":8080", nil))
}

func main() {
    handleRequests()
}