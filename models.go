package main

import (
	"time"
)

// UserRequest represents the expected request object received when a user logs
// in or signs up.
type UserRequest struct {
	Name     string `json:"name"`
	Password string `json:"password"`
	Token    string `json:"token"`
}

// User represents a single user.
type User struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Token string `json:"token,omitempty"`
}

// Workout represents a single workout.
type Workout struct {
	ID    int       `json:"id"`
	User  int       `json:"user,omitempty"`
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
}

// LoginResponse represents all of the information required upon logging in.
type LoginResponse struct {
	User     User      `json:"user"`
	Workouts []Workout `json:"workouts"`
}
