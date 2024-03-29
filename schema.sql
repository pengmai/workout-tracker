DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
	id SERIAL CONSTRAINT userid PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	password VARCHAR(50) NOT NULL,
	token VARCHAR(50) NOT NULL
);

DROP TABLE IF EXISTS workouts CASCADE;
CREATE TABLE workouts (
	id SERIAL CONSTRAINT workoutid PRIMARY KEY,
	user_id integer NOT NULL,
	start_time TIMESTAMP WITH TIME ZONE NOT NULL,
	end_time TIMESTAMP WITH TIME ZONE NOT NULL,
	CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);
