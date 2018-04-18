package main

import (
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq"
)

// Env stores the datastore, logger, and other resources shared by goroutines
// in the application.
type Env struct {
	db     Datastore
	logger *log.Logger
}

func main() {
	logger := log.New(os.Stdout, "workit-api: ", log.LstdFlags)
	c, err := ReadConfig()
	if err != nil {
		logger.Fatal(err)
	}
	db, err := InitializeDB("postgres", c.dbConnectionString)
	if err != nil {
		logger.Fatal(err)
	}

	env := &Env{db, logger}
	router := env.NewRouter()

	logger.Printf("Server listening on port %s", c.port)
	logger.Fatal(http.ListenAndServe(":"+c.port, router))
}
