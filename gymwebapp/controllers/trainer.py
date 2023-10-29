from flask import Blueprint
from flask import render_template, session, abort
from models.all_users_func import *
from models.trainer_func import *


trainer_bp = Blueprint('trainer_bp', __name__)


@trainer_bp.before_request
def hook():
    if session.get('username') and user_exists(session['role'], session['username']):
        if session['role'] == "trainer":
             return 
    abort(401)


"-----------------------------VIEW PERSONAL TRAINING BOOKINGs------------------------------------------"


@trainer_bp.route('/viewbookings')
def getViewBookings():
    ptBookings = viewBookings()
    return render_template("trainer/viewbookings.html", ptBookings = ptBookings)