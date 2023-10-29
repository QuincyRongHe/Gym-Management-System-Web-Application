from flask import Flask, render_template, request,session
from controllers.member import member_bp
from controllers.trainer import trainer_bp
from controllers.admin import admin_bp
from controllers.all_users import *
from socket import gethostname
import babel
import datetime as dt

app = Flask(__name__)

app.secret_key = 'the random string'

app.register_blueprint(all_users_bp)
app.register_blueprint(member_bp)
app.register_blueprint(trainer_bp)
app.register_blueprint(admin_bp)

@app.template_filter()
def nz_date(value):

    return value.strftime('%d-%m-%Y')

@app.template_filter()
def time(value):

    actual_time = (dt.datetime.min + value).time()

    return actual_time.strftime('%I:%M %p')

@app.template_filter()
def format_date_time(value):

    return value.strftime('%d-%m-%Y %I:%M %p')

@app.context_processor
def global_function():
    if session.get('username'):
        print(f"**********{session['role']}")
        user = get_a_profile(role=session['role'], username=session['username'])
        return dict( user=user)

    return dict()

@app.errorhandler(404)
def page_not_found(e):
    return render_template('error_pages/404.html')

@app.errorhandler(500)
def page_not_found(e):
    return render_template('error_pages/500.html')

@app.errorhandler(401)
def page_not_found(e):
    return render_template('error_pages/401.html')

@app.before_request
def hook():
    # request - flask.request
    print('endpoint: %s, url: %s, path: %s' % (
        request.endpoint,
        request.url,
        request.path))

