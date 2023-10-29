from flask_wtf import FlaskForm
from wtforms import BooleanField, StringField, validators, RadioField, TextAreaField, IntegerField, SubmitField
from wtforms.validators import DataRequired, Email, regexp, ValidationError, NumberRange
from wtforms.fields.html5 import DateField

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

class RegistrationForm(FlaskForm):
    username     = StringField('Username', validators=[validators.Length(min=4, max=25), DataRequired()])
    email        = StringField('Email Address', validators=[validators.Length(min=6, max=35), DataRequired(), Email(granular_message=True)])
    first_name   = StringField('First Name', validators=[validators.length(min=2, max=35), DataRequired()])
    last_name    = StringField('Last Name', validators=[validators.length(min=2, max=35), DataRequired()])
    dob          = DateField('Date of Birth', format='%Y-%m-%d', validators=[DataRequired()])
    gender       = RadioField('Gender',choices=[('male', 'male'), ('female', 'female')], validators=[DataRequired()])
    sub          = RadioField('Subscription',choices=[('1', 'Active'), ('0', 'Inactive')], validators=[DataRequired()])
    housename    = StringField('House Number / Name', validators=[validators.length(min=2, max=15), DataRequired()])
    street       = StringField('Street', validators=[validators.length(min=2, max=20), DataRequired()])
    town         = StringField('Town', validators=[validators.length(min=2, max=25), DataRequired()])
    city         = StringField('City', validators=[validators.length(min=2, max=25), DataRequired()])
    postcode     = StringField('Postal Code', validators=[validators.regexp(regex="(\d{4})", message="Invalid Postal Code, should be NZ postal code only!"), DataRequired()])
    phone        = StringField('Phone Number', validators=[validators.regexp(regex='(02\d\d{6,8}|0800\d{5,8}|0\d\d{7})', message='Invalid NZ Phone number!'), DataRequired()])
    introduction = TextAreaField('Introduction', validators=[validators.length(min=0, max=250)])
    emergentname = StringField('Emergency Contact Person', validators=[validators.length(min=1, max=45), DataRequired()])
    emergentnum  = StringField('Emergency Contact number', validators=[validators.regexp(regex='(02\d\d{6,8}|0800\d{5,8}|0\d\d{7})', message='Invalid NZ Phone number!'), DataRequired()])
    health       = TextAreaField('Health History', validators=[validators.length(min=0, max=250)])
    weight       = IntegerField('Weight', validators=[validators.optional()])
    height       = IntegerField('Height', validators=[validators.optional()])
    submit       = SubmitField()

    def validate_username(form, field):
        connection = getCursor()
        query = f"SELECT COUNT(*) FROM members WHERE username='{field.data}'"
        print(query)
        connection.execute(query)
        isDuplicate = True if int(connection.fetchone()[0]) else False
        if isDuplicate:
            raise ValidationError('This username exists, please use another one')
        
    


    