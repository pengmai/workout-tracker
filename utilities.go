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
			"finished in": time.Since(start),
		}).Info("Finished request")
	}
}

/* Functions to create JSON responses */
func internalServerError(w http.ResponseWriter, err error) {
	respondWithError(w, http.StatusInternalServerError, err,
		"Unable to process request")
}

func respondWithError(w http.ResponseWriter, code int, err error,
	message string) {
	log.WithError(err).Error("An error occurred")
	respondWithJSON(w, code, map[string]string{"error": message})
}

func respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	response, err := json.Marshal(payload)
	if err != nil {
		internalServerError(w, err)
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
