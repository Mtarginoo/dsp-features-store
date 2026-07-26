package main

import (
	"log"
	"net/http"
	"os"
)

const addr = ":8080"

func main() {
	host, err := os.Hostname()
	if err != nil {
		log.Fatalf("resolve hostname: %v", err)
	}

	mux := http.NewServeMux()
	mux.Handle("/", newHelloHandler(host))

	log.Printf("listening on %s as %s", addr, host)
	log.Fatal(http.ListenAndServe(addr, mux))
}
