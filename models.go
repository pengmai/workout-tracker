package main

import (
	"fmt"
	"strconv"
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
	ID   int    `json:"id"`
	Name string `json:"name"`
}

// Workout represents a single workout.
type Workout struct {
	ID    int        `json:"id"`
	User  int        `json:"user,omitempty"`
	Start CustomTime `json:"start"`
	End   CustomTime `json:"end"`
}

// LoginResponse represents all of the information required upon logging in.
type LoginResponse struct {
	User     User      `json:"user"`
	Workouts []Workout `json:"workouts"`
}

type CustomTime struct {
	time.Time
}

func (ct *CustomTime) UnmarshalJSON(b []byte) error {
	seconds, err := strconv.ParseInt(string(b), 10, 64)
	ct.Time = time.Unix(seconds, 0)
	return err
}

func (ct *CustomTime) MarshalJSON() ([]byte, error) {
	return []byte(fmt.Sprintf("%d", ct.Time.Unix())), nil
}
