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
		respondWithError(w, http.StatusBadRequest, err, "Invalid request")
		return
	}
	var request UserRequest
	err = json.Unmarshal(body, &request)
	if err != nil || request.Name == "" || request.Password == "" {
		respondWithError(
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
		respondWithError(w, http.StatusBadRequest, err, "the given name already exists")
		return
	case err != nil:
		internalServerError(w, err)
		return
	}

	log.WithField("name", request.Name).Info("Added new user")
	respondWithJSON(w, http.StatusCreated, map[string]interface{}{
		"id":    newID,
		"token": request.Token,
	})
}

func (env *Env) Login(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		respondWithError(w, http.StatusBadRequest, err, "Invalid request")
	}
	var request UserRequest
	err = json.Unmarshal(body, &request)
	if err != nil || ((request.Name == "" || request.Password == "") && request.Token == "") {
		respondWithError(
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
			respondWithError(w, http.StatusNotFound, err, "The specified user could not be found")
			return
		case err == ErrInvalidCredentials:
			respondWithError(w, http.StatusUnauthorized, err, "Invalid credentials")
			return
		case err != nil:
			internalServerError(w, err)
			return
		}
	} else {
		user, err = env.db.LoginWithToken(request.Token)
		switch {
		case err == ErrUserNotFound:
			respondWithError(w, http.StatusNotFound, err, "The given token did not match any users")
			return
		case err != nil:
			internalServerError(w, err)
			return
		}
	}

	log.WithField("name", user.Name).Info("User signed in")
	workouts, err := env.db.GetWorkouts(user.ID)
	if err != nil {
		internalServerError(w, err)
		return
	}
	respondWithJSON(w, http.StatusOK, LoginResponse{user, workouts})
}

func (env *Env) AddWorkout(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		respondWithError(w, http.StatusBadRequest, err, "Invalid request")
		return
	}
	var workout Workout
	err = json.Unmarshal(body, &workout)
	if err != nil || workout.User == 0 || workout.Start.IsZero() || workout.End.IsZero() {
		respondWithError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("invalid request: %s", string(body)),
			"Invalid request",
		)
		return
	}

	if !workout.End.After(workout.Start.Time) {
		respondWithError(
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
		respondWithError(w, http.StatusNotFound, err, "The specified user could not be found")
		return
	case err != nil:
		internalServerError(w, err)
		return
	}

	name, err := env.db.GetUsername(workout.User)
	if err != nil {
		internalServerError(w, err)
		return
	}
	log.WithField("name", name).Info("Added workout")
	w.WriteHeader(http.StatusCreated)
}

func (env *Env) UpdateWorkout(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		respondWithError(w, http.StatusBadRequest, err, "Invalid request")
		return
	}

	var workout Workout
	err = json.Unmarshal(body, &workout)
	if err != nil ||
		workout.ID == 0 || workout.User == 0 ||
		workout.Start.IsZero() || workout.End.IsZero() {
		respondWithError(
			w,
			http.StatusBadRequest,
			fmt.Errorf("invalid request: %s", string(body)),
			"Invalid request",
		)
		return
	}

	if !workout.End.After(workout.Start.Time) {
		respondWithError(
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
		respondWithError(
			w,
			http.StatusUnauthorized,
			err,
			"The requested workout does not belong to you",
		)
		return
	case err != nil:
		internalServerError(w, err)
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

func (env *Env) DeleteWorkout(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	workoutString := ps.ByName("id")
	workoutID, err := strconv.ParseInt(workoutString, 10, 32)
	if err != nil {
		respondWithError(w, http.StatusBadRequest, err, "Invalid workout")
		return
	}
	err = env.db.DeleteWorkout(int(workoutID))
	if err != nil {
		internalServerError(w, err)
		return
	}
	log.WithField("id", workoutID).Info("Deleted workout")
	w.WriteHeader(http.StatusNoContent)
}

/* Serve static files */
func GetIndex(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	type ApplicationMetadata struct {
		Name string
	}
	metadata := ApplicationMetadata{"Workout Service"}
	t := template.Must(template.New("index.gohtml").ParseFiles("./static/index.gohtml"))
	var b bytes.Buffer
	err := t.Execute(&b, metadata)
	if err != nil {
		internalServerError(w, err)
		return
	}
	b.WriteTo(w)
}

func GetIcon(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	http.ServeFile(w, r, "./static/favicon.ico")
}

func GetStyles(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	http.ServeFile(w, r, "./static/main.css")
}

func GetGopher(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	http.ServeFile(w, r, "./static/coffee-gopher.gif")
}

func NotFound(w http.ResponseWriter, r *http.Request) {
	log.WithFields(log.Fields{
		"method": r.Method,
		"URI":    r.RequestURI,
	}).Info("Endpoint not found")

	respondWithJSON(
		w,
		http.StatusNotFound,
		map[string]string{"error": "endpoint not found"},
	)
}

func MethodNotAllowed(w http.ResponseWriter, r *http.Request) {
	log.WithFields(log.Fields{
		"method": r.Method,
		"URI":    r.RequestURI,
	}).Info("Method not allowed")

	respondWithJSON(
		w,
		http.StatusMethodNotAllowed,
		map[string]string{"error": "Method not allowed"},
	)
}
