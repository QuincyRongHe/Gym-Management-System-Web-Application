
import connect
import mysql.connector
from pyecharts import options as opts
from pyecharts.charts import Pie, Timeline, Line

def getCursor():
    global dbconn
    global connection
    connection = mysql.connector.connect(user=connect.dbuser, \
    password=connect.dbpass, host=connect.dbhost, \
    database=connect.dbname, autocommit=True)
    dbconn = connection.cursor()
    return dbconn


# def user_exists(username):
#     connection = getCursor()
#     connection.execute("SELECT * FROM admins WHERE username = {}".format(username))
#     user = connection.fetchone()
#     return True if len(user) != 0 else False

def createdb():
    connection = getCursor()

def get_all_members():
    connection = getCursor()
    query = "SELECT member_id, concat(first_name, ' ',last_name) as name, username, email, phone FROM members;"
    connection.execute(query)
    members = connection.fetchall()
    return members


def dbsearch_members(keyword):
    connection = getCursor()
    query = "SELECT member_id, concat(first_name, ' ',last_name) as name, username, email, phone FROM members WHERE concat(first_name, ' ',last_name) like '%{}%';".format(keyword)
    connection.execute(query)
    # print(query)
    
    members = connection.fetchall()
    # print(members)
    return members

def pay_for(pt_id, group_id, price):

    pass

    


def dbadd_new_member(data, start, end):
    connection = getCursor()

    query_keys = f"INSERT INTO members ( username"
    query_values = f" VALUES ( '{data['username']}'" 
    username = data.pop('username', None)
    subStatus = data.pop('subStatus', None)

    for key, value in data.items():
        if value not in ['', None]:
            query_keys += f', {key}'
            query_values += f', "{value}"'
    query_keys += " )"
    query_values += " );"

    query = query_keys + query_values

    print(query)
    
    connection.execute(query)

    print("New Member created!")

    connection = getCursor()

    query = f"SELECT member_id from members WHERE username = '{username}'"
    connection.execute(query)

    user_id = int(connection.fetchone()[0])

    print(f"user id is: {user_id}")

    connection = getCursor()

    query = f'''INSERT INTO subscriptions (member_id,  startdatetime, end_datetime, is_active) 
                VALUES ({user_id}, '{start}', '{end}', {subStatus});'''
    
    connection.execute(query)
    print("New subscription created!")
    
    

    

    
    
def dbget_reports(fromDate, toDate):
    query = "SELECT SUM(amount) as total_amount, SUM(CASE WHEN pay_for='SUB' THEN amount ELSE 0 END) as sub_amount,SUM(CASE WHEN pay_for='PT' THEN amount ELSE 0 END) as pt_amount FROM payments WHERE created_on BETWEEN '{}' AND '{}';".format(fromDate, toDate)
    connection = getCursor()
    connection.execute(query) 
    reports = connection.fetchall()
    return reports

def get_pie() -> Timeline:
    connection = getCursor()
    query = """
        SELECT
            group_exercise_sessions.title AS class,
            COUNT(attendances.attendance_id) AS cnt,
            DATE_FORMAT(DATE_SUB(attendances.created_on, INTERVAL WEEKDAY(attendances.created_on) DAY), '%d-%m-%Y') AS week_start
        FROM
            attendances
            RIGHT JOIN group_sessions_bookings ON group_sessions_bookings.bk_id = attendances.bk_id
            RIGHT JOIN group_exercise_sessions ON group_exercise_sessions.session_id = group_sessions_bookings.session_id
        WHERE
            attendances.created_on >= DATE(NOW()) - INTERVAL 8 WEEK
        GROUP BY
            group_exercise_sessions.title, week_start
        ORDER BY
            week_start ASC;
    """
    connection.execute(query)
    datas = connection.fetchall()
    tl = Timeline()
    pie_data = {}
    for i in range(len(datas)):
        data = datas[i]
        week_start = data[2]
        if week_start not in pie_data:
            pie_data[week_start] = []
        pie_data[week_start].append((data[0], data[1]))
    
    for week_start, data in pie_data.items():
        pie = (
            Pie()
            .add(
                "",
                data,
                rosetype = "radius",
                radius=["40%", "70%"]
            )
            .set_global_opts(
                title_opts=opts.TitleOpts(title="Group Exercise Sessions Attendance - {}".format(week_start)),
                legend_opts=opts.LegendOpts(
                    type_="scroll", pos_top="10%", pos_left="80%", orient="vertical"
                )
            )
            .set_series_opts(label_opts=opts.LabelOpts(formatter="{b}: {c}"))
        )
        tl.add(pie, "{}".format(week_start))
    
    return tl



def get_line() -> Line:
    connection = getCursor()
    query = """
            SELECT DATE_FORMAT(created_on, '%d-%m-%Y') AS created_date,
       COUNT(CASE WHEN using_gym_only = 1 THEN 1 END) AS using_gym_only_count,
       COUNT(bk_id) AS bk_id_count,
       COUNT(pt_bk_id) AS pt_bk_id_count
FROM attendances
GROUP BY DATE_FORMAT(created_on, '%d-%m-%Y');
        """
    connection.execute(query)
    datas = connection.fetchall()
    tl = Timeline()
    c = (
        Line()
        .add_xaxis([str(data[0]) for data in datas])
        .add_yaxis("using gym only", [data[1] for data in datas])
        .add_yaxis("group exercise class", [data[2] for data in datas])
        .add_yaxis("personal training session", [data[3] for data in datas])
        .set_global_opts(title_opts=opts.TitleOpts(title="All gym attendance"))
        )
    return c

def send_message_to(sender_id, receiver_id, data):
    connection = getCursor()

    query = f"INSERT INTO messages (sender_id, receiver_id, title, messages, type, messages.read, sent_date_time) VALUES ({sender_id}, {receiver_id}, '{data['title']}', '{data['msg']}', '{data['type']}', 0, '{data['sent']}');"
    connection.execute(query)