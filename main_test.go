package main

import (
	"testing"
    "net/http"
    "net/http/httptest"
    "encoding/json"
    "github.com/stretchr/testify/assert"
)

func TestPayload(t *testing.T){

    want := "Automate all the things!"
    req := httptest.NewRequest(http.MethodGet, "/payload", nil)
    w := httptest.NewRecorder()
    timestampedPayload(w, req)
    res := w.Result()
    defer res.Body.Close()
    var j Payload
    err := json.NewDecoder(res.Body).Decode(&j)
    if err != nil {
        panic(err)
    }
    assert.Equal(t, j.Message, want)
    assert.NotNil(t, j.Timestamp)
}