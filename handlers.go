package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/julienschmidt/httprouter"
)

// SignUp handles adding a new user to the database.
func (env *Env) SignUp(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		env.respondWithError(w, http.StatusBadRequest, err, "Invalid request")
		return
	}
	var request UserRequest
	err = json.Unmarshal(body, &request)
	if err != nil || request.Name == "" || request.Password == "" {
		env.respondWithError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("invalid request: %s", string(body)),
			"Invalid request",
		)
		return
	}

	request.Name = strings.Title(strings.ToLower(request.Name))
	request.Token = computeHmac256(request.Password, request.Name)
	newID, err := env.db.SignUp(request)
	switch {
	case err == ErrUserAlreadyExists:
		env.logger.Printf("name: %s", request.Name)
		env.respondWithError(w, http.StatusBadRequest, err, "the given name already exists")
		return
	case err != nil:
		env.internalServerError(w, err)
		return
	}

	env.logger.Printf("Added new user: %s", request.Name)
	env.respondWithJSON(w, http.StatusCreated, map[string]interface{}{
		"id":    newID,
		"token": request.Token,
	})
}

func (env *Env) Login(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		env.respondWithError(w, http.StatusBadRequest, err, "Invalid request")
	}
	var request UserRequest
	err = json.Unmarshal(body, &request)
	if err != nil || ((request.Name == "" || request.Password == "") && request.Token == "") {
		env.respondWithError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("invalid request: %s", string(body)),
			"Invalid request",
		)
		return
	}

	var user User
	if request.Name != "" && request.Password != "" {
		request.Name = strings.Title(strings.ToLower(request.Name))
		request.Token = computeHmac256(request.Password, request.Name)

		user, err = env.db.LoginWithCredentials(request.Name, request.Token)
		switch {
		case err == ErrUserNotFound:
			env.respondWithError(w, http.StatusNotFound, err, "The specified user could not be found")
			return
		case err == ErrInvalidCredentials:
			env.respondWithError(w, http.StatusUnauthorized, err, "Invalid credentials")
			return
		case err != nil:
			env.internalServerError(w, err)
			return
		}
	} else {
		user, err = env.db.LoginWithToken(request.Token)
		switch {
		case err == ErrUserNotFound:
			env.respondWithError(w, http.StatusNotFound, err, "The given token did not match any users")
			return
		case err != nil:
			env.internalServerError(w, err)
			return
		}
	}

	env.logger.Printf("%s logged in", user.Name)
	workouts, err := env.db.GetWorkouts(user.ID)
	if err != nil {
		env.internalServerError(w, err)
		return
	}
	env.respondWithJSON(w, http.StatusOK, LoginResponse{user, workouts})
}

func (env *Env) AddWorkout(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		env.respondWithError(w, http.StatusBadRequest, err, "Invalid request")
		return
	}
	var workout Workout
	err = json.Unmarshal(body, &workout)
	if err != nil || workout.User == 0 || workout.Start.IsZero() || workout.End.IsZero() {
		env.respondWithError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("invalid request: %s", string(body)),
			"Invalid request",
		)
		return
	}

	if !workout.End.After(workout.Start.Time) {
		env.respondWithError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("end %v is not after start %v", workout.End, workout.Start),
			"End time must be greater than start time",
		)
		return
	}

	err = env.db.AddWorkout(workout)
	switch {
	case err == ErrUserNotFound:
		env.respondWithError(w, http.StatusNotFound, err, "The specified user could not be found")
		return
	case err != nil:
		env.internalServerError(w, err)
		return
	}
	w.WriteHeader(http.StatusCreated)
}
