package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHelloHandlerIncludesHostname(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()

	newHelloHandler("test-host")(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusOK)
	}

	const want = "hello from test-host\n"
	if got := rec.Body.String(); got != want {
		t.Errorf("body = %q, want %q", got, want)
	}
}
