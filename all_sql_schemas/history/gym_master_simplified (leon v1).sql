DROP SCHEMA IF EXISTS gym;
CREATE SCHEMA gym;
USE gym;

# About the users
# user is generally the person who has access to this system
# this has 3 roles in total: member, trainer, admin
# Trainer and member each has its own details but no requirement to store to much information about admin,
# so there is no specific table for admin
# trainer_details, and member_details inherit users table by setting user_id as as both primary key and foreign key.
# In order to insure they are 0..1 relationship, so the primary key is UNIQUE on member and trainers tables

CREATE TABLE `admin` (
  `admin_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(15) NOT NULL UNIQUE,
  `email` varchar(45) NOT NULL,
  PRIMARY KEY (`admin_id`)
);

CREATE TABLE `members` (
  `member_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(15) NOT NULL UNIQUE,
  `email` varchar(45) NOT NULL,

  `first_name` varchar(45) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `date_of_birth` date NOT NULL,
  `house_number_name` varchar(15) DEFAULT NULL,
  `street` varchar(20) DEFAULT NULL,
  `town` varchar(25) DEFAULT NULL,
  `city` varchar(25) DEFAULT NULL,
  `post_code` varchar(4) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `introductions` longtext DEFAULT NULL,
  `emergency_contact_person` varchar(45) DEFAULT NULL,
  `emergency_contact_phone` varchar(20) DEFAULT NULL,
  `health_record` longtext DEFAULT NULL,
  `weight` varchar(4) DEFAULT NULL,
  `height` varchar(4) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  PRIMARY KEY (`member_id`)
);

CREATE TABLE `subscriptions` (
  `sub_id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `startdatetime` datetime NOT NULL,
  `end_datetime` datetime NOT NULL,
  `is_active` bool,
  PRIMARY KEY (`sub_id`),
  FOREIGN KEY (`member_id`) REFERENCES members(member_id)
);


CREATE TABLE `trainers` (
  `trainer_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(15) NOT NULL UNIQUE,
  `email` varchar(45) NOT NULL,

  `first_name` varchar(45) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `date_of_birth` date NOT NULL,
  `house_number_name` varchar(15) DEFAULT NULL,
  `street` varchar(20) DEFAULT NULL,
  `town` varchar(25) DEFAULT NULL,
  `city` varchar(25) DEFAULT NULL,
  `post_code` varchar(4) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `qualifications` longtext DEFAULT NULL,
  `biography` longtext DEFAULT NULL,
  `speciality` longtext DEFAULT NULL,
  PRIMARY KEY (`trainer_id`)
);

#Schedule for a trainer
CREATE TABLE `trainer_schedules` (
    `schedule_id` int NOT NULL AUTO_INCREMENT,
    `trainer_id` int NOT NULL,
    `start_time` time NOT NULL,
    `end_time` time NOT NULL,
    `day_of_week` int NOT NULL,
     PRIMARY KEY (`schedule_id`),
     FOREIGN KEY (`trainer_id`) REFERENCES trainers(`trainer_id`)
);

CREATE TABLE `personal_training_bookings` (
    `pt_bk_id` int NOT NULL AUTO_INCREMENT,
    `trainer_id` int NOT NULL,
    `member_id` int NOT NULL,
    `duration` int NOT NULL,
    `start_datetime` time NOT NULL,
    `price` int DEFAULT 80,
    `created_on` datetime NOT NULL,
    `message` longtext DEFAULT NULL,
     PRIMARY KEY (`pt_bk_id`),
     FOREIGN KEY (`trainer_id`) REFERENCES trainers(`trainer_id`),
     FOREIGN KEY (`member_id`) REFERENCES members(`member_id`)
);



#Admin sends to other member
CREATE TABLE `messages` (
  `msg_id` int NOT NULL AUTO_INCREMENT,
  `sender_id` int NOT NULL,
  `receiver_id` int NOT NULL,
  `title` varchar(20),
  `messages` longtext DEFAULT NULL,
  `type` varchar(10) DEFAULT NULL,
  `read` bool DEFAULT FALSE,
  `sent_date_time` datetime,
  PRIMARY KEY (`msg_id`),
  FOREIGN KEY (`sender_id`) REFERENCES admin(`admin_id`),
  FOREIGN KEY (`receiver_id`) REFERENCES members(`member_id`)
);

# Parent class
CREATE TABLE `payments` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `amount` int NOT NULL,
  `created_on` datetime NOT NULL,
  `sub_id` int DEFAULT NULL,
  `pt_bk_id` int DEFAULT NULL,
  `pay_for` varchar(3) NOT NULL,
  PRIMARY KEY (`payment_id`),
  FOREIGN KEY (`sub_id`) REFERENCES subscriptions(`sub_id`),
  FOREIGN KEY (`pt_bk_id`) REFERENCES personal_training_bookings(`pt_bk_id`)
);


CREATE TABLE `group_exercise_sessions` (
  `session_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(25) NOT NULL,
  `trainer_id` int NOT NULL,
  `category` char(10) NOT NULL,
  `description` longtext DEFAULT NULL,
  `start_time` datetime,
  `day_of_week` int NOT NULL,
  `max_space` int DEFAULT 30,
  PRIMARY KEY (`session_id`),
  FOREIGN KEY (`trainer_id`) REFERENCES trainers(`trainer_id`)
);


CREATE TABLE `group_sessions_bookings` (
  `bk_id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `session_id` int NOT NULL,
  `created_on` datetime DEFAULT NULL,
  `start_time` datetime,
  `day_of_week` int NOT NULL,
  `max_space` int DEFAULT 30,
  PRIMARY KEY (`bk_id`),
  FOREIGN KEY (`member_id`) REFERENCES members(`member_id`),
  FOREIGN KEY (`session_id`) REFERENCES group_exercise_sessions(`session_id`)
);


CREATE TABLE `attendances` (
  `attendance_id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `created_on` datetime NOT NULL,
  `using_gym` bool DEFAULT TRUE,
  `bk_id` int DEFAULT NULL,
  `pt_bk_id` int DEFAULT NULL,
  PRIMARY KEY (`attendance_id`),
  FOREIGN KEY (`member_id`) REFERENCES members(`member_id`),
  FOREIGN KEY (`bk_id`) REFERENCES group_sessions_bookings(`bk_id`),
  FOREIGN KEY (`pt_bk_id`) REFERENCES personal_training_bookings(`pt_bk_id`)
);


