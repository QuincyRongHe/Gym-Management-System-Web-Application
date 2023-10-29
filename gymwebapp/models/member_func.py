#from models.cursor import getCursor
import connect
import mysql.connector
from models.all_users_func import get_sub_status


#I could only get this to work in the same python file as the functions? 
def getCursor():
    global dbconn
    global connection
    connection = mysql.connector.connect(user=connect.dbuser, \
    password=connect.dbpass, host=connect.dbhost, \
    database=connect.dbname, autocommit=True)
    dbconn = connection.cursor()
    return dbconn

#import SQL data to python from memmber table
def getMembers():
    connection = getCursor()
    connection.execute('SELECT * FROM members;')
    return connection.fetchall()

    
def book_class(class_id, user_id, date):
    connection = getCursor()
    query = f"""INSERT INTO group_sessions_bookings (member_id, session_id, created_on) 
    VALUES ('{user_id}', '{class_id}', '{date}');"""

    connection.execute(query)
    
    return 200


def get_all_trainers():
    connection = getCursor()
    query = "SELECT * from trainers;"
    connection.execute(query)
    return connection.fetchall()

    
def memberViewBookings():
    connection = getCursor()
    connection.execute ("SELECT members.first_name, members.last_name, members.member_id, trainers.trainer_id, trainers.first_name, trainers.last_name, \
                        personal_training_bookings.pt_bk_id, personal_training_bookings.start_date, personal_training_bookings.start_time, personal_training_bookings.location \
                        FROM members \
                        JOIN personal_training_bookings ON members.member_id = personal_training_bookings.member_id \
                        JOIN trainers ON personal_training_bookings.trainer_id = trainers.trainer_id \
                        ORDER BY personal_training_bookings.start_date ASC, personal_training_bookings.start_time;")
    return connection.fetchall()


def get_sub_by_member(userID):
    connection = getCursor()
    query = f"select startdatetime, end_datetime, is_active from subscriptions where member_id = '{userID}' ORDER BY startdatetime DESC;"
    connection.execute(query)
    result = connection.fetchall()

    
    return result

def get_group_sessions_by_member(userID, date=None):
    connection = getCursor()
    query = f"""select t.trainer_id, title, CONCAT(t.first_name, t.last_name), ges.category, ges.start_date, ges.start_time, ges.location, ges.session_id 
                FROM group_sessions_bookings AS gsb 
                JOIN group_exercise_sessions AS ges ON gsb.session_id=ges.session_id 
                JOIN trainers AS t ON ges.trainer_id=t.trainer_id 
                WHERE member_id = {userID}"""
    query += f" and ges.start_date >= '{date}'" if date else ""
    query += f" ORDER BY ges.start_date ASC, ges.start_time ASC;"
    
    connection.execute(query)
    result = connection.fetchall()
    print(result)
    
    return result

def get_pt_session_by_member(userID, date=None):
    connection = getCursor()
    query = f"""select t.trainer_id, CONCAT(t.first_name, t.last_name), ptb.start_date, ptb.start_time, ptb.location, ptb.message
                FROM personal_training_bookings AS ptb 
                JOIN trainers AS t ON  ptb.trainer_id=t.trainer_id 
                WHERE member_id = {userID}"""
  
    query += f" and ptb.start_date >= '{date}'" if date else ""
    query += f" ORDER BY ptb.start_date ASC, ptb.start_time ASC;"
    print(query)
    connection.execute(query)
    result = connection.fetchall()
    
    return result
def get_messages_by_member(userID):
    connection = getCursor()
    query = f"select msg_id, title, messages, messages.read, sent_date_time, type, sender_id, receiver_id FROM messages WHERE receiver_id = {userID} ORDER BY sent_date_time DESC;"
    
    connection.execute(query)
    result = connection.fetchall()
    print("msgs", result)
    
    return result

def archive_a_message(msg_id):
    connection = getCursor()
    query = f"UPDATE messages SET messages.read=1 WHERE msg_id={msg_id}"

    connection.execute(query)

def unread_a_message(msg_id):
    connection = getCursor()
    query = f"UPDATE messages SET messages.read=0 WHERE msg_id={msg_id}"

    connection.execute(query)


def book_a_pt(member_id, trainer_id, start_date, start_time, location, created_on):
    connection = getCursor()
    query = f"""INSERT INTO personal_training_bookings 
                (trainer_id, member_id, duration, start_date, start_time, price, location, created_on) 
                VALUES
                ('{trainer_id}', '{member_id}', 1, '{start_date}', '{start_time}', 80, '{location}', '{created_on}')
            """

    connection.execute(query)

def getTrainerSchedule():
    connection = getCursor()
    connection.execute ("SELECT trainer_schedules.trainer_id, trainer_schedules.start_time, trainer_schedules.end_time, group_exercise_sessions.start_date, group_exercise_sessions.start_time, trainer_schedules.day_name \
                        FROM group_exercise_sessions \
                        JOIN trainer_schedules ON trainer_schedules.trainer_id = group_exercise_sessions.trainer_id AND DAYNAME(start_date) = trainer_schedules.day_name")
    return connection.fetchall()
    

# def get_messages_by_member(member_id):

#     connection = getCursor()
#     connection.execute (
#     f"""
    
#     SELECT msg_id, sender_id, receiver_id, title, messages, type, messages.read, sent_date_time
#     FROM messages
#     WHERE 
#     receiver_id = {member_id};
#     """)
#     return connection.fetchall()
    
def get_a_message_by_id(msg_id):

    connection = getCursor()
    connection.execute (
    f"""
    
    SELECT msg_id, sender_id, receiver_id, title, messages, type, messages.read, sent_date_time
    FROM messages
    WHERE 
    msg_id = {msg_id};
    """)
    return connection.fetchone()


