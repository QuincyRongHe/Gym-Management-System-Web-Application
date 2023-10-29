import connect
import mysql.connector
from datetime import datetime, timedelta

def getCursor():
    global dbconn
    global connection
    connection = mysql.connector.connect(user=connect.dbuser, \
    password=connect.dbpass, host=connect.dbhost, \
    database=connect.dbname, autocommit=True)
    dbconn = connection.cursor()
    return dbconn



def get_role(role):
    roles = ['admins', 'trainers', 'members']
    ind = roles.index(role+"s")
    return roles[ind]

    

def user_exists(role, username):
    """Checking if the user exists"""
    connection = getCursor()
    try:
        
        query = "SELECT * FROM {} WHERE username = '{}'".format(get_role(role), username)
        connection.execute(query)
        user = connection.fetchone()
        return True if user != None else False
    except:
        return False
    

         

def get_a_profile(role, username=None, id=None):
    connection = getCursor()

    if id != None:
        query = f"SELECT * FROM {role}s WHERE {role}_id = '{id}';"
    else:
        query = f"SELECT * FROM {role}s WHERE username = '{username}';"

    connection.execute(query)
    member = connection.fetchone()


    return member

def get_userID_by_username(role, username=None):
    connection = getCursor()
    

    query = f"SELECT {role}_id FROM {role}s WHERE username = '{username}';"


    connection.execute(query)
    id = connection.fetchone()
    return id


def get_sub_status(userID):
    connection = getCursor()
    query = f"SELECT is_active FROM subscriptions WHERE member_id={userID} ORDER BY startdatetime DESC;"

    connection.execute(query)

    status = connection.fetchone()

    if status == None:
        connection = getCursor()
        query = f"""INSERT INTO subscriptions (member_id, startdatetime, end_datetime, is_active) VALUES
                    ({userID}, '{datetime.today()}', '{datetime.today()+timedelta(weeks=4)}', {1});"""
        connection.execute(query)

        connection = getCursor()
        query = f"SELECT is_active FROM subscriptions WHERE member_id={userID} ORDER BY startdatetime DESC;"

        connection.execute(query)
        status = connection.fetchone()

    return status



def get_all_group_sessions_schedules():
    connection = getCursor()

    query = "SELECT title, trainer_id,category,description,  cast(concat(start_date, ' ', start_time) as datetime), location, session_id FROM group_exercise_sessions"
    connection.execute(query)

    schedules = connection.fetchall()
    return schedules

def get_a_group_session(class_id):

    connection = getCursor()

    query = f"SELECT * FROM group_exercise_sessions WHERE session_id={class_id}"
    connection.execute(query)

    session = connection.fetchone()
    trainer_id = session[2]

    return session, trainer_id

def space_left_of_a_group_session(class_id):
    
    connection = getCursor()
    defaultMax = 30
    query = f"SELECT COUNT(*) FROM group_sessions_bookings WHERE session_id={class_id}"
    connection.execute(query)

    booked = connection.fetchone()

    return defaultMax - booked[0]



def get_all_categories():

    connection = getCursor()

    query = "SELECT category FROM group_exercise_sessions"
    connection.execute(query)

    categories = connection.fetchall()
    return categories

    
def get_a_trainer_by_a_session(class_id):

    connection = getCursor()

    query = f"""SELECT * FROM group_exercise_sessions AS ges WHERE session_id={class_id} 
                        RIGHT JOIN trainers AS tr ON ges.trainer_id = tr.trainer_id"""
    connection.execute(query)

    session = connection.fetchone()
    return session



def update_user_profile(role, userID, data, isAdmin=False):
    connection = getCursor()

    if role == 'member':

        query = f'''UPDATE members
                    SET 
                    first_name = '{data['ftn']}', last_name = '{data['lsn']}',
                    gender = '{data['gender']}',
                    email = '{data['email']}',
                    house_number_name = '{data['house']}',
                    street = '{data['street']}',
                    town = '{data['town']}',
                    city = '{data['city']}',
                    post_code = '{data['pcode']}',
                    phone = '{data['phone']}',
                    introductions = '{data['intro']}',
                    emergency_contact_person = '{data['emp']}',
                    emergency_contact_phone = '{data['empct']}',
                    weight = '{data['weight']}',
                    height = '{data['height']}',
                    health_record = '{data['health']}'
                    
                    WHERE member_id = {userID};'''
    elif role == 'trainer':

        query = f'''UPDATE trainers
                    SET 
                    first_name = '{data['ftn']}', last_name = '{data['lsn']}',
                    gender = '{data['gender']}',
                    email = '{data['email']}',
                    house_number_name = '{data['house']}',
                    street = '{data['street']}',
                    town = '{data['town']}',
                    city = '{data['city']}',
                    post_code = '{data['pcode']}',
                    phone = '{data['phone']}',
                    qualifications = '{data['qual']}',
                    speciality = '{data['spec']}',
                    biography = '{data['bio']}'
                    WHERE trainer_id = {userID};'''
    elif role == 'admin':
        query = f'''UPDATE admins
                    SET 
                    first_name = '{data['ftn']}', 
                    last_name = '{data['lsn']}',
                    email = '{data['email']}'
                    WHERE admin_id = {userID};
'''

    connection.execute(query)

    if isAdmin and role == 'member':

        query = f" UPDATE subscriptions SET is_active={data['subStatus']} WHERE member_id = {userID};"
        print(query)
        connection.execute(query)
    
    return 200
        
    


def trainer_schedule_on_specific_date(trainer_id, dayofWeek, date):
    
    connection = getCursor()
    query = f"SELECT * FROM trainer_schedules WHERE trainer_id = {trainer_id} and day_of_week = {dayofWeek};"

   


    connection.execute(query)
    ts = connection.fetchall()

    connection = getCursor()

    query = f"SELECT start_time, title, session_id, location FROM group_exercise_sessions WHERE trainer_id = {trainer_id} and start_date = '{date}';"
    # print(f"{query} !")

    connection.execute(query)
    ss = connection.fetchall()

    connection = getCursor()

    query = f"SELECT start_time, location FROM personal_training_bookings WHERE trainer_id = {trainer_id} and start_date = '{date}';"

    connection.execute(query)
    pt = connection.fetchall()

    

    # print(f"{ts}--> {ss}--> {pt} !")

    return ts, ss, pt


def get_all_trainers_name():
    connection = getCursor()
    query = "SELECT trainer_id, concat(first_name, ' ', last_name) as name FROM trainers;"
    connection.execute(query)
    return connection.fetchall()

def user_has_booked_this_class(class_id, userID):
    connection = getCursor()
    query = f'SELECT COUNT(*) FROM group_sessions_bookings WHERE member_id = {userID} and session_id = {class_id}'
    connection.execute(query)
    result = connection.fetchone()
    
    if result[0]:
        print(result)
        return True
    return False


