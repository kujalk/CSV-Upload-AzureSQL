DROP TABLE IF EXISTS Delta.income;
DROP TABLE IF EXISTS Delta.get_fit_now_check_in;
DROP TABLE IF EXISTS Delta.get_fit_now_member;
DROP TABLE IF EXISTS Delta.interview;
DROP TABLE IF EXISTS Delta.facebook_event_checkin;
DROP TABLE IF EXISTS Delta.person;
DROP TABLE IF EXISTS Delta.crime_scene_report;
DROP TABLE IF EXISTS Delta.drivers_license;

IF (NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Delta')) 
BEGIN
    EXEC ('CREATE SCHEMA [Delta] AUTHORIZATION [dbo]')
END
CREATE TABLE Delta.crime_scene_report (
"date" integer,
"type" text,
"description" text,
"city" text
);

CREATE TABLE Delta.drivers_license (
"id" integer,
"age" integer,
"height" integer,
"eye_color" text,
"hair_color" text,
"gender" text,
"plate_number" text,
"car_make" text,
"car_model" text,
PRIMARY KEY("id")
);

CREATE TABLE Delta.person (
"id" integer,
"name" text,
"license_id" integer,
"address_number" integer,
"address_street_name" text,
"ssn" integer,
PRIMARY KEY("id"),
FOREIGN KEY("license_id") REFERENCES Delta.drivers_license("id")
);

CREATE TABLE Delta.facebook_event_checkin (
"person_id" integer,
"event_id" integer,
"event_name" text,
"date" integer,
FOREIGN KEY("person_id") REFERENCES Delta.person("id")
);

CREATE TABLE Delta.interview (
"person_id" integer,
"transcript" text,
FOREIGN KEY("person_id") REFERENCES Delta.person("id")
);

CREATE TABLE Delta.get_fit_now_member (
"id" VARCHAR(50),
"person_id" integer,
"name" text,
"membership_start_date" integer,
"membership_status" text,
PRIMARY KEY("id"),
FOREIGN KEY("person_id") REFERENCES Delta.person("id")
);

CREATE TABLE Delta.get_fit_now_check_in (
"membership_id" VARCHAR(50),
"check_in_date" integer,
"check_in_time" integer,
"check_out_time" integer,
FOREIGN KEY("membership_id") REFERENCES Delta.get_fit_now_member("id")
);

CREATE TABLE Delta.income (
"ssn" integer,
"annual_income" integer,
PRIMARY KEY("ssn")
);