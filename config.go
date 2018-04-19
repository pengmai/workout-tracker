package main

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/sirupsen/logrus"
)

// Config represents the configuration information for our app.
type Config struct {
	dbConnectionString string
	port               string
	logLevel           logrus.Level
}

// ReadConfig populates a Config struct from environment variables.
func ReadConfig() (Config, error) {
	empty := Config{}
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

	var logLevel logrus.Level
	switch strings.ToUpper(os.Getenv("LOG_LEVEL")) {
	case "":
		fallthrough
	case "DEBUG":
		logLevel = logrus.DebugLevel
	case "INFO":
		logLevel = logrus.InfoLevel
	case "WARN":
		logLevel = logrus.WarnLevel
	case "ERROR":
		logLevel = logrus.ErrorLevel
	case "FATAL":
		logLevel = logrus.FatalLevel
	case "PANIC":
		logLevel = logrus.PanicLevel
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
		logLevel,
	}, nil
}
