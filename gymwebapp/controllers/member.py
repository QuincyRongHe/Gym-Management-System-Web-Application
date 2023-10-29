from flask import Blueprint, url_for
from json import dump;import json
from flask import render_template, request,session, Response, abort, redirect
from datetime import datetime
from models.member_func import *
from models.all_users_func import *

member_bp = Blueprint('member_bp', __name__)


@member_bp.before_request
def hook():
    # request - flask.request
    if session.get('username') and user_exists(session['role'], session['username']):
        if session['role'] == "member":
             return
    abort(401)


"-----------------------------VIEW_TRAINERS------------------------------------------"

"""
- View all trainers
- View one trainer
"""

@member_bp.route('/view_trainers')
@member_bp.route('/view_trainer/<int:trainer_id>')
def viewTrainers(trainer_id = None):

    if trainer_id:
        trainer = get_a_profile(role='trainer', id=trainer_id)

        return render_template('member/view_one_trainer.html', trainer = trainer)
    
    trainer_list = get_all_trainers()

    return render_template("member/view-trainers.html", trainerList = trainer_list)


"-----------------------------BOOKINGS------------------------------------------"

"""
Make a Booking for group exercises classes
"""

@member_bp.route("/bookclass/<int:id>", methods=['GET', 'POST'])
def bookClass(id):
    book_class(id, session['userID'], datetime.today())

    return redirect(f'/class/{id}')


"""
Make a booking for Personal training Session
interact with ajax
"""

@member_bp.route('/bookpt',  methods=['GET', 'POST'])      
def bookpt():

    event = request.get_json()
    print(event)


    member_id = session['userID']
    trainer_id = event['trainer_id']

    start = datetime.strptime(event['start'], '%d/%m/%Y, %I:%M:%S %p')

    start_date = start.date()
    start_time = start.time()
    location = 'studio3'
    if event['location'] == 'a':
        location = 'studio1'
    elif event['location'] == 'b':
        location = 'studio2'
    created_on = datetime.today()

    print(member_id, trainer_id, location, start_date,start_time,created_on, event['location'], event['location']=='a')


    book_a_pt(member_id, trainer_id, start_date, start_time, location, created_on)

    print("successfully added a new pt session!")
  

    return json.dumps({'success':True}), 200, {'ContentType':'application/json'} 




"-----------------------------MESSAGING------------------------------------------"

"""
Mark a message as read or unread based on its current state
"""

@member_bp.route('/archive/<int:msg_id>/<redir>/<int:isRead>', methods=["GET"])      
def archiveMessage(msg_id, redir, isRead):


    print(msg_id, redir, isRead)


    if redir == 'inbox':
        redir = f'/inbox/{msg_id}'
    elif redir == 'home':
        redir = '/'

    if isRead:
        unread_a_message(msg_id)
    else:
        archive_a_message(msg_id)
        
    

    return redirect(url_for('member_bp.viewInbox', msg_id=msg_id))

        
"""
- Check inbox
- chack individual message
"""


@member_bp.route('/inbox')
@member_bp.route('/inbox/<int:msg_id>')
def viewInbox(msg_id=None):
    if msg_id:
        msg = get_a_message_by_id(msg_id)

        print(msg)

        return render_template('member/inbox.html', msg=msg)
    
    msgs = get_messages_by_member(session['userID'])
    print(msgs)


    return render_template('member/inbox.html', msgs=msgs)
    
    

# RESERVED For Ruby

# #view report page
# @member_bp.route('/memberviewbookings')
# def getMemberBookings():
#     return renderMemberBookings(False, False, False)

# def renderMemberBookings(doubleBooked, trainerUnavailable, wasFormSubmitted):
#     currentBookings = memberViewBookings()
#     trainers = get_all_trainers()
#     schedules = getTrainerSchedule()
#     return render_template("memberviewbookings.html", currentBookings = currentBookings, trainers = trainers, doubleBooked = doubleBooked, trainerUnavailable = trainerUnavailable, wasFormSubmitted = wasFormSubmitted, schedules = schedules)




# #form nane for booking a pt session
# @member_bp.route('/member/bookpt', methods=["POST"])
# def memberbookPT():
#     #variables from the form
#     addMemberId = request.form.get('member')
#     addTrainerId = request.form.get('trainer')
#     addDuration = request.form.get('duration')
#     addDate = request.form.get('date')
#     addTime = request.form.get('time')
#     addLocation = request.form.get('location')
#     #check database for if available
#     connection = getCursor()
#     checksql = "SELECT trainer_id, start_date, start_time  \
#             FROM personal_training_bookings \
#             WHERE trainer_id = %s and start_date = %s and start_time = %s " 
#     checkparameters = (addTrainerId, addDate, addTime)
#     connection.execute(checksql, checkparameters)
#     results_double_booking = connection.fetchall()

#     #check if result is in the trainer scheduled hours 
#     schedules = getTrainerSchedule()
#     for value in schedules:
#         if addTrainerId == str(value[0]) and addDate == str(value[3]):
#             if addTime == str(value[4]):
#                 results_trainer_schedule = 1
#             else:
#                 if addTime >= str(value[1]) and addTime < str(value[2]):
#                     results_trainer_schedule = 0
#                 else:
#                     results_trainer_schedule = 1
#         else:
#             results_trainer_schedule = 1
#     # results_trainer_schedule = 0
#     #enter into database if time is available
#     if len(results_double_booking) == 0 and results_trainer_schedule == 0:
#         connection = getCursor()
#         sql ="Insert into personal_training_bookings (trainer_id, member_id, duration, start_date, start_time, location) VALUES (%s,%s,%s,%s,%s,%s)"
#         parameters = (addTrainerId, addMemberId, addDuration, addDate, addTime, addLocation)
#         print(f'added successfully with details: {parameters}')
#         connection.execute(sql, parameters)

#         return renderMemberBookings(False, False, True)
#     elif len(results_double_booking) != 0 and results_trainer_schedule == 0:
#         return renderMemberBookings(True, False, True)
#     elif len(results_double_booking) == 0 and results_trainer_schedule != 0:
#         return renderMemberBookings(False, True, True)
#     else:
#         return renderMemberBookings(True, True, True)