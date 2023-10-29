from json import dump;import json
from datetime import datetime, timedelta, date
import datetime as dt
from flask import Blueprint, render_template, request, jsonify, session, redirect,abort, request
from models.all_users_func import *
from models.member_func import *


all_users_bp = Blueprint('all_users_bp', __name__)


"""
Functions below are for each member to log in to the web app 
& have the right data pulled from database
"""
@all_users_bp.before_request
def hook():
    guest_paths = ['/', '/login']  
    path = request.path
    if path in guest_paths:
        return
    elif session.get('username') and user_exists(session['role'], session['username']):
         return 
    abort(401)

"-----------------------GUEST PORTAL ------------------------------"
@all_users_bp.route('/')

def home():

    if session.get("username"):
        return redirect("/dashboard")

    return render_template("base.html")

@all_users_bp.route('/login', methods = ['POST', 'GET'])
def login():
    
    print("logging in")

    role = request.form['role']
    username = request.form['username']

    if user_exists(role, username):
        session['username'] = username
        session['role'] = role
        id = get_userID_by_username(role, username=username)[0]
        session['userID'] = id
        session['subStatus'] = get_sub_status(id)
        return json.dumps({'success':True}), 200, {'ContentType':'application/json'} 
    
    else:
        return "The user doesn't exist, please check if you have ticked a wrong role and incorrect username!"
    
"-----------------------------------All logged-in USERS PORTAL------------------------------------"

"""
Log out the current user and delete all 
data saved when the user was logged in

"""

@all_users_bp.route('/logout')
def logout():
        
    session.pop('username', None)
    session.pop('role', None)
    session.pop('userID', None)
    session.pop('subStatus', None)
    return redirect("/", code=302)



"""
Shows infomation relevant to the current logged in users
Group session, Personal Trainings, subscription dexpiry, messages, etc.

"""
@all_users_bp.route('/dashboard')
def dashboard():
    userId = session["userID"]

    if session['role'] == 'member':
        subs = get_sub_by_member(userID=userId)
        groups = get_group_sessions_by_member(userID=userId, date=datetime.today().date())
        pts = get_pt_session_by_member(userID=userId, date=datetime.today().date())
        msgs = get_messages_by_member(userID=userId)
        print("PTS:", pts)

        return render_template("base.html", sub=subs[0], groups =groups, pts=pts, msgs=msgs)
    
    return render_template("base.html")
    



"-----------------------------------MY PROFILE------------------------------------"

"""
Retrieve details of current users and show them in the Front end

"""
@all_users_bp.route('/myprofile')
def myprofile():

    user = get_a_profile(session['role'], session['username'] )
    #bmi calculation
    if session['role'] == 'member':
        bmi = int((float(user[17]) / float(user[18])**2) * 10000)
        return render_template("all_users/myprofile.html", user=user, bmi=bmi)


    
    return render_template("all_users/myprofile.html", user=user)

"""
return a view current user can make changes of their profile.
"""

@all_users_bp.route('/myprofile/update')
def updateMyprofile():
    return render_template("all_users/update_myprofile.html")


"""
Save updates for my profile
"""
@all_users_bp.route('/myprofile/update/save', methods = ['POST', 'GET'])
def saveUpdateMyprofile():

    data = dict()

    data['ftn'] = request.form.get("fname")
    data['lsn'] = request.form.get("lname")
    data['gender'] = request.form.get("gender")
    data['email'] = request.form.get("email")

    if session['role'] != 'admin':
        data['house'] = request.form.get("house")
        data['street'] = request.form.get("street")
        data['town'] = request.form.get("town")
        data['city'] = request.form.get("city")
        data['pcode'] = request.form.get("postcode")
        data['phone'] = request.form.get("phone")

    if session['role'] == 'member':

        data['intro'] = request.form.get("introduction")
        data['height'] = request.form.get("height")
        data['weight'] = request.form.get("weight")
        data['health'] = request.form.get("health_record")
        data['emp'] = request.form.get("emergent_person")
        data['empct'] = request.form.get("emergent_person_phone")
        

    if session['role'] == 'trainer':
        data['qual'] = request.form.get("qualification")
        data['spec'] = request.form.get("speciality")
        data['bio'] = request.form.get("biography")


    update_user_profile(session['role'],session['userID'], data)

    return redirect('/myprofile')

"-----------------------------------CALENDAR VIEW------------------------------------"


"""

GROUP EXERCISES SESSIONS

retrieve all calsses to front end and present in a calendar view (FullCalendar.io)

"""

#Functions below enable all users to look at the calendar
@all_users_bp.route('/all_classes' )
def view_classes_calendar():

    def process_row(row):
    # func which returns a dictionary like:
    # '2010-01-09T12:30:00'
        id = row[6]
        location = 'c'
        if row[5] == "studio1":
            location = 'a'
        elif row[5] == "studio2":
            location = 'b'
        return dict (title = row[0],
                     start = row[4].strftime("%Y-%m-%dT%H:%M:%S"),
                     end = (row[4]+ timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%S"),
                     resourceId = location,
                     url = f"/class/{id}",
                     extendedProps=dict(
                                        description = row[3]
            
                     )

                 )
    
    sessions = get_all_group_sessions_schedules()

    events = [process_row(session) for session in sessions]

    

    eventsjson = json.dumps(events, indent=4)

    # print(eventsjson)

    return render_template("all_users/view_classes_calendar.html", events=eventsjson)


"""
Shows one class

"""

@all_users_bp.route('/class/<int:class_id>')
def showaclass(class_id):

    classDetails, trainerID = get_a_group_session(class_id)

    trainer = get_a_profile('trainer', id =trainerID)

    spaceLeft = space_left_of_a_group_session(class_id)

    booked = user_has_booked_this_class(class_id, session['userID'])

    today = datetime.today().date()

    
    return render_template("all_users/view_oneclass.html", classDetails=classDetails, trainer=trainer, spaceLeft=spaceLeft, booked=booked, today=today)


"""
PERSONAL TRAINING SESSIONS

- Shows a dropdown box for user to choose a trainer to view
- View the available timeframe of one trainer by greying out their unavailable time on the calendar. 
    (e.g. grey out their group sessions, personal training sessions, and off time)
- Shows up to 14 days ahead

"""
@all_users_bp.route('/trainer-schedule')

@all_users_bp.route('/trainer-schedule/<int:trainer_id>')

def showTrainersSchedules(trainer_id = None):
    """Assume it can only book up to 14 days ahead"""


    # def less_class(ts, ss):
    # # func which returns a dictionary like:
    # # '2010-01-09T12:30:00'

    #     newlist = ts

    #     while ss:
    #         session = ss.pop(0)
    #         ssstart, ssend = session[0], session[0]+timedelta(hours=1)
    #         for t in newlist:
    #             tstart, tend = t[2], t[3]
                

    #             if tstart == ssstart:

    #                 newlist.append((t[0], t[1], (datetime.datetime.min + ssend).time(), tend, t[4]))

    #                 newlist.pop(newlist.index(t))
    #             elif tstart < ssstart and tend > ssstart:
    #                 newlist.append((t[0], t[1], tstart, ssstart, t[4]))
    #                 if ssstart+timedelta(hours=1) < tend:
    #                     newlist.append((t[0], t[1], ssstart+timedelta(hours=1), tend, t[4]))
    #                 newlist.pop(newlist.index(t))
    #             print(f'(in for loop) t = {t}, list = {newlist}')
        
    #     return newlist
    
    def less_bh(bh, ts):


        newlist = bh

        while ts:
            schedule = ts.pop(0)
            tstart, tsend = schedule[2], schedule[3]
            for b in newlist:
                bstart, bend = b[0], b[1]
                
                if bstart < tstart:

                    newlist.append((bstart, tstart))
                if bend > tsend:
                    newlist.append((tsend, bend))

                newlist.pop(newlist.index(b))

                print(f'(in for loop) b = {b}, list = {newlist}')
        
        return newlist
    
    def process_row(row, date, isPT=False, isTS=False, dayOff=False, loc=None, occupied=False):

        if dayOff:
            return dict (
                        start = date.strftime('%Y-%m-%dT00:00:00'),
                        allDay = 'True',
                        backgroundColor='#808080',

                        display= 'background',

                    )




        nt = (dt.datetime.min + row[0]).time()
        newdt = dt.datetime.combine(date, nt)

        

        

        if isTS:

            enddt = (dt.datetime.min + row[1]).time()
            enddt = dt.datetime.combine(date, enddt)
            enddt = enddt.strftime("%Y-%m-%dT%H:%M:%S")

            return dict (
                        start = newdt.strftime("%Y-%m-%dT%H:%M:%S"),
                        end = enddt,
                        backgroundColor='#808080',

                        display= 'background',

                    )

        location = 'c'
        if loc == "studio1":
            location = 'a'
        elif loc == "studio2":
            location = 'b'
        

        if occupied:

            return dict (
                    start = newdt.strftime("%Y-%m-%dT%H:%M:%S"),
                    end = (newdt+ timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%S"),

                    resourceId = location,
                    backgroundColor='#808080',
                    display= 'background',
                    
                    )


        if not isPT:

            
            return dict (title = row[1],
                        start = newdt.strftime("%Y-%m-%dT%H:%M:%S"),
                        end = (newdt+ timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%S"),
                        url = f"/class/{row[2]}",
                        resourceId = location,
                        


                    )
        
            
        
        

        return dict (title = "Personal Training",
                    start = newdt.strftime("%Y-%m-%dT%H:%M:%S"),
                    end = (newdt+ timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%S"),

                    resourceId = location,

                    
                    )
    
        
    timetable = []
    period = 15
    
    if trainer_id != None:
        currentday = date.today()
        lastday = currentday + timedelta(days=period)
        day = currentday.isoweekday()
        
        
        while( currentday <= lastday):

            

            print(f'current = {currentday} {day}')


            ts, ss, pt = trainer_schedule_on_specific_date(trainer_id, day, currentday)
            

            for s in ss:
                locs = ['studio1', 'studio2', 'studio3']

                timetable.append(process_row(s, date=currentday, loc=s[3]))

                locs.remove(s[3])

                for loc in locs:
                    timetable.append(process_row(s, date=currentday, isPT=False, loc=loc, occupied=True))


            for p in pt:
                timetable.append(process_row(p, date=currentday, isPT=True, loc=p[1]))

                locs = ['studio1', 'studio2', 'studio3']
                locs.remove(p[1])

                for loc in locs:
                    timetable.append(process_row(p, date=currentday, isPT=True, loc=loc, occupied=True))

 

            if len(ts) == 0:
                timetable.append(process_row(ts, date=currentday, dayOff=True))
            else:
                t = datetime.strptime("06:00:00","%H:%M:%S")
                delta = timedelta(hours=t.hour, minutes=t.minute, seconds=t.second)
                t = datetime.strptime("20:00:00","%H:%M:%S")
                delta2 = timedelta(hours=t.hour, minutes=t.minute, seconds=t.second)
                bh = [(delta, delta2)]
                ts = less_bh(bh, ts)
                for t in ts:
                    timetable.append(process_row(t, date=currentday, isTS=True))


            # print(f' Original: {ts}')
            # new_ts = less_class(ts, ss)
            # for i in new_ts:
            #     print(f' New afte less class: {i[2]} {i[3]}')
            # new_ts = less_class(new_ts, pt)
            # for i in new_ts:
            #     print(f' New after less pt: {i[2]} {i[3]}')
            # print("\n")

            currentday += timedelta(days=1)
            day = currentday.isoweekday()

    print(timetable)

    current_trainer_name = None
    if trainer_id:
        current_trainer= get_a_profile('trainer', id=trainer_id)
        fname = current_trainer[3]
        lname = current_trainer[4]
        current_trainer_name = f"{fname} {lname}"

    
    today = date.today()
    end = today+timedelta(days=period)




    return render_template("all_users/trainer_schedule.html", 
                           timetable=timetable, 
                           trainer_list=get_all_trainers_name(), 
                           name = current_trainer_name, 
                           trainer_id=trainer_id,
                           start_date = today,
                           end_date = end)
