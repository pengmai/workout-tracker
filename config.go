package main

import (
	"errors"
	"fmt"
	"os"
)

// Config represents the configuration information for our app.
type Config struct {
	dbConnectionString string
	port               string
}

// ReadConfig populates a Config struct from environment variables.
func ReadConfig() (Config, error) {
	empty := Config{"", ""}
	username := os.Getenv("DB_USER")
	if username == "" {
		return empty, errors.New("missing environment variable 'DB_USER'")
	}
	password := os.Getenv("DB_PASS")
	if password == "" {
		return empty, errors.New("missing environment variable 'DB_PASS'")
	}
	name := os.Getenv("DB_NAME")
	if name == "" {
		return empty, errors.New("missing environment variable 'DB_NAME'")
	}
	server := os.Getenv("DB_SERVER")
	if server == "" {
		return empty, errors.New("missing environment variable 'DB_SERVER'")
	}
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	return Config{
		fmt.Sprintf(
			"user=%s password=%s dbname=%s host=%s sslmode=verify-full",
			username,
			password,
			name,
			server,
		),
		port,
	}, nil
}
