import connect
import mysql.connector

def getCursor():
    global dbconn
    global connection
    connection = mysql.connector.connect(user=connect.dbuser, \
    password=connect.dbpass, host=connect.dbhost, \
    database=connect.dbname, autocommit=True)
    dbconn = connection.cursor()
    return dbconn




def getMembers():
    connection = getCursor()
    connection.execute('SELECT * FROM users;')
    return connection.fetchall()


def viewBookings():
    connection = getCursor()
    connection.execute ("SELECT first_name, last_name, phone, members.member_id, personal_training_bookings.pt_bk_id, personal_training_bookings.trainer_id, \
                            personal_training_bookings.message, date_of_birth, health_record, introductions, start_date, start_time, location, price \
                            FROM members \
                            JOIN personal_training_bookings ON members.member_id = personal_training_bookings.member_id;")
    return connection.fetchall()


    