DROP SCHEMA IF EXISTS gym;
CREATE SCHEMA gym;
USE gym;


create table admins
(
    admin_id   int auto_increment
        primary key,
    username   varchar(15) not null,
    email      varchar(45) not null,
    first_name varchar(25) not null,
    last_name  varchar(25) not null,
    constraint username
        unique (username)
);

create table members
(
    member_id                int auto_increment
        primary key,
    username                 varchar(15) not null,
    email                    varchar(45) not null,
    first_name               varchar(45) not null,
    last_name                varchar(45) not null,
    date_of_birth            date        not null,
    gender                   varchar(25) null,
    house_number_name        varchar(15) null,
    street                   varchar(20) null,
    town                     varchar(25) null,
    city                     varchar(25) null,
    post_code                varchar(4)  null,
    phone                    varchar(20) null,
    introductions            longtext    null,
    emergency_contact_person varchar(45) null,
    emergency_contact_phone  varchar(20) null,
    health_record            longtext    null,
    weight                   varchar(4)  null,
    height                   varchar(4)  null,
    created_on               datetime    default CURRENT_TIMESTAMP,
    constraint username
        unique (username)
);

create table trainers
(
    trainer_id        int auto_increment
        primary key,
    username          varchar(15) not null,
    email             varchar(45) not null,
    first_name        varchar(45) not null,
    last_name         varchar(45) not null,
    date_of_birth     date        not null,
    gender            varchar(25) null,
    house_number_name varchar(15) null,
    street            varchar(20) null,
    town              varchar(25) null,
    city              varchar(25) null,
    post_code         varchar(4)  null,
    phone             varchar(20) null,
    qualifications    longtext    null,
    biography         longtext    null,
    speciality        longtext    null,
    constraint username
        unique (username)
);

create table group_exercise_sessions
(
    session_id  int auto_increment
        primary key,
    title       varchar(25)    not null,
    trainer_id  int            not null,
    category    char(50)       not null,
    description longtext       null,
    start_date  date       not null,
    start_time  time			not null,
    location    varchar(10)    not null,
    max_space   int default 30 null,
    constraint group_exercise_sessions_ibfk_1
        foreign key (trainer_id) references trainers (trainer_id)
);




create table group_sessions_bookings
(
    bk_id       int auto_increment
        primary key,
    member_id   int            not null,
    session_id  int            not null,
    created_on  datetime       default CURRENT_TIMESTAMP,
    constraint group_sessions_bookings_ibfk_1
        foreign key (member_id) references members (member_id),
    constraint group_sessions_bookings_ibfk_2
        foreign key (session_id) references group_exercise_sessions (session_id)
);

create index member_id
    on group_sessions_bookings (member_id);

create index session_id
    on group_sessions_bookings (session_id);

create table trainer_schedules
(
    schedule_id int auto_increment
        primary key,
    trainer_id  int         not null,
    start_time  time        not null,
    end_time    time        not null,
    day_of_week int         not null,
    constraint trainer_schedules_ibfk_1
        foreign key (trainer_id) references trainers (trainer_id),
	constraint check_is_within_business_hours
		check(start_time >= TIME '06:00:00' AND end_time <= TIME '20:00:00'),
	constraint check_day_of_a_week
		check(day_of_week > 0 AND day_of_week < 8)
);

create index trainer_id
    on trainer_schedules (trainer_id);


-- Triggers (Please Do NOT touch this Area)

DELIMITER $$
CREATE TRIGGER `group_sessions_can_only_happen_when_trainer_is_available` BEFORE INSERT ON `group_exercise_sessions`
FOR EACH ROW
BEGIN
	DECLARE stime_tsch time;
    DECLARE etime_tsch time;
    DECLARE stime_session time;
    DECLARE etime_session time;
    DECLARE newweekday int;
    SET newweekday = (weekday(NEW.start_date)+1);
	SET stime_tsch = (SELECT start_time FROM trainer_schedules WHERE NEW.trainer_id=trainer_schedules.trainer_id AND newweekday = trainer_schedules.day_of_week);
    SET etime_tsch = (SELECT end_time FROM trainer_schedules WHERE NEW.trainer_id=trainer_schedules.trainer_id AND newweekday = trainer_schedules.day_of_week);
    SET stime_session = (SELECT start_time FROM group_exercise_sessions WHERE NEW.trainer_id=group_exercise_sessions.trainer_id AND NEW.start_date = group_exercise_sessions.start_date);

    IF stime_tsch IS NULL OR stime_tsch > NEW.start_time OR etime_tsch IS NULL OR etime_tsch <= NEW.start_time
    OR stime_session = NEW.start_time
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "Group session should be within trainer's available timeframe";
    END IF;
END$$
DELIMITER ;

--






create table personal_training_bookings
(
    pt_bk_id       int auto_increment
        primary key,
    trainer_id     int                                not null,
    member_id      int                                not null,
    duration       int                                not null,
    start_date     date                               not null,
    start_time     time                               not null,
    price          int      default 80                null,
    location       varchar(10)                        not null,
    created_on     datetime default CURRENT_TIMESTAMP null,
    message        longtext                           null,
    constraint personal_training_bookings_ibfk_1
        foreign key (trainer_id) references trainers (trainer_id),
    constraint personal_training_bookings_ibfk_2
        foreign key (member_id) references members (member_id)
);

create index member_id
    on personal_training_bookings (member_id);

create index trainer_id
    on personal_training_bookings (trainer_id);

create table subscriptions
(
    sub_id        int auto_increment
        primary key,
    member_id     int        not null,
    startdatetime datetime   not null,
    end_datetime  datetime   not null,
    is_active     tinyint(1) null,
    constraint subscriptions_ibfk_1
        foreign key (member_id) references members (member_id)
);

create index member_id
    on subscriptions (member_id);




create table messages
(
    msg_id         int auto_increment
        primary key,
    sender_id      int                  not null,
    receiver_id    int                  not null,
    title          varchar(50)          null,
    messages       longtext             null,
    type           varchar(20)          not null,
    `read`         tinyint(1)     default 0 ,
    sent_date_time datetime             null,
    constraint messages_ibfk_1
        foreign key (sender_id) references admins (admin_id),
    constraint messages_ibfk_2
        foreign key (receiver_id) references members (member_id),
	constraint message_types_check
		check( type in ('SUB', 'PT', 'OTHER', 'PROMO', 'NEWS'))
);

create index receiver_id
    on messages (receiver_id);

create index sender_id
    on messages (sender_id);




create table payments
(
    payment_id int auto_increment
        primary key,
    amount     int         not null,
    created_on datetime    default CURRENT_TIMESTAMP,
    sub_id     int         not null,
    pt_bk_id   int         null,
    pay_for    varchar(20) not null,
    constraint payments_ibfk_1
        foreign key (sub_id) references subscriptions (sub_id),
    constraint payments_ibfk_2
        foreign key (pt_bk_id) references personal_training_bookings (pt_bk_id),
	constraint pay_for_category
		check( pay_for in ('SUB', 'PT')),
	constraint payment_type_check
		check( (pay_for = 'SUB' AND pt_bk_id IS NULL) OR (pay_for = 'PT' AND pt_bk_id IS NOT NULL))
);




create index pt_bk_id
    on payments (pt_bk_id);


-- Triggers (Please Do NOT touch this Area)

DELIMITER $$
CREATE TRIGGER `only_member_with_active_sub_can_pay` BEFORE INSERT ON `payments`
FOR EACH ROW
BEGIN
    IF (SELECT is_active FROM subscriptions WHERE NEW.sub_id=sub_id) IS FALSE AND NEW.pt_bk_id is NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "only members with an active sub can pay";
    END IF;
END$$
DELIMITER ;

--

create index sub_id
    on payments (sub_id);




create table attendances
(
    attendance_id int auto_increment
        primary key,
    member_id     int                  not null,
    created_on    datetime             not null,
    using_gym_only     tinyint(1) default 1 null,
    bk_id         int                  null,
    pt_bk_id      int                  null,
    constraint attendances_ibfk_1
        foreign key (member_id) references members (member_id),
    constraint attendances_ibfk_2
        foreign key (bk_id) references group_sessions_bookings (bk_id),
    constraint attendances_ibfk_3
        foreign key (pt_bk_id) references personal_training_bookings (pt_bk_id),
	CONSTRAINT only_one_attendance_is_recorded_per_row
		CHECK (
        ( CASE WHEN using_gym_only IS FALSE THEN 0 ELSE 1 END
		+ CASE WHEN bk_id IS NULL THEN 0 ELSE 1 END
		+ CASE WHEN pt_bk_id IS NULL THEN 0 ELSE 1 END
		) = 1
        )
);

create index bk_id
    on attendances (bk_id);

create index member_id
    on attendances (member_id);

create index pt_bk_id
    on attendances (pt_bk_id);


create index trainer_id
    on group_exercise_sessions (trainer_id);


-- Triggers (Please Do NOT touch this Area)

-- DELIMITER $$
-- CREATE TRIGGER `only_one_of_three_column_can_have_value` BEFORE INSERT ON `attendances`
-- FOR EACH ROW
-- BEGIN
--     IF NEW.using_gym_only = 0 THEN
--         SIGNAL SQLSTATE '12345'
--             SET MESSAGE_TEXT = 'check constraint on Test.ID failed';
--     END IF;
-- END$$
-- DELIMITER ;


--


INSERT INTO admins (admin_id, username, first_name, last_name, email) VALUES
(1, 'admintiger', 'Sarah ', 'Johnson', 'admintiger@yahoo.com'),
(2, 'adminlion', 'Sabrina', 'Zhang', 'adminlion@yahoo.com'),
(3, 'adminpanda', 'Nadia', 'Davis', 'adminpanda@yahoo.com'),
(4, 'admincheetah', 'Chris', 'Bone', 'admincheetah@yahoo.com');


INSERT INTO members (member_id, username, email, first_name, last_name, date_of_birth, gender, house_number_name, street, town, city, post_code, phone, introductions, emergency_contact_person, emergency_contact_phone, health_record, weight, height, created_on) VALUES
(1, 'johnsmith', 'john.smith@gmail.com', 'John', 'Smith', '1992-05-07', 'Male', '1', 'Main st', 'Flatbush', 'Auckland', '0876', '021768325', 'Hi, I am John Smith and I want to stay fit and healthy!', 'Janie Smith', '0226752313', 'No known health issues', '80', '180', '2023-03-09 11:04:33'),
(2, 'sara999', 'sara999@hotmail.com', 'Sara', 'Jones', '1985-03-02', 'Female', '3', 'Oak st', 'Henderson', 'Auckland', '0234', '0217835341', 'Hello, my name is Sara Jones and I want to be in the best shape of my life!', 'Michael Jones', '02376686865', 'Allergic to some food items', '60', '173', '2023-02-09 11:07:21'),
(3, 'lisaflowers', 'lisa2022@gmail.com', 'Lisa', 'Williams', '2000-03-04', 'Female', '38', 'Pink avenue', 'Albany', 'Auckland', '0754', '0212887534', 'Hi there! I am Lisa Williams and I want to get in shape for my wedding!', 'David Williams', '02234154363', 'No known health issues', '70', '167', '2023-03-09 11:09:52'),
(4, 'johndoe', 'john.doe@gmail.com', 'John', 'Doe', '1990-10-15', 'Male', '23', 'Elm st', 'Mt. eden', 'Auckland', '1024', '0276689342', 'Hey, I am John Doe and I am ready to start my fitness journey!', 'Sarah Johnson', '0278736458', 'Allergic to nuts', '85', '182', '2023-03-10 15:20:12'),
(5, 'emilyjane', 'emilyjane@gmail.com', 'Emily', 'Jane', '1995-08-22', 'Female', '9', 'rose st', 'Takapuna', 'Auckland', '0622', '0227865432', 'Hello, my name is Emily Jane and I am excited to join this gym!', 'Lucas Brown', '0213654321', 'Asthma', '63', '170', '2023-03-11 09:34:56'),
(6, 'davidgym', 'davidgym@gmail.com', 'David', 'Lee', '1982-06-30', 'Male', '17', 'ocean rd', 'Mission bay', 'Auckland', '1071', '0217798754', 'Hi, my name is David Lee and I am committed to achieving my fitness goals!', 'Julie Kim', '0278765643', 'High blood pressure', '78', '175', '2023-03-12 14:45:23'),
(7, 'katefitness', 'katefitness@gmail.com', 'Kate', 'Wilson', '1998-02-14', 'Female', '10', 'Orange rd', 'Mt. Roskill', 'Auckland', '1041', '0275689234', 'Hey everyone, I am Kate Wilson and I am ready to get fit!', 'Mark Wilson', '0217683490', 'Diabetes', '65', '170', '2023-03-13 10:12:56'),
(8, 'davidgreen', 'david.green@hotmail.com', 'David', 'Green', '1990-09-12', 'Male', '12', 'Ocean road', 'Mission bay', 'Auckland', '1071', '0217654321', 'Hello, I am David Green and I want to build muscle and increase my strength!', 'Rachel Green', '0212345678', 'Asthma', '90', '190', '2023-03-09 11:12:01'),
(9, 'jenny88', 'jenny88@gmail.com', 'Jenny', 'Brown', '1988-07-22', 'Female', '45', 'Queen street', 'City Centre', 'Auckland', '1010', '0211234567', 'Hi, I am Jenny Brown and I want to lose weight and improve my fitness!', 'Mark Brown', '0223456789', 'Allergic to dairy products', '75', '168', '2023-03-09 11:15:29'),
(10, 'peterpan', 'peter.pan@gmail.com', 'Peter', 'Pan', '2002-12-01', 'Male', '23', 'High street', 'Penrose', 'Auckland', '1061', '0212345678', 'Hi there! I am Peter Pan and I want to become more flexible and improve my posture!', 'Wendy Darling', '0271234567', 'No known health issues', '65', '175', '2023-03-09 11:18:47'),
(11, 'oliviajade', 'olivia.jade@hotmail.com', 'Olivia', 'Jade', '1995-05-16', 'Female', '9', 'Main road', 'Kumeu', 'Auckland', '0892', '0213456789', 'Hello, my name is Olivia Jade and I want to increase my stamina and endurance!', 'Jacob Jade', '0224567890', 'High blood pressure', '62', '170', '2023-03-09 11:22:15'),
(12, 'karen33', 'karen33@hotmail.com', 'Karen', 'Smith', '1990-08-02', 'Female', '7', 'Main road', 'Parnell', 'Auckland', '1052', '0211111111', 'Hello, my name is Karen and I am excited to start my fitness journey!', 'Peter Smith', '0212222222', 'Diabetes', '70', '170', '2023-03-11 14:15:10'),
(13, 'jessica11', 'jessica11@gmail.com', 'Jessica', 'Brown', '1987-06-22', 'Female', '6', 'Queen street', 'Auckland Central', 'Auckland', '1010', '0213333333', 'Hi there! I am Jessica and I am ready to transform my body!', 'Chris Brown', '0214444444', 'Hypertension', '85', '175', '2023-03-12 16:45:09'),
(14, 'mikec', 'mikec@gmail.com', 'Mike', 'Clark', '1995-01-25', 'Male', '12', 'high street', 'Grafton', 'Auckland', '1010', '0215555555', 'Hello, my name is Mike and I am committed to achieving my fitness goals!', 'Sarah Clark', '0216666666', 'No known health issues', '75', '180', '2023-03-12 18:20:07');




INSERT INTO trainers (trainer_id, username, email, first_name, last_name, date_of_birth, gender, house_number_name, street, town, city, post_code, phone, qualifications, biography, speciality) VALUES
(1, 'Emilyfitness', 'emilyfitness@gmail.com', 'Emily', 'Lee', '1987-03-14', 'Female', '5', 'Parkview st', 'Albany', 'Auckland', '0876', '0218796785', 'BSc in Sports Science, Level 3 Personal Trainer Certificate', 'I have been in the fitness industry for over 10 years and have experience training a range of clients, from beginners to advanced athletes', 'Strength training'),
(2, 'johnnyhale', 'johnnyhale@gmail.com', 'Johnny', 'Hale', '1989-06-23', 'Male', '6', 'Amorino avenue', 'Albany', 'Auckland', '0875', '02276548421', 'BSc in Exercise Science, Level 2 Gym Instructor Certificate, Level 3 Personal Trainer Certificate', 'I am passionate about helping people achieve their fitness goals and love to see my clients improve their health and confidence', 'HIIT'),
(3, 'sarah999', 'sarah999@gmail.com', 'Sarah', 'Taylor', '1994-08-11', 'Female', '30', 'Tompson st', 'Henderson', 'Auckland', '0616', '02136708657', 'BSc in Sports and Exercise Science, Level 3 Personal Trainer Certificate', 'I am a passionate and dedicated trainer who enjoys helping my clients reach their goals, no matter how big or small', 'Weight loss'),
(4, 'anita2010', 'anita2010@gmail.com', 'Anita', 'Dobston', '2003-10-24', 'Female', '23', 'George st', 'Henderson', 'Auckland', '0628', '0236755679', 'BSc in Sports and Exercise Science, Level 3 Personal Trainer Certificate', 'I am a dedicated and experienced trainer who loves helping people achieve their fitness goals and live healthier lives', 'Bodybuilding'),
(5, 'jefflau', 'jefflaufit@gmail.com', 'Jeff', 'Lau', '1990-09-28', 'Male', '86', 'Robins rd', 'Flatbush', 'Auckland', '0821', '02374681515', 'Level 3 Personal Trainer Certificate, Level 3 Diploma in Sports Massage Therapy', 'I am a highly motivated strength coach, with a passion for helping my clients achieve their fitness goals and feel their best', 'Strength training'),
(6, 'stevenroberts1', 'stevenroberts1@yahoo.com', 'Steven', 'Roberts', '1989-09-14', 'Male', '39', 'Market drive', 'Flatdiary', 'Auckland', '0912', '02163537484', 'Level 3 Personal Trainer Certificate', 'I love helping people achieving their goals.', 'Cardiovascular Fitness'),
(7, 'Jessicawu', 'jessicawu@yahoo.com', 'Jessica', 'Wu', '2003-03-01', 'Female', '890', 'Queen st', 'Remuera', 'Auckland', '0835', '02238790717', 'Certified Strength and Conditioning Specialist (CSCS), Certified Personal Trainer (CPT), TRX Suspension Training', 'I am a former collegiate athlete and has been a personal trainer for 8 years', 'Strength and conditioning training'),
(8, 'davidbrown60', 'davidbrown60@gmail.com', 'David', 'Brown', '1988-01-01', 'Male', '79', 'Albert drive', 'Silverdale', 'Auckland', '0982', '0212987638', 'Certified Personal Trainer (CPT), Pre- and Post-Natal Fitness, Nutrition Coach', 'I have been a personal trainer for 8 years.', 'Nutrition Coaching, FIIT'),
(9, 'Aaronfly', 'aaronfly@gmail.com', 'Aaron', 'Smith', '1986-12-10', 'Male', '100', 'Maple st', 'Hobsonville', 'Auckland', '0862', '02163534242', 'Doctor of Physical Therapy (DPT), Certified Strength and Conditioning Specialist (CSCS), Certified Personal Trainer (CPT)', 'I am a licensed physiotherapist and has been a personal trainer for over 15 years', 'Injury Prevention and Rehabilitation, Health and Wellness'),
(10, 'Samantha', 'samathajohnson@gmail.com', 'Samantha', 'Johnson', '1993-07-23', 'Female', '201', 'Bristol rd', 'Kumeu', 'Auckland', '0812', '02238716483', 'Certified Personal Trainer (CPT), CrossFit Level 1 Trainer, Group Fitness Instructor', 'I have been a personal trainer for over 10 years and specialise in functional training along with high-intensity interval training (HIIT)', 'Functional Training, HIIT, Weight Loss');

INSERT INTO trainer_schedules (schedule_id, trainer_id, start_time, end_time, day_of_week) VALUES
(1, 1, '06:00:00', '13:00:00', 1),
(2, 2, '06:00:00', '13:00:00', 1),
(3, 4, '13:00:00', '20:00:00', 1),
(4, 5, '13:00:00', '20:00:00', 1),
(5, 6, '13:00:00', '20:00:00', 1),
(6, 3, '06:00:00', '13:00:00', 2),
(7, 8, '06:00:00', '13:00:00', 2),
(8, 7, '13:00:00', '20:00:00', 2),
(9, 9, '13:00:00', '20:00:00', 2),
(10, 10, '13:00:00', '20:00:00', 2),

(11, 1, '06:00:00', '13:00:00', 3),
(12, 2, '06:00:00', '13:00:00', 3),
(13, 4, '13:00:00', '20:00:00', 3),
(14, 5, '13:00:00', '20:00:00', 3),
(15, 6, '13:00:00', '20:00:00', 3),
(16, 3, '06:00:00', '13:00:00', 4),
(17, 8, '06:00:00', '13:00:00', 4),
(18, 7, '13:00:00', '20:00:00', 4),
(19, 9, '13:00:00', '20:00:00', 4),
(20, 10, '13:00:00', '20:00:00', 4),


(21, 1, '06:00:00', '13:00:00', 5),
(22, 2, '06:00:00', '13:00:00', 5),
(23, 4, '13:00:00', '20:00:00', 5),
(24, 5, '13:00:00', '20:00:00', 5),
(25, 6, '13:00:00', '20:00:00', 5),



(26, 3, '06:00:00', '13:00:00', 7),
(27, 8, '06:00:00', '13:00:00', 7),
(28, 7, '06:00:00', '13:00:00', 7),
(29, 9, '06:00:00', '13:00:00', 7),
(30, 10, '06:00:00', '13:00:00', 7),
(31, 1, '13:00:00', '20:00:00', 7),
(32, 2, '13:00:00', '20:00:00', 7),
(33, 4, '13:00:00', '20:00:00', 7),
(34, 5, '13:00:00', '20:00:00', 7),
(35, 6, '13:00:00', '20:00:00', 7),

(36, 3, '06:00:00', '13:00:00', 6),
(37, 8, '06:00:00', '13:00:00', 6),
(38, 7, '06:00:00', '13:00:00', 6),
(39, 9, '06:00:00', '13:00:00', 6),
(40, 10, '06:00:00', '13:00:00', 6),
(41, 1, '13:00:00', '20:00:00', 6),
(42, 2, '13:00:00', '20:00:00', 6),
(43, 4, '13:00:00', '20:00:00', 6),
(44, 5, '13:00:00', '20:00:00', 6),
(45, 6, '13:00:00', '20:00:00', 6);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(1, 'Pilates', 1, 'Pilates', 'Focus on your core with the core principles of Pilates! The eight principles of the Pilates technique – concentration, breath, centering, control, precision, movement, isolation and routine – are brought together to give you a low-impact workout that strengthens like nothing else.', '2023-04-03', '07:00:00', 'studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(2, 'EnergyHIIT', 2, 'HIIT', 'A high intensity interval workout with different stations that focus on cardiovascular conditioning and strength training.', '2023-04-03', '10:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(3, 'BoxFit', 4, 'Boxing', 'Workouts with emphasis on improving boxing technique and boxing style training (High Intensity Training). Pads will be supplied to members and also gloves will be available to borrow if you don’t own any. Bringing your own gloves is advised and boxing wraps are a requirement for protection and hygiene reasons.', '2023-04-03', '15:00:00', 'studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(4, 'Yoga', 5, 'Yoga', 'Yoga your mind and yoga your body. This workout can range from gentle and slow-moving to dynamic, but it always tones, shapes and centres the mind without impact or stress.', '2023-04-03', '17:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(5, 'Zumba', 6, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-04-03', '19:00:00','studio3', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(6, 'MetaFIT', 3, 'FIT', 'A 60-minute bodyweight training system that gets results!! A functional and effective metabolic workout that will change the way you train', '2023-04-04', '07:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(7, 'EnergyCORE', 8, 'CORE', 'Focus on your core and all of you will benefit! Strengthen your middle and improve your posture with this fantastically focused workout.', '2023-04-04', '10:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(8, 'EnergyLITE', 7, 'LITE', 'A cardio class designed for all levels, this class has a mix of high and low intensity that burns calories and helps tone your body.', '2023-04-04', '15:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(9, 'PowerPump', 9, 'Strength', 'A weight-training workout designed to increase strength and endurance. With various equipment and exercises, this class will get you lifting like a pro!', '2023-04-04', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(10, 'SpinCycle', 10, 'Cycling', 'Get your heart pumping and your legs moving with this intense cycling workout. With music that will keep you motivated, you won’t even realize how hard you’re working!', '2023-04-04', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(11, 'KickBox', 1, 'Kickboxing', 'This high-energy class combines martial arts techniques with fast-paced cardio. With moves that range from punches to kicks, you’ll leave feeling like a total bad-ass!', '2023-04-05', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(12, 'BarreClass', 2, 'Barre', 'This ballet-inspired workout uses a combination of moves to tone and sculpt your entire body. With a focus on the core and legs, you’ll feel like a ballerina in no time!', '2023-04-05', '10:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(13, 'BootCamp', 4, 'Bootcamp', 'This military-style workout will push you to your limits! With a mix of cardio and strength training exercises, you’ll feel like a soldier by the end of it.', '2023-04-05', '15:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(14, 'YinYoga', 5, 'Yoga', 'This slow-paced form of yoga focuses on relaxation and stress-reduction. With a mix of gentle poses and deep breathing, you’ll leave feeling calm and centered.', '2023-04-05', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(15, 'PoundFit', 6, 'Drumming', 'This unique workout combines cardio, strength training, and drumming for a full-body workout that’s fun and effective. With drumsticks in hand, you’ll feel like a rockstar!', '2023-04-05', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(16, 'BodyPump', 3, 'Weight', 'A barbell workout that strengthens your entire body. This workout challenges all your major muscle groups by using the best weight-room exercises such as squats, presses, lifts and curls.', '2023-04-06', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(17, 'Spin', 8, 'Cycling', 'An indoor cycling class that is fun, low-impact and high-intensity. You’ll ride to upbeat music, while an experienced instructor leads you through hills, flats, intervals and jumps.', '2023-04-06', '10:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(18, 'TRX', 7, 'Functional Training', 'Suspension training using the TRX that develops strength, balance, flexibility and core stability simultaneously. It requires the use of the TRX Suspension Trainer, a highly portable performance training tool that leverages gravity and the user’s body weight to complete hundreds of exercises.', '2023-04-06', '15:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(19, 'BootCamp', 9, 'HIIT', 'An intense workout that is designed to get you in the best shape of your life. It combines strength training and cardio in one session and includes a mix of bodyweight exercises, weights, and cardio drills to help you build muscle and burn fat.', '2023-04-06', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(20, 'Barre', 10, 'Barre', 'A ballet-inspired workout that targets your entire body. This workout combines the best of yoga, Pilates and ballet to give you a low-impact workout that tones your muscles and improves your flexibility.', '2023-04-06', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(21, 'YinYoga', 1, 'Yoga', 'A slow-paced yoga class that focuses on breathing and holding poses for a longer period of time. This practice is designed to release tension and increase flexibility.', '2023-04-07', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(22, 'PumpUp', 2, 'Weight', 'A total body workout using weights to tone and sculpt your muscles. Perfect for all fitness levels and a great way to build strength and confidence.', '2023-04-07', '10:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(23, 'SpinCycle', 4, 'Cycling', 'A high-intensity indoor cycling class that simulates outdoor riding. Burn calories and improve your cardiovascular fitness in this fun and challenging workout.', '2023-04-07', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(24, 'BarreBurn', 5, 'Barre', 'A ballet-inspired workout that targets your entire body, with a focus on the legs, glutes, and core. Improve your balance and flexibility while toning your muscles.', '2023-04-07', '17:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(25, 'BodyAttack', 6, 'Cardio', 'A high-energy, sports-inspired workout that combines aerobics, strength, and conditioning exercises. Improve your speed, agility, and coordination while burning calories.', '2023-04-07', '19:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(26, 'FlexFlow', 3, 'Flex', 'A class designed to improve your flexibility and range of motion. Incorporates stretching and mobility exercises to help you move better and feel better.', '2023-04-08', '07:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(27, 'Piloxing', 8, 'Pilates', 'A fusion of Pilates, boxing, and dance, this workout targets your core and improves your cardiovascular fitness. Sculpt your body and have fun in this unique class!', '2023-04-08', '10:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(28, 'BodyPump', 2, 'Weight ', 'A barbell workout that strengthens and tones your entire body. Suitable for all levels, this class will challenge you and help you achieve your fitness goals.', '2023-04-08', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(29, 'BodyPump', 5, 'Strength', 'Get lean, tone muscle, and work your entire body with this barbell-based workout.', '2023-04-08', '17:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(30, 'Spin', 1, 'Cycling', 'Experience the thrill of the ride with this indoor cycling class that simulates outdoor terrain and challenges your endurance.', '2023-04-08', '19:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(31, 'BodyCombat', 3, 'Combat', 'Kick, punch, and strike your way to a better body and improved cardiovascular fitness with this high-energy martial arts-inspired workout.', '2023-04-09', '07:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(32, 'Piloxing', 8, 'Piloxing', 'This fusion of Pilates and boxing will challenge your body and mind, and help you build lean muscle and improve your coordination.', '2023-04-09', '10:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(33, 'TRX', 2, 'Suspension', 'Use your own body weight and gravity to build strength, balance, flexibility, and core stability with this suspension training workout.', '2023-04-09', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(34, 'Yin Yoga', 5, 'Yoga', 'Relax, stretch, and release tension with this slow-paced style of yoga that focuses on holding poses for an extended period of time.', '2023-04-09', '17:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(35, 'Barre', 1, 'Barre', 'Shape, tone, and sculpt your body with this ballet-inspired workout that combines elements of Pilates, yoga, and strength training.', '2023-04-09', '19:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(36, 'Zumba', 7, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-04-08', '07:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(37, 'Barre', 9, 'Barre', 'This workout incorporates elements of ballet, Pilates, and yoga to create a full-body workout that strengthens, tones, and lengthens muscles.', '2023-04-08', '10:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(38, 'Spin', 4, 'Cardio', 'A high-intensity cycling class that simulates outdoor cycling on stationary bikes with fast-paced music to keep you motivated and engaged.', '2023-04-08', '15:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(39, 'Bootcamp', 5, 'Bootcamp', 'A challenging and intense workout that combines strength training and cardiovascular conditioning to improve your overall fitness level.', '2023-04-08', '19:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(40, 'Zumba', 7, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-04-09', '07:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(41, 'TRX', 9, 'Functional', 'A total body workout that uses suspension training to build strength, balance, flexibility, and core stability.', '2023-04-09', '10:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(42, 'Piloxing', 4, 'Piloxing', 'A fusion of Pilates, boxing, and dance that creates a full-body workout that burns calories, strengthens muscles, and improves flexibility.', '2023-04-09', '15:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(43, 'Yogalates', 6, 'Yogalates', 'A combination of yoga and Pilates that creates a holistic workout that strengthens muscles, improves flexibility, and promotes relaxation and stress reduction.', '2023-04-09', '19:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(44, 'Pole Fitness', 2, 'Pole Fitness', 'A workout that combines dance, acrobatics, and strength training using a vertical pole to create a challenging and fun workout that strengthens muscles and improves flexibility.', '2023-04-09', '19:00:00',
 'studio3', 30);



INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(45, 'Pilates', 1, 'Pilates', 'Focus on your core with the core principles of Pilates! The eight principles of the Pilates technique – concentration, breath, centering, control, precision, movement, isolation and routine – are brought together to give you a low-impact workout that strengthens like nothing else.', '2023-03-27', '07:00:00', 'studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(46, 'EnergyHIIT', 2, 'HIIT', 'A high intensity interval workout with different stations that focus on cardiovascular conditioning and strength training.', '2023-03-27', '10:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(47, 'BoxFit', 4, 'Boxing', 'Workouts with emphasis on improving boxing technique and boxing style training (High Intensity Training). Pads will be supplied to members and also gloves will be available to borrow if you don’t own any. Bringing your own gloves is advised and boxing wraps are a requirement for protection and hygiene reasons.', '2023-03-27', '15:00:00', 'studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(48, 'Yoga', 5, 'Yoga', 'Yoga your mind and yoga your body. This workout can range from gentle and slow-moving to dynamic, but it always tones, shapes and centres the mind without impact or stress.', '2023-03-27', '17:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(49, 'Zumba', 6, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-03-27', '19:00:00','studio3', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(50, 'MetaFIT', 3, 'FIT', 'A 60-minute bodyweight training system that gets results!! A functional and effective metabolic workout that will change the way you train', '2023-03-28', '07:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(51, 'EnergyCORE', 8, 'CORE', 'Focus on your core and all of you will benefit! Strengthen your middle and improve your posture with this fantastically focused workout.', '2023-03-28', '10:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(52, 'EnergyLITE', 7, 'LITE', 'A cardio class designed for all levels, this class has a mix of high and low intensity that burns calories and helps tone your body.', '2023-03-28', '15:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(53, 'PowerPump', 9, 'Strength', 'A weight-training workout designed to increase strength and endurance. With various equipment and exercises, this class will get you lifting like a pro!', '2023-03-28', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(54, 'SpinCycle', 10, 'Cycling', 'Get your heart pumping and your legs moving with this intense cycling workout. With music that will keep you motivated, you won’t even realize how hard you’re working!', '2023-03-28', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(55, 'KickBox', 1, 'Kickboxing', 'This high-energy class combines martial arts techniques with fast-paced cardio. With moves that range from punches to kicks, you’ll leave feeling like a total bad-ass!', '2023-03-29', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(56, 'BarreClass', 2, 'Barre', 'This ballet-inspired workout uses a combination of moves to tone and sculpt your entire body. With a focus on the core and legs, you’ll feel like a ballerina in no time!', '2023-03-29', '10:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(57, 'BootCamp', 4, 'Bootcamp', 'This military-style workout will push you to your limits! With a mix of cardio and strength training exercises, you’ll feel like a soldier by the end of it.', '2023-03-29', '15:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(58, 'YinYoga', 5, 'Yoga', 'This slow-paced form of yoga focuses on relaxation and stress-reduction. With a mix of gentle poses and deep breathing, you’ll leave feeling calm and centered.', '2023-03-29', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(59, 'PoundFit', 6, 'Drumming', 'This unique workout combines cardio, strength training, and drumming for a full-body workout that’s fun and effective. With drumsticks in hand, you’ll feel like a rockstar!', '2023-03-29', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(60, 'BodyPump', 3, 'Weight', 'A barbell workout that strengthens your entire body. This workout challenges all your major muscle groups by using the best weight-room exercises such as squats, presses, lifts and curls.', '2023-03-30', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(61, 'Spin', 8, 'Cycling', 'An indoor cycling class that is fun, low-impact and high-intensity. You’ll ride to upbeat music, while an experienced instructor leads you through hills, flats, intervals and jumps.', '2023-03-30', '10:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(62, 'TRX', 7, 'Functional Training', 'Suspension training using the TRX that develops strength, balance, flexibility and core stability simultaneously. It requires the use of the TRX Suspension Trainer, a highly portable performance training tool that leverages gravity and the user’s body weight to complete hundreds of exercises.', '2023-03-30', '15:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(63, 'BootCamp', 9, 'HIIT', 'An intense workout that is designed to get you in the best shape of your life. It combines strength training and cardio in one session and includes a mix of bodyweight exercises, weights, and cardio drills to help you build muscle and burn fat.', '2023-03-30', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(64, 'Barre', 10, 'Barre', 'A ballet-inspired workout that targets your entire body. This workout combines the best of yoga, Pilates and ballet to give you a low-impact workout that tones your muscles and improves your flexibility.', '2023-03-30', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(65, 'YinYoga', 1, 'Yoga', 'A slow-paced yoga class that focuses on breathing and holding poses for a longer period of time. This practice is designed to release tension and increase flexibility.', '2023-03-31', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(66, 'PumpUp', 2, 'Weight', 'A total body workout using weights to tone and sculpt your muscles. Perfect for all fitness levels and a great way to build strength and confidence.', '2023-03-31', '10:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(67, 'SpinCycle', 4, 'Cycling', 'A high-intensity indoor cycling class that simulates outdoor riding. Burn calories and improve your cardiovascular fitness in this fun and challenging workout.', '2023-03-31', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(68, 'BarreBurn', 5, 'Barre', 'A ballet-inspired workout that targets your entire body, with a focus on the legs, glutes, and core. Improve your balance and flexibility while toning your muscles.', '2023-03-31', '17:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(69, 'BodyAttack', 6, 'Cardio', 'A high-energy, sports-inspired workout that combines aerobics, strength, and conditioning exercises. Improve your speed, agility, and coordination while burning calories.', '2023-03-31', '19:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(70, 'FlexFlow', 3, 'Flex', 'A class designed to improve your flexibility and range of motion. Incorporates stretching and mobility exercises to help you move better and feel better.', '2023-04-01', '07:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(71, 'Piloxing', 8, 'Pilates', 'A fusion of Pilates, boxing, and dance, this workout targets your core and improves your cardiovascular fitness. Sculpt your body and have fun in this unique class!', '2023-04-01', '10:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(72, 'BodyPump', 2, 'Weight ', 'A barbell workout that strengthens and tones your entire body. Suitable for all levels, this class will challenge you and help you achieve your fitness goals.', '2023-04-01', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(73, 'BodyPump', 5, 'Strength', 'Get lean, tone muscle, and work your entire body with this barbell-based workout.', '2023-04-01', '17:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(74, 'Spin', 1, 'Cycling', 'Experience the thrill of the ride with this indoor cycling class that simulates outdoor terrain and challenges your endurance.', '2023-04-01', '19:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(75, 'BodyCombat', 3, 'Combat', 'Kick, punch, and strike your way to a better body and improved cardiovascular fitness with this high-energy martial arts-inspired workout.', '2023-04-02', '07:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(76, 'Piloxing', 8, 'Piloxing', 'This fusion of Pilates and boxing will challenge your body and mind, and help you build lean muscle and improve your coordination.', '2023-04-02', '10:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(77, 'TRX', 2, 'Suspension', 'Use your own body weight and gravity to build strength, balance, flexibility, and core stability with this suspension training workout.', '2023-04-02', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(78, 'Yin Yoga', 5, 'Yoga', 'Relax, stretch, and release tension with this slow-paced style of yoga that focuses on holding poses for an extended period of time.', '2023-04-02', '17:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(79, 'Barre', 1, 'Barre', 'Shape, tone, and sculpt your body with this ballet-inspired workout that combines elements of Pilates, yoga, and strength training.', '2023-04-02', '19:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(80, 'Zumba', 7, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-04-01', '07:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(81, 'Barre', 9, 'Barre', 'This workout incorporates elements of ballet, Pilates, and yoga to create a full-body workout that strengthens, tones, and lengthens muscles.', '2023-04-01', '10:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(82, 'Spin', 4, 'Cardio', 'A high-intensity cycling class that simulates outdoor cycling on stationary bikes with fast-paced music to keep you motivated and engaged.', '2023-04-01', '15:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(83, 'Bootcamp', 5, 'Bootcamp', 'A challenging and intense workout that combines strength training and cardiovascular conditioning to improve your overall fitness level.', '2023-04-01', '19:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(84, 'Zumba', 7, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-04-02', '07:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(85, 'TRX', 9, 'Functional', 'A total body workout that uses suspension training to build strength, balance, flexibility, and core stability.', '2023-04-02', '10:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(86, 'Piloxing', 4, 'Piloxing', 'A fusion of Pilates, boxing, and dance that creates a full-body workout that burns calories, strengthens muscles, and improves flexibility.', '2023-04-02', '15:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(87, 'Yogalates', 6, 'Yogalates', 'A combination of yoga and Pilates that creates a holistic workout that strengthens muscles, improves flexibility, and promotes relaxation and stress reduction.', '2023-04-02', '19:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(88, 'Pole Fitness', 2, 'Pole Fitness', 'A workout that combines dance, acrobatics, and strength training using a vertical pole to create a challenging and fun workout that strengthens muscles and improves flexibility.', '2023-04-02', '19:00:00',
 'studio3', 30);





INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(89, 'Pilates', 1, 'Pilates', 'Focus on your core with the core principles of Pilates! The eight principles of the Pilates technique – concentration, breath, centering, control, precision, movement, isolation and routine – are brought together to give you a low-impact workout that strengthens like nothing else.', '2023-03-20', '07:00:00', 'studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(90, 'EnergyHIIT', 2, 'HIIT', 'A high intensity interval workout with different stations that focus on cardiovascular conditioning and strength training.', '2023-03-20', '10:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(91, 'BoxFit', 4, 'Boxing', 'Workouts with emphasis on improving boxing technique and boxing style training (High Intensity Training). Pads will be supplied to members and also gloves will be available to borrow if you don’t own any. Bringing your own gloves is advised and boxing wraps are a requirement for protection and hygiene reasons.', '2023-03-20', '15:00:00', 'studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(92, 'Yoga', 5, 'Yoga', 'Yoga your mind and yoga your body. This workout can range from gentle and slow-moving to dynamic, but it always tones, shapes and centres the mind without impact or stress.', '2023-03-20', '17:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(93, 'Zumba', 6, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-03-20', '19:00:00','studio3', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(94, 'MetaFIT', 3, 'FIT', 'A 60-minute bodyweight training system that gets results!! A functional and effective metabolic workout that will change the way you train', '2023-03-21', '07:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(95, 'EnergyCORE', 8, 'CORE', 'Focus on your core and all of you will benefit! Strengthen your middle and improve your posture with this fantastically focused workout.', '2023-03-21', '10:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(96, 'EnergyLITE', 7, 'LITE', 'A cardio class designed for all levels, this class has a mix of high and low intensity that burns calories and helps tone your body.', '2023-03-21', '15:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(97, 'PowerPump', 9, 'Strength', 'A weight-training workout designed to increase strength and endurance. With various equipment and exercises, this class will get you lifting like a pro!', '2023-03-21', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(98, 'SpinCycle', 10, 'Cycling', 'Get your heart pumping and your legs moving with this intense cycling workout. With music that will keep you motivated, you won’t even realize how hard you’re working!', '2023-03-21', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(99, 'KickBox', 1, 'Kickboxing', 'This high-energy class combines martial arts techniques with fast-paced cardio. With moves that range from punches to kicks, you’ll leave feeling like a total bad-ass!', '2023-03-22', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(100, 'BarreClass', 2, 'Barre', 'This ballet-inspired workout uses a combination of moves to tone and sculpt your entire body. With a focus on the core and legs, you’ll feel like a ballerina in no time!', '2023-03-22', '10:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(101, 'BootCamp', 4, 'Bootcamp', 'This military-style workout will push you to your limits! With a mix of cardio and strength training exercises, you’ll feel like a soldier by the end of it.', '2023-03-22', '15:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(102, 'YinYoga', 5, 'Yoga', 'This slow-paced form of yoga focuses on relaxation and stress-reduction. With a mix of gentle poses and deep breathing, you’ll leave feeling calm and centered.', '2023-03-22', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(103, 'PoundFit', 6, 'Drumming', 'This unique workout combines cardio, strength training, and drumming for a full-body workout that’s fun and effective. With drumsticks in hand, you’ll feel like a rockstar!', '2023-03-22', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(104, 'BodyPump', 3, 'Weight', 'A barbell workout that strengthens your entire body. This workout challenges all your major muscle groups by using the best weight-room exercises such as squats, presses, lifts and curls.', '2023-03-23', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(105, 'Spin', 8, 'Cycling', 'An indoor cycling class that is fun, low-impact and high-intensity. You’ll ride to upbeat music, while an experienced instructor leads you through hills, flats, intervals and jumps.', '2023-03-23', '10:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(106, 'TRX', 7, 'Functional Training', 'Suspension training using the TRX that develops strength, balance, flexibility and core stability simultaneously. It requires the use of the TRX Suspension Trainer, a highly portable performance training tool that leverages gravity and the user’s body weight to complete hundreds of exercises.', '2023-03-23', '15:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(107, 'BootCamp', 9, 'HIIT', 'An intense workout that is designed to get you in the best shape of your life. It combines strength training and cardio in one session and includes a mix of bodyweight exercises, weights, and cardio drills to help you build muscle and burn fat.', '2023-03-23', '17:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(108, 'Barre', 10, 'Barre', 'A ballet-inspired workout that targets your entire body. This workout combines the best of yoga, Pilates and ballet to give you a low-impact workout that tones your muscles and improves your flexibility.', '2023-03-23', '19:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(109, 'YinYoga', 1, 'Yoga', 'A slow-paced yoga class that focuses on breathing and holding poses for a longer period of time. This practice is designed to release tension and increase flexibility.', '2023-03-24', '07:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(110, 'PumpUp', 2, 'Weight', 'A total body workout using weights to tone and sculpt your muscles. Perfect for all fitness levels and a great way to build strength and confidence.', '2023-03-24', '10:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(111, 'SpinCycle', 4, 'Cycling', 'A high-intensity indoor cycling class that simulates outdoor riding. Burn calories and improve your cardiovascular fitness in this fun and challenging workout.', '2023-03-24', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(112, 'BarreBurn', 5, 'Barre', 'A ballet-inspired workout that targets your entire body, with a focus on the legs, glutes, and core. Improve your balance and flexibility while toning your muscles.', '2023-03-24', '17:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(113, 'BodyAttack', 6, 'Cardio', 'A high-energy, sports-inspired workout that combines aerobics, strength, and conditioning exercises. Improve your speed, agility, and coordination while burning calories.', '2023-03-24', '19:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(114, 'FlexFlow', 3, 'Flex', 'A class designed to improve your flexibility and range of motion. Incorporates stretching and mobility exercises to help you move better and feel better.', '2023-03-25', '07:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(115, 'Piloxing', 8, 'Pilates', 'A fusion of Pilates, boxing, and dance, this workout targets your core and improves your cardiovascular fitness. Sculpt your body and have fun in this unique class!', '2023-03-25', '10:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(116, 'BodyPump', 2, 'Weight ', 'A barbell workout that strengthens and tones your entire body. Suitable for all levels, this class will challenge you and help you achieve your fitness goals.', '2023-03-25', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(117, 'BodyPump', 5, 'Strength', 'Get lean, tone muscle, and work your entire body with this barbell-based workout.', '2023-03-25', '17:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(118, 'Spin', 1, 'Cycling', 'Experience the thrill of the ride with this indoor cycling class that simulates outdoor terrain and challenges your endurance.', '2023-03-25', '19:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(119, 'BodyCombat', 3, 'Combat', 'Kick, punch, and strike your way to a better body and improved cardiovascular fitness with this high-energy martial arts-inspired workout.', '2023-03-26', '07:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(120, 'Piloxing', 8, 'Piloxing', 'This fusion of Pilates and boxing will challenge your body and mind, and help you build lean muscle and improve your coordination.', '2023-03-26', '10:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(121, 'TRX', 2, 'Suspension', 'Use your own body weight and gravity to build strength, balance, flexibility, and core stability with this suspension training workout.', '2023-03-26', '15:00:00', 'studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(122, 'Yin Yoga', 5, 'Yoga', 'Relax, stretch, and release tension with this slow-paced style of yoga that focuses on holding poses for an extended period of time.', '2023-03-26', '17:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(123, 'Barre', 1, 'Barre', 'Shape, tone, and sculpt your body with this ballet-inspired workout that combines elements of Pilates, yoga, and strength training.', '2023-03-26', '19:00:00', 'studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(124, 'Zumba', 7, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-03-25', '07:00:00', 'studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(125, 'Barre', 9, 'Barre', 'This workout incorporates elements of ballet, Pilates, and yoga to create a full-body workout that strengthens, tones, and lengthens muscles.', '2023-03-25', '10:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(126, 'Spin', 4, 'Cardio', 'A high-intensity cycling class that simulates outdoor cycling on stationary bikes with fast-paced music to keep you motivated and engaged.', '2023-03-25', '15:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(127, 'Bootcamp', 5, 'Bootcamp', 'A challenging and intense workout that combines strength training and cardiovascular conditioning to improve your overall fitness level.', '2023-03-25', '19:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(128, 'Zumba', 7, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-03-26', '07:00:00','studio3', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(129, 'TRX', 9, 'Functional', 'A total body workout that uses suspension training to build strength, balance, flexibility, and core stability.', '2023-03-26', '10:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(130, 'Piloxing', 4, 'Piloxing', 'A fusion of Pilates, boxing, and dance that creates a full-body workout that burns calories, strengthens muscles, and improves flexibility.', '2023-03-26', '15:00:00','studio2', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(131, 'Yogalates', 6, 'Yogalates', 'A combination of yoga and Pilates that creates a holistic workout that strengthens muscles, improves flexibility, and promotes relaxation and stress reduction.', '2023-03-26', '19:00:00','studio1', 30);

INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(132, 'Pole Fitness', 2, 'Pole Fitness', 'A workout that combines dance, acrobatics, and strength training using a vertical pole to create a challenging and fun workout that strengthens muscles and improves flexibility.', '2023-03-26', '19:00:00',
 'studio3', 30);


INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(133, 'Pilates', 1, 'Pilates', 'Focus on your core with the core principles of Pilates! The eight principles of the Pilates technique – concentration, breath, centering, control, precision, movement, isolation and routine – are brought together to give you a low-impact workout that strengthens like nothing else.', '2023-03-13', '07:00:00', 'studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(134, 'Zumba', 6, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-03-13', '19:00:00','studio3', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(135, 'EnergyCORE', 8, 'CORE', 'Focus on your core and all of you will benefit! Strengthen your middle and improve your posture with this fantastically focused workout.', '2023-03-14', '10:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(136, 'PowerPump', 9, 'Strength', 'A weight-training workout designed to increase strength and endurance. With various equipment and exercises, this class will get you lifting like a pro!', '2023-03-14', '17:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(137, 'BootCamp', 4, 'Bootcamp', 'This military-style workout will push you to your limits! With a mix of cardio and strength training exercises, you’ll feel like a soldier by the end of it.', '2023-03-15', '15:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(138, 'Yin Yoga', 5, 'Yoga', 'Relax, stretch, and release tension with this slow-paced style of yoga that focuses on holding poses for an extended period of time.', '2023-03-15', '17:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(139, 'TRX', 7, 'Functional Training', 'Suspension training using the TRX that develops strength, balance, flexibility and core stability simultaneously. It requires the use of the TRX Suspension Trainer, a highly portable performance training tool that leverages gravity and the user’s body weight to complete hundreds of exercises.', '2023-03-16', '15:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(140, 'BootCamp', 9, 'HIIT', 'An intense workout that is designed to get you in the best shape of your life. It combines strength training and cardio in one session and includes a mix of bodyweight exercises, weights, and cardio drills to help you build muscle and burn fat.', '2023-03-16', '17:00:00','studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(141, 'Yin Yoga', 1, 'Yoga', 'Relax, stretch, and release tension with this slow-paced style of yoga that focuses on holding poses for an extended period of time.', '2023-03-17', '07:00:00','studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(142, 'BarreBurn', 5, 'Barre', 'A ballet-inspired workout that targets your entire body, with a focus on the legs, glutes, and core. Improve your balance and flexibility while toning your muscles.', '2023-03-17', '17:00:00', 'studio2', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(143, 'Zumba', 7, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-03-18', '07:00:00', 'studio3', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(144, 'BodyPump', 2, 'Weight ', 'A barbell workout that strengthens and tones your entire body. Suitable for all levels, this class will challenge you and help you achieve your fitness goals.', '2023-03-18', '15:00:00', 'studio1', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(145, 'BodyPump', 5, 'Strength', 'Get lean, tone muscle, and work your entire body with this barbell-based workout.', '2023-03-18', '17:00:00', 'studio3', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(146, 'Zumba', 7, 'Zumba', 'A dance sensation! This high-energy class combines Latin rhythm with easy-to-follow moves to deliver a one-of-a-kind fitness programme. With dancing like this, you won’t even realise you’re working out!', '2023-03-19', '07:00:00','studio3', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(147, 'Piloxing', 8, 'Piloxing', 'This fusion of Pilates and boxing will challenge your body and mind, and help you build lean muscle and improve your coordination.', '2023-03-19', '10:00:00', 'studio3', 30);
INSERT INTO group_exercise_sessions (session_id, title, trainer_id, category, description, start_date, start_time, location, max_space) VALUES
(148, 'Yogalates', 6, 'Yogalates', 'A combination of yoga and Pilates that creates a holistic workout that strengthens muscles, improves flexibility, and promotes relaxation and stress reduction.', '2023-03-19', '19:00:00','studio1', 30);


INSERT INTO group_sessions_bookings (bk_id, member_id, session_id, created_on) VALUES
(1, 1, 1, '2023-03-09 14:02:01'),
(2, 1, 2, '2023-03-09 14:02:04'),
(3, 2, 3, '2023-03-09 14:02:05'),
(4, 2, 4, '2023-03-09 14:02:07'),
(5, 3, 5, '2023-03-09 14:02:08'),
(6, 3, 6, '2023-03-09 14:02:09'),
(7, 3, 7, '2023-03-09 14:18:57'),
(8, 8, 122, '2023-03-16 14:08:09'),
(9, 5, 106, '2023-03-16 14:08:12'),
(10, 9, 122, '2023-03-16 14:08:13'),
(11, 10, 67, '2023-03-16 14:08:13'),
(12, 12, 67, '2023-03-16 14:08:13'),
(13, 7, 130, '2023-03-16 14:08:13'),
(14, 6, 130, '2023-03-16 14:08:13'),
(15, 11, 128, '2023-03-16 14:08:13'),
(16, 1, 133, '2023-03-11 14:02:01'),
(17, 2, 134, '2023-03-12 13:02:01'),
(18, 2, 135, '2023-03-12 19:02:45'),
(19, 3, 136, '2023-03-12 21:02:55'),
(20, 3, 137, '2023-03-14 14:02:01'),
(21, 4, 138, '2023-03-14 19:02:01'),
(22, 4, 139, '2023-03-15 14:02:01'),
(23, 5, 140, '2023-03-15 20:46:00'),
(24, 5, 141, '2023-03-15 22:00:02'),
(25, 6, 142, '2023-03-16 14:02:01'),
(26, 6, 143, '2023-03-17 09:02:51'),
(27, 7, 144, '2023-03-17 10:32:44'),
(28, 9, 145, '2023-03-17 14:55:30'),
(29, 7, 146, '2023-03-17 20:44:34'),
(30, 10, 147, '2023-03-18 09:22:25'),
(31, 12, 148, '2023-03-18 21:03:49');


INSERT INTO personal_training_bookings (pt_bk_id, trainer_id, member_id, duration, start_date, start_time, price, location, created_on, message) VALUES (1, 1, 1, 1, '2023-03-20', '09:00:00', 199, 'studio1', '2023-03-09 13:58:40', 'Looking forward to seeing you! :>');
INSERT INTO personal_training_bookings (pt_bk_id, trainer_id, member_id, duration, start_date, start_time, price, location, created_on, message) VALUES (2, 7, 2, 1, '2023-03-21', '18:00:00', 199, 'studio2', '2023-03-09 13:58:44', 'Looking forward to seeing you! :>');
INSERT INTO personal_training_bookings (pt_bk_id, trainer_id, member_id, duration, start_date, start_time, price, location, created_on, message) VALUES (3, 6, 3, 1, '2023-04-05', '16:00:00', 199, 'studio3', '2023-03-09 13:58:45', 'Looking forward to seeing you! :>');
INSERT INTO personal_training_bookings (pt_bk_id, trainer_id, member_id, duration, start_date, start_time, price, location, created_on, message) VALUES (4, 5, 1, 1, '2023-04-08', '16:00:00', 199, 'studio3', '2023-03-09 13:58:46', 'Looking forward to seeing you! :>');
INSERT INTO personal_training_bookings (pt_bk_id, trainer_id, member_id, duration, start_date, start_time, price, location, created_on, message) VALUES (5, 6, 14, 1, '2023-03-24', '16:00:00', 199, 'studio1', '2023-03-12 09:59:47', 'Looking forward to seeing you! :>');
INSERT INTO personal_training_bookings (pt_bk_id, trainer_id, member_id, duration, start_date, start_time, price, location, created_on, message) VALUES (6, 5, 13, 1, '2023-03-25', '18:00:00', 199, 'studio2', '2023-03-20 09:59:47', 'Looking forward to seeing you! :>');
INSERT INTO personal_training_bookings (pt_bk_id, trainer_id, member_id, duration, start_date, start_time, price, location, created_on, message) VALUES (7, 4, 12, 1, '2023-03-26', '16:00:00', 199, 'studio3', '2023-03-22 09:59:47', 'Looking forward to seeing you! :>');

INSERT INTO subscriptions (sub_id, member_id, startdatetime, end_datetime, is_active) VALUES
(1, 1, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(2, 2, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(3, 3, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(4, 4, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(5, 5, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(6, 6, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(7, 7, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(8, 8, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(9, 9, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(10, 10, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(11, 11, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(12, 12, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(13, 13, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1),
(14, 14, '2023-03-09 00:00:00', '2023-04-09 00:00:00', 1);




INSERT INTO messages (msg_id, sender_id, receiver_id, title, messages, type, `read`, sent_date_time) VALUES
(1, 1, 2, 'renew your membership', 'We hope this message finds you well and that you have been enjoying your workouts at our  We are reaching out to remind you that your membership is set to expire soon.

If you have not already done so, we encourage you to renew your membership to continue your fitness journey with us. We offer a variety of equipment, classes, and amenities to help you reach your fitness goals. We are fully committed to providing a safe and clean environment for our members.

To renew your membership, please visit our website or stop by the front desk. If you have any questions or concerns, please do not hesitate to reach out to our staff.', 'SUB', 1, '2023-03-09 14:09:02'),
(2, 1, 3, 'Personal training has been successfully booked', 'We are writing to confirm that your private training session with Samantha has been successfully booked for 12 April 2023 at 7am. We hope you are looking forward to your session and are excited to see the progress you will make in your fitness journey.

As a reminder, the cost of the session is $99. Payment can be made online through our website or at the front desk before your session. Please arrive at least 10 minutes before your scheduled session to allow time for check-in and to prepare for your workout.

If you need to reschedule or cancel your session, please notify us at least 24 hours in advance to avoid being charged for the session.

Thank you for choosing Lincoln Fitness for your fitness needs. We look forward to seeing you at your session and helping you achieve your goals.', 'PT', 1, '2023-03-09 14:09:06'),
(3, 2, 1, 'renew your membership', 'We hope this message finds you well and that you have been enjoying your workouts at our  We are reaching out to remind you that your membership is set to expire soon.

If you have not already done so, we encourage you to renew your membership to continue your fitness journey with us. We offer a variety of equipment, classes, and amenities to help you reach your fitness goals. We are fully committed to providing a safe and clean environment for our members.

To renew your membership, please visit our website or stop by the front desk. If you have any questions or concerns, please do not hesitate to reach out to our staff.', 'SUB', 0, '2023-03-09 14:09:07');

INSERT INTO payments (payment_id, amount, created_on, sub_id, pt_bk_id, pay_for) VALUES
(1, 99, '2023-03-09 14:20:03', 1, null, 'SUB'),

(2, 99, '2023-03-16 15:02:08', 2, null, 'SUB'),
(3, 99, '2023-03-16 15:02:09', 3, null, 'SUB'),
(4, 99, '2023-03-16 15:02:10', 4, null, 'SUB'),
(5, 99, '2023-03-16 15:02:11', 5, null, 'SUB'),
(6, 199, '2023-03-16 15:04:37', 1, 1, 'PT'),
(7, 199, '2023-03-16 15:04:37', 2, 2, 'PT'),
(8, 199, '2023-03-16 15:04:37', 3, 3, 'PT');



INSERT INTO attendances (attendance_id, member_id, created_on, using_gym_only, bk_id, pt_bk_id) VALUES
(1, 1, '2023-03-09 14:23:01', 1, null, null),
(2, 1, '2023-03-09 14:23:03', 1, null, null),
(3, 2, '2023-03-09 14:23:08', 1, null, null),
(4, 3, '2023-03-09 14:23:09', 1, null, null),
(5, 14, '2023-03-10 09:10:55', 1, null, null),
(6, 13, '2023-03-11 16:01:47', 1, null, null),
(7, 12, '2023-03-12 15:27:46', 1, null, null),
(8, 1, '2023-03-13 06:59:01', 0, 16, null),
(9, 2, '2023-03-13 18:58:02', 0, 17, null),
(10, 12, '2023-03-13 19:02:23', 1, null, null),
(11, 2, '2023-03-14 10:00:01', 0, 18, null),
(12, 3, '2023-03-14 14:58:01', 0, 19, null),
(13, 3, '2023-03-15 15:00:00', 0, 20, null),
(14, 4, '2023-03-15 16:57:59', 0, 21, null),
(15, 11, '2023-03-15 17:27:46', 1, null, null),
(16, 4, '2023-03-16 14:55:22', 0, 22, null),
(17, 5, '2023-03-16 16:56:58', 0, 23, null),
(18, 10, '2023-03-16 17:20:45', 1, null, null),
(19, 5, '2023-03-17 06:57:02', 0, 24, null),
(20, 6, '2023-03-17 16:57:02', 0, 25, null),
(21, 9, '2023-03-17 18:27:46', 1, null, null),
(22, 6, '2023-03-18 06:57:04', 0, 26, null),
(23, 7, '2023-03-18 14:58:45', 0, 27, null),
(24, 8, '2023-03-18 15:27:46', 1, null, null),
(25, 9, '2023-03-18 16:57:02', 0, 28, null),
(26, 7, '2023-03-19 06:57:46', 0, 29, null),
(27, 10, '2023-03-19 09:57:44', 0, 30, null),
(28, 7, '2023-03-19 17:27:46', 1, null, null),
(29, 12, '2023-03-19 18:58:23', 0, 31, null),
(30, 1, '2023-03-20 08:57:26', 0, null, 1),
(31, 6, '2023-03-20 16:22:04', 1, null, null),
(32, 5, '2023-03-21 07:59:22', 1, null, null),
(33, 2, '2023-03-21 17:50:29', 0, null, 2),
(34, 5, '2023-03-23 14:57:02', 0, 9, null),
(35, 10, '2023-03-23 15:34:22', 1, null, null),
(36, 14, '2023-03-24 15:49:45', 0, null, 5),
(37, 11, '2023-03-25 09:34:22', 1, null, null),
(38, 13, '2023-03-25 17:56:00', 0, null, 6),
(39, 11, '2023-03-26 06:55:05', 0, 15, null),
(40, 7, '2023-03-26 14:57:22', 0, 13, null),
(41, 6, '2023-03-26 14:58:00', 0, 14, null),
(42, 12, '2023-03-26 15:56:00', 0, null, 7),
(43, 8, '2023-03-26 16:55:57', 0, 8, null),
(44, 9, '2023-03-26 16:58:00', 0, 10, null),
(45, 2, '2023-03-26 19:34:22', 1, null, null);


ALTER TABLE trainer_schedules
ADD COLUMN day_name varchar(20)
GENERATED ALWAYS AS (
	CASE
WHEN day_of_week = '1' THEN 'Monday'
WHEN day_of_week = '2' THEN 'Tuesday'
WHEN day_of_week = '3' THEN 'Wednesday'
WHEN day_of_week = '4' THEN 'Thursday'
WHEN day_of_week = '5' THEN 'Friday'
WHEN day_of_week = '6' THEN 'Saturday'
WHEN day_of_week = '7' THEN 'Sunday'
ELSE 0
END) 
;