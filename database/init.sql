CREATE DATABASE IF NOT EXISTS appdb;
USE appdb;

CREATE TABLE IF NOT EXISTS students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  major VARCHAR(100) NOT NULL,
  gpa DECIMAL(3,2) NOT NULL
);

INSERT INTO students (name, major, gpa) VALUES
  ('Alice Johnson',   'Computer Science', 3.85),
  ('Bob Martinez',    'Mechanical Eng.',  3.50),
  ('Carla Singh',     'Economics',        3.92),
  ('David Lee',       'Biology',          3.70),
  ('Eva Chen',        'Mathematics',      3.98);
