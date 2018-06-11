package main

import (
	"database/sql"
	"errors"
)

// Datastore defines the methods used to retrieve data from our database.
type Datastore interface {
	SignUp(request UserRequest) (int, error)
	LoginWithCredentials(name, passHash string) (User, error)
	LoginWithToken(token string) (User, error)
	GetUsername(userID int) (string, error)
	AddWorkout(workout Workout) (int, error)
	UpdateWorkout(workout Workout) error
	DeleteWorkout(workoutID int) error
	GetWorkouts(userID int) ([]Workout, error)
	GetUsers() ([]string, error)
}

// DB implements Datastore and serves as the bridge between the Datastore
// definition and the actual database.
type DB struct {
	*sql.DB
}

// InitializeDB initializes the database connection.
func InitializeDB(driverName, dataSourceName string) (*DB, error) {
	db, err := sql.Open(driverName, dataSourceName)
	if err != nil {
		return nil, err
	}
	if err = db.Ping(); err != nil {
		return nil, err
	}

	return &DB{db}, nil
}

// SignUp adds a new user to the database and returns their user ID.
func (db *DB) SignUp(r UserRequest) (int, error) {
	// Verify that the name is not already taken.
	if db.rowExists("SELECT id FROM users WHERE name = $1", r.Name) {
		return 0, ErrUserAlreadyExists
	}
	var userID int
	err := db.QueryRow(
		`INSERT INTO users(name, password, token)
		VALUES ($1, $2, $3) RETURNING id`,
		r.Name, r.Token, r.Token).Scan(&userID)
	return userID, err
}

// LoginWithCredentials logs a user in using a name and password hash.
func (db *DB) LoginWithCredentials(name, passHash string) (User, error) {
	user := User{}
	var ourPassHash string
	row := db.QueryRow("SELECT id, name, password FROM users WHERE name = $1", name)
	err := row.Scan(&user.ID, &user.Name, &ourPassHash)
	switch {
	case err == sql.ErrNoRows:
		return user, ErrUserNotFound
	case err != nil:
		return user, err
	case ourPassHash != passHash:
		return user, ErrInvalidCredentials
	default:
		return user, nil
	}
}

// LoginWithToken logs a user in using an access token.
func (db *DB) LoginWithToken(token string) (User, error) {
	user := User{}
	row := db.QueryRow("SELECT id, name FROM users WHERE token = $1", token)
	err := row.Scan(&user.ID, &user.Name)
	switch {
	case err == sql.ErrNoRows:
		return user, ErrUserNotFound
	default:
		return user, nil
	}
}

// GetUsername retrieves the name of the user with the given ID.
func (db *DB) GetUsername(userID int) (string, error) {
	var name string
	row := db.QueryRow("SELECT name FROM users WHERE id = $1", userID)
	err := row.Scan(&name)
	switch {
	case err == sql.ErrNoRows:
		return name, ErrUserNotFound
	default:
		return name, err
	}
}

// AddWorkout adds a workout to the database.
func (db *DB) AddWorkout(workout Workout) (int, error) {
	if !db.rowExists("SELECT id FROM users WHERE id = $1", workout.User) {
		return 0, ErrUserNotFound
	}

	var workoutID int
	err := db.QueryRow(
		`INSERT INTO workouts(user_id, start_time, end_time)
		VALUES ($1, $2, $3) RETURNING id`,
		workout.User, workout.Start.Time, workout.End.Time,
	).Scan(&workoutID)
	return workoutID, err
}

// UpdateWorkout replaces the workout with the given workout.
func (db *DB) UpdateWorkout(workout Workout) error {
	// Verify that the workout belongs to the user
	var ourUser int
	_ = db.QueryRow(
		"SELECT user_id FROM workouts WHERE id = $1",
		workout.ID,
	).Scan(&ourUser)
	if ourUser != workout.User {
		return ErrUserNotAuthorized
	}

	_, err := db.Exec(
		`UPDATE workouts
		SET start_time = $1, end_time = $2
		WHERE id = $3`,
		workout.Start.Time, workout.End.Time, workout.ID,
	)
	return err
}

// DeleteWorkout deletes the workout with the specified ID.
func (db *DB) DeleteWorkout(workoutID int) error {
	_, err := db.Exec(
		`DELETE FROM workouts WHERE id = $1`,
		workoutID,
	)
	return err
}

// GetWorkouts retrieves the list of workouts for the given user.
func (db *DB) GetWorkouts(userID int) ([]Workout, error) {
	workouts := make([]Workout, 0)
	err := db.readRows(
		func(rs *sql.Rows) error {
			var workout Workout
			readErr := rs.Scan(&workout.ID, &workout.Start.Time, &workout.End.Time)
			workouts = append(workouts, workout)
			return readErr
		},
		"SELECT id, start_time, end_time FROM workouts WHERE user_id = $1",
		userID,
	)
	return workouts, err
}

// GetUsers returns a list of users' names from the database.
func (db *DB) GetUsers() ([]string, error) {
	var userNames []string
	err := db.readRows(
		func(rs *sql.Rows) error {
			var name string
			readErr := rs.Scan(&name)
			userNames = append(userNames, name)
			return readErr
		},
		"SELECT name FROM users",
	)
	return userNames, err
}

func (db *DB) readRows(read func(rs *sql.Rows) error, query string, args ...interface{}) error {
	rows, err := db.Query(query, args...)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		err = read(rows)
		if err != nil {
			return err
		}
	}
	if err = rows.Err(); err != nil {
		return err
	}

	return nil
}

func (db *DB) rowExists(query string, args ...interface{}) bool {
	row := db.QueryRow(query, args...)
	return row.Scan() != sql.ErrNoRows
}

/* Custom error types */

// ErrUserAlreadyExists is returned when a new account with an existing name is requested.
var ErrUserAlreadyExists = errors.New("datastore: a user with the given name already exists")

// ErrUserNotFound is returned when a user could not be found.
var ErrUserNotFound = errors.New("datastore: a user with the given information could not be found")

// ErrInvalidCredentials is returned when a user login fails.
var ErrInvalidCredentials = errors.New("datastore: the user's credentials did not match")

// ErrUserNotAuthorized is returned when a user requests an action that they do not have
// access to.
var ErrUserNotAuthorized = errors.New("datastore: the user does not have access to modify the workout")
