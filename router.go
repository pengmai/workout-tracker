package main

import (
	"net/http"

	"github.com/julienschmidt/httprouter"
)

// Route stores all of the data required for a single route.
type Route struct {
	Name    string
	Method  string
	Pattern string
	Handle  httprouter.Handle
}

// NewRouter initializes a new router with all of our routes and logging.
func (env *Env) NewRouter() *httprouter.Router {
	routes := []Route{
		{
			"Index",
			"GET",
			"/",
			GetIndex,
		},
		{
			"Icon",
			"GET",
			"/favicon.ico",
			GetIcon,
		},
		{
			"Gopher",
			"GET",
			"/gopher.gif",
			GetGopher,
		},
		{
			"SignUp",
			"POST",
			"/signup",
			env.SignUp,
		},
		{
			"Login",
			"POST",
			"/login",
			env.Login,
		},
		{
			"AddWorkout",
			"POST",
			"/workout",
			env.AddWorkout,
		},
		{
			"UpdateWorkout",
			"PUT",
			"/workout",
			env.UpdateWorkout,
		},
		{
			"DeleteWorkout",
			"DELETE",
			"/workout/:id",
			env.DeleteWorkout,
		},
	}

	router := httprouter.New()
	for _, route := range routes {
		router.Handle(
			route.Method,
			route.Pattern,
			env.loggerMiddleware(route.Name, route.Handle),
		)
	}

	router.NotFound = http.HandlerFunc(NotFound)
	router.MethodNotAllowed = http.HandlerFunc(MethodNotAllowed)

	return router
}
