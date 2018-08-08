package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"time"

	"github.com/julienschmidt/httprouter"
	log "github.com/sirupsen/logrus"
)

/* HTTP Middleware */
func (env *Env) loggerMiddleware(name string, handle httprouter.Handle) httprouter.Handle {
	return func(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
		start := time.Now()

		handle(w, r, ps)

		log.WithFields(log.Fields{
			"method":      r.Method,
			"URI":         r.RequestURI,
			"handler":     name,
			"user-agent":  r.Header.Get("User-Agent"),
			"finished in": time.Since(start),
		}).Info("Finished request")
	}
}

/* Functions to create JSON responses */

// InternalServerError is a shorthand to write a 500 internal server error to
// the client.
func InternalServerError(w http.ResponseWriter, err error) {
	WriteError(w, http.StatusInternalServerError, err,
		"Unable to process request")
}

// WriteError is a shorthand to write an error to the client.
func WriteError(w http.ResponseWriter, code int, err error,
	message string) {
	log.WithError(err).Error("An error occurred")
	WriteJSON(w, code, map[string]string{"error": message})
}

// WriteJSON is a shorthand to respond to the client with a payload to be
// serialized to JSON.
func WriteJSON(w http.ResponseWriter, code int, payload interface{}) {
	response, err := json.Marshal(payload)
	if err != nil {
		InternalServerError(w, err)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(code)
	w.Write(response)
}

func computeHmac256(message, secret string) string {
	key := []byte(secret)
	h := hmac.New(sha256.New, key)
	h.Write([]byte(message))
	return base64.StdEncoding.EncodeToString(h.Sum(nil))
}
