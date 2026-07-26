package main

import (
	"fmt"
	"net/http"
)

func newHelloHandler(host string) http.HandlerFunc {
	return func(w http.ResponseWriter, _ *http.Request) {
		fmt.Fprintf(w, "hello from %s\n", host)
	}
}
