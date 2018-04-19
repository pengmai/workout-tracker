package main

import (
	"errors"
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

	connectionString := os.Getenv("DATABASE_URL")
	if connectionString == "" {
		return empty, errors.New("missing environment variable 'DATABASE_URL'")
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
		connectionString,
		port,
		logLevel,
	}, nil
}
