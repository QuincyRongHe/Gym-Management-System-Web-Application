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

CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(45) NOT NULL,
  `role` varchar(7) NOT NULL,
  PRIMARY KEY (`user_id`)
);

CREATE TABLE `members` (
  `member_id` int NOT NULL UNIQUE,
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
  `health_record` longtext,
  PRIMARY KEY (`member_id`),
  FOREIGN KEY (`member_id`) REFERENCES users(`user_id`)
);

CREATE TABLE `trainers` (
  `trainer_id` int NOT NULL UNIQUE,
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
  `emergency_contact_number` varchar(20) DEFAULT NULL,
  `health_record` longtext,
  PRIMARY KEY (`trainer_id`),
  FOREIGN KEY (`trainer_id`) REFERENCES users(`user_id`)
);

#Schedule for a trainer
CREATE TABLE `trainer_schedules` (
    `schedule_id` int NOT NULL AUTO_INCREMENT,
    `trainer_id` int NOT NULL,
    `start_time` time NOT NULL,
    `end_time` time NOT NULL,
    `break_time` time NOT NULL,
    `break_duration` DECIMAL(1,1) NOT NULL DEFAULT 0.5,
    `day_of_week` int NOT NULL,
     PRIMARY KEY (`schedule_id`),
     FOREIGN KEY (`trainer_id`) REFERENCES trainers(`trainer_id`)
);

CREATE TABLE `special_training_sessions` (
    `sp_id` int NOT NULL AUTO_INCREMENT,
    `trainer_id` int NOT NULL,
    `duration` int NOT NULL,
    `start_datetime` time NOT NULL,
    `price` int DEFAULT 80,
     PRIMARY KEY (`sp_id`),
     FOREIGN KEY (`trainer_id`) REFERENCES trainers(`trainer_id`)
);



#Admin sends to other member
CREATE TABLE `messages` (
  `msg_id` int NOT NULL AUTO_INCREMENT,
  `sender_id` int NOT NULL,
  `receiver_id` int NOT NULL,
  `title` varchar(20),
  `messages` longtext DEFAULT NULL,
  `read` bool DEFAULT FALSE,
  `sent_date_time` datetime,
  PRIMARY KEY (`msg_id`),
  FOREIGN KEY (`sender_id`) REFERENCES users(`user_id`),
  FOREIGN KEY (`receiver_id`) REFERENCES members(`member_id`)
);


CREATE TABLE `subscriptions` (
  `sub_id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `created_on` datetime NOT NULL,
  `next_payment_due` varchar(20),
  `is_active` bool,
  PRIMARY KEY (`sub_id`),
  FOREIGN KEY (`member_id`) REFERENCES members(member_id)
);

# Parent class
CREATE TABLE `payments` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `amount` int NOT NULL,
  `created_on` datetime NOT NULL,
  PRIMARY KEY (`payment_id`)
);

# is inherited by

CREATE TABLE `subscription_payments` (
  `sub_pay_id` int NOT NULL AUTO_INCREMENT,
  `sub_id` int NOT NULL UNIQUE,
  PRIMARY KEY (`sub_pay_id`),
  FOREIGN KEY (`sub_pay_id`) REFERENCES payments(`payment_id`),
  FOREIGN KEY (`sub_id`) REFERENCES subscriptions(`sub_id`)
);

CREATE TABLE `special_training_payments` (
  `sp_pay_id` int NOT NULL AUTO_INCREMENT,
  `sub_id` int NOT NULL UNIQUE,
  PRIMARY KEY (`sp_pay_id`),
  FOREIGN KEY (`sp_pay_id`) REFERENCES payments(`payment_id`),
  FOREIGN KEY (`sub_id`) REFERENCES subscriptions(`sub_id`)
);

# Once the payment is processed (could be declined or accepted)
# it will insert an entry here

CREATE TABLE `payment_process` (
  `process_id` int NOT NULL AUTO_INCREMENT,
  `payment_id` int NOT NULL,
  `processor_id` int NOT NULL,
  `accepted` bool NOT NULL DEFAULT FALSE,
  `processed_datetime` datetime,
  PRIMARY KEY (`process_id`),
  FOREIGN KEY (`processor_id`) REFERENCES users(`user_id`),
  FOREIGN KEY (`payment_id`) REFERENCES payments(`payment_id`)
);

CREATE TABLE `group_exercise_sessions` (
  `session_id` int NOT NULL AUTO_INCREMENT,
  `title` int NOT NULL,
  `trainer_id` int NOT NULL,
  `type` char(10) NOT NULL,
  `description` longtext DEFAULT NULL,
  `start_time` datetime,
  `day_of_week` int NOT NULL,
  `max_space` int DEFAULT 30,
  PRIMARY KEY (`session_id`),
  FOREIGN KEY (`trainer_id`) REFERENCES trainers(`trainer_id`)
);


CREATE TABLE `bookings_for_group_sessions` (
  `bk_id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `session_id` int NOT NULL,
  `datetime_created` longtext DEFAULT NULL,
  `start_time` datetime,
  `day_of_week` int NOT NULL,
  `max_space` int DEFAULT 30,
  PRIMARY KEY (`bk_id`),
  FOREIGN KEY (`member_id`) REFERENCES members(`member_id`),
  FOREIGN KEY (`session_id`) REFERENCES group_exercise_sessions(`session_id`)
);

CREATE TABLE `bookings_for_special_trainings` (
  `sp_bk_id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `session_id` int NOT NULL,
  `datetime_created` datetime NOT NULL,
  PRIMARY KEY (`sp_bk_id`),
  FOREIGN KEY (`member_id`) REFERENCES members(`member_id`),
  FOREIGN KEY (`session_id`) REFERENCES special_training_sessions(`sp_id`)
);

CREATE TABLE `attendances` (
  `attendance_id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `datetime_created` datetime NOT NULL,
  `using_gym` bool DEFAULT FALSE,
  PRIMARY KEY (`attendance_id`),
  FOREIGN KEY (`member_id`) REFERENCES members(`member_id`)
);

CREATE TABLE `attendances_for_group_sessions` (
  `attendance_id` int NOT NULL UNIQUE,
  `bk_id` int NOT NULL,

  PRIMARY KEY (`attendance_id`),
  FOREIGN KEY (`attendance_id`) REFERENCES attendances(`attendance_id`),
  FOREIGN KEY (`bk_id`) REFERENCES bookings_for_group_sessions(`bk_id`)
);

CREATE TABLE `attendances_for_special_sessions` (
  `attendance_id` int NOT NULL UNIQUE,
  `sp_bk_id` int NOT NULL,

  PRIMARY KEY (`attendance_id`),
  FOREIGN KEY (`attendance_id`) REFERENCES attendances(`attendance_id`),
  FOREIGN KEY (`sp_bk_id`) REFERENCES bookings_for_special_trainings(`sp_bk_id`)
);