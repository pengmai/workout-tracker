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
	AddWorkout(workout Workout) error
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

func (db *DB) LoginWithToken(token string) (User, error) {
	user := User{}
	row := db.QueryRow("SELECT id, name FROM users WHERE token = $1", token)
	err := row.Scan(&user.ID, &user.Name)
	switch {
	case err == sql.ErrNoRows:
		return user, ErrUserNotFound
	case err != nil:
		return user, err
	default:
		return user, nil
	}
}

func (db *DB) AddWorkout(workout Workout) error {
	if !db.rowExists("SELECT id FROM users WHERE id = $1", workout.User) {
		return ErrUserNotFound
	}

	_, err := db.Exec(
		`INSERT INTO workouts(user_id, start_time, end_time)
		VALUES ($1, $2, $3)`,
		workout.User, workout.Start.Time, workout.End.Time,
	)
	return err
}

func (db *DB) GetWorkouts(userID int) ([]Workout, error) {
	workouts := make([]Workout, 0)
	err := db.readRows(
		func(rs *sql.Rows) error {
			var workout Workout
			readErr := rs.Scan(&workout.Start.Time, &workout.End.Time)
			workouts = append(workouts, workout)
			return readErr
		},
		"SELECT start_time, end_time FROM workouts WHERE user_id = $1",
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
var ErrUserAlreadyExists = errors.New("datastore: a user with the given name already exists")
var ErrUserNotFound = errors.New("datastore: a user with the given information could not be found")
var ErrInvalidCredentials = errors.New("datastore: the user's credentials did not match")
