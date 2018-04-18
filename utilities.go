package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"time"

	"github.com/julienschmidt/httprouter"
)

/* HTTP Middleware */
func (env *Env) loggerMiddleware(name string, handle httprouter.Handle) httprouter.Handle {
	return func(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
		start := time.Now()

		handle(w, r, ps)

		env.logger.Printf(
			"%s\t%s\t%s\t%s",
			r.Method,
			r.RequestURI,
			name,
			time.Since(start),
		)
	}
}

/* Functions to create JSON responses */
func (env *Env) internalServerError(w http.ResponseWriter, err error) {
	env.respondWithError(w, http.StatusInternalServerError, err,
		"Unable to process request")
}

func (env *Env) respondWithError(w http.ResponseWriter, code int, err error,
	message string) {
	env.logger.Println(err)
	env.respondWithJSON(w, code, map[string]string{"error": message})
}

func (env *Env) respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	response, err := json.Marshal(payload)
	if err != nil {
		env.internalServerError(w, err)
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
