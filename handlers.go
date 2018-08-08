package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"

	"github.com/julienschmidt/httprouter"
	log "github.com/sirupsen/logrus"
)

// SignUp handles adding a new user to the database.
func (env *Env) SignUp(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		WriteError(w, http.StatusBadRequest, err, "Invalid request")
		return
	}
	var request UserRequest
	err = json.Unmarshal(body, &request)
	if err != nil || request.Name == "" || request.Password == "" {
		WriteError(
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
		log.WithField("name", request.Name).Info("The given name already exists")
		WriteError(w, http.StatusBadRequest, err, "the given name already exists")
		return
	case err != nil:
		InternalServerError(w, err)
		return
	}

	log.WithField("name", request.Name).Info("Added new user")
	WriteJSON(w, http.StatusCreated, map[string]interface{}{
		"id":    newID,
		"token": request.Token,
	})
}

// Login validates the credentials in the request body and returns the list of workouts
// for the user.
func (env *Env) Login(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		WriteError(w, http.StatusBadRequest, err, "Invalid request")
	}
	var request UserRequest
	err = json.Unmarshal(body, &request)
	if err != nil || ((request.Name == "" || request.Password == "") && request.Token == "") {
		WriteError(
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
			WriteError(w, http.StatusNotFound, err, "The specified user could not be found")
			return
		case err == ErrInvalidCredentials:
			WriteError(w, http.StatusUnauthorized, err, "Invalid credentials")
			return
		case err != nil:
			InternalServerError(w, err)
			return
		}
	} else {
		user, err = env.db.LoginWithToken(request.Token)
		switch {
		case err == ErrUserNotFound:
			WriteError(w, http.StatusNotFound, err, "The given token did not match any users")
			return
		case err != nil:
			InternalServerError(w, err)
			return
		}
	}

	log.WithField("name", user.Name).Info("User signed in")
	workouts, err := env.db.GetWorkouts(user.ID)
	if err != nil {
		InternalServerError(w, err)
		return
	}
	WriteJSON(w, http.StatusOK, LoginResponse{user, workouts})
}

// AddWorkout adds a workout to the datastore.
func (env *Env) AddWorkout(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		WriteError(w, http.StatusBadRequest, err, "Invalid request")
		return
	}
	var workout Workout
	err = json.Unmarshal(body, &workout)
	if err != nil || workout.User == 0 || workout.Start.IsZero() || workout.End.IsZero() {
		WriteError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("invalid request: %s", string(body)),
			"Invalid request",
		)
		return
	}

	if !workout.End.After(workout.Start) {
		WriteError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("end %v is not after start %v", workout.End, workout.Start),
			"End time must be greater than start time",
		)
		return
	}

	workoutID, err := env.db.AddWorkout(workout)
	switch {
	case err == ErrUserNotFound:
		WriteError(w, http.StatusNotFound, err, "The specified user could not be found")
		return
	case err != nil:
		InternalServerError(w, err)
		return
	}

	name, err := env.db.GetUsername(workout.User)
	if err != nil {
		InternalServerError(w, err)
		return
	}
	log.WithField("name", name).Info("Added workout")
	WriteJSON(w, http.StatusCreated, map[string]int{"id": workoutID})
}

// UpdateWorkout replaces the workout specified in the request body.
func (env *Env) UpdateWorkout(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		WriteError(w, http.StatusBadRequest, err, "Invalid request")
		return
	}

	var workout Workout
	err = json.Unmarshal(body, &workout)
	if err != nil ||
		workout.ID == 0 || workout.User == 0 ||
		workout.Start.IsZero() || workout.End.IsZero() {
		WriteError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("invalid request: %s", string(body)),
			"Invalid request",
		)
		return
	}

	if !workout.End.After(workout.Start) {
		WriteError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("end %v is not after start %v", workout.End, workout.Start),
			"End time must be greater than start time",
		)
		return
	}

	err = env.db.UpdateWorkout(workout)
	switch {
	case err == ErrUserNotAuthorized:
		WriteError(
			w,
			http.StatusUnauthorized,
			err,
			"The requested workout does not belong to you",
		)
		return
	case err != nil:
		InternalServerError(w, err)
		return
	}

	name, err := env.db.GetUsername(workout.User)
	log.WithFields(log.Fields{
		"name":    name,
		"workout": workout.ID,
		"start":   workout.Start,
		"end":     workout.End,
	}).Debug("Updated workout")
	log.WithField("name", name).Info("Updated workout")
	w.WriteHeader(http.StatusNoContent)
}

// DeleteWorkout deletes the workout specified in the URL parameter. There is currently no
// validation to ensure that the caller has access to do so.
func (env *Env) DeleteWorkout(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	workoutString := ps.ByName("id")
	workoutID, err := strconv.ParseInt(workoutString, 10, 32)
	if err != nil {
		WriteError(w, http.StatusBadRequest, err, "Invalid workout")
		return
	}
	err = env.db.DeleteWorkout(int(workoutID))
	if err != nil {
		InternalServerError(w, err)
		return
	}
	log.WithField("id", workoutID).Info("Deleted workout")
	w.WriteHeader(http.StatusNoContent)
}

/* Landing page */

// GetIndex serves the static html landing page.
func GetIndex(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	type ApplicationMetadata struct {
		Name string
	}
	metadata := ApplicationMetadata{"Workout Service"}
	t := template.Must(template.New("index.gohtml").ParseFiles("./static/index.gohtml"))
	var b bytes.Buffer
	err := t.Execute(&b, metadata)
	if err != nil {
		InternalServerError(w, err)
		return
	}
	b.WriteTo(w)
}

// GetIcon returns the favicon.ico file.
func GetIcon(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	http.ServeFile(w, r, "./static/favicon.ico")
}

// GetGopher gets the Go gif in the landing page.
func GetGopher(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	http.ServeFile(w, r, "./static/coffee-gopher.gif")
}

// NotFound is a custom not found handler that logs the request data.
func NotFound(w http.ResponseWriter, r *http.Request) {
	log.WithFields(log.Fields{
		"method": r.Method,
		"URI":    r.RequestURI,
	}).Info("Endpoint not found")

	WriteJSON(
		w,
		http.StatusNotFound,
		map[string]string{"error": "endpoint not found"},
	)
}

// MethodNotAllowed is a custom 405 handler that logs the request.
func MethodNotAllowed(w http.ResponseWriter, r *http.Request) {
	log.WithFields(log.Fields{
		"method": r.Method,
		"URI":    r.RequestURI,
	}).Info("Method not allowed")

	WriteJSON(
		w,
		http.StatusMethodNotAllowed,
		map[string]string{"error": "Method not allowed"},
	)
}
