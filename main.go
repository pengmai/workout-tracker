package main

import (
	"net/http"
	"os"

	_ "github.com/lib/pq"
	log "github.com/sirupsen/logrus"
)

// Env stores the datastore and other resources shared by goroutines
// in the application.
type Env struct {
	db Datastore
}

func main() {
	c, err := ReadConfig()
	if err != nil {
		log.Fatal(err)
	}

	log.SetOutput(os.Stdout)
	log.SetLevel(c.logLevel)

	db, err := InitializeDB("postgres", c.dbConnectionString)
	if err != nil {
		log.Fatal(err)
	}

	env := &Env{db}
	router := env.NewRouter()

	log.WithField("port", c.port).Info("Server started")
	log.Fatal(http.ListenAndServe(":"+c.port, router))
}
