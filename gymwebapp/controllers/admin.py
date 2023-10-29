from flask import Blueprint
from flask import render_template, session, abort,Response, request, redirect
from models.all_users_func import *
from models.admin_func import *
from forms.registration import RegistrationForm
from datetime import date, datetime, timedelta


admin_bp = Blueprint('admin_bp', __name__)


"""
Authenticate the user as an admin before they can interact with each funciton.
"""
@admin_bp.before_request
def hook():
    if session.get('username') and user_exists(session['role'], session['username']):
        if session['role'] == "admin":
             return 
    abort(401)


"---------------------------------------REPORTS-------------------------------------------"

"""
View Financial Report.
Generate the income from Subscriptions and Personal Training sessions seperately based on a given range.
Validation applied to ensure enddate will be greater than startdate before a report is generated.

"""


@admin_bp.route('/view-reports')
def view_reports():
    return render_template("admin/reports/view-financial-reports.html")

#View report page when date error has occured
def errorview_reports():
    errorresult = True
    return render_template("admin/reports/view-financial-reports.html", errorresult = errorresult)
    
#Form to get dates from user
@admin_bp.route('/report', methods=['POST'])
def get_reports():
    #variables from the form
    fromDate = request.form.get("fromDate")
    toDate = request.form.get("toDate")

    #check if the dates are in the right order
    from_date_obj = datetime.strptime(fromDate, '%Y-%m-%d')
    to_date_obj = datetime.strptime(toDate, '%Y-%m-%d')
    #redirect to functions depending the dates
    print(from_date_obj, to_date_obj)
    if from_date_obj > to_date_obj:
        return errorview_reports()
    else: 
        return correctdates(from_date_obj, to_date_obj)
    
#generates report if the dates are ok
def correctdates(start, end):
    errorresult = False
    # fromDate = request.form.get("fromDate")
    # toDate = request.form.get("toDate")
    result = dbget_reports(start, end)
    return render_template("admin/reports/view-financial-reports.html", reports=result, fromDate=start, toDate=end, errorresult=errorresult)

@admin_bp.route('/show_myecharts')
def show_myecharts():
    pie = get_pie()
    line = get_line()
    return render_template("admin/reports/show_myecharts.html",
                           pie_options = pie.dump_options(),
                           line_options = line.dump_options())




"---------------------------------------MEMBERS-------------------------------------------"
"""
View all members and search for members by their names.
"""

@admin_bp.route('/view-members', methods=['GET', 'POST'])
def view_members():

    if request.method == 'POST':
        searched = request.form.get("searchmembers")

        members = dbsearch_members(searched)

        print(members)
    else:
        members = get_all_members()
    
    return render_template("admin/views/view-members.html", members=members)


"""
View a member's profile.

"""

@admin_bp.route('/view/memberprofile/<username>')
def view_memberprofile(username):

    member = get_a_profile('member', username=username)

    isActive = get_sub_status(userID=member[0])
    
    return render_template("admin/member_profile.html", member=member, isActive=isActive[0])

"""
return information while the admin wants to update a member's profile.
"""

@admin_bp.route('/update/memberprofile/<memberID>_<uname>', methods=['GET'])

def updateMemberProfile(memberID, uname):

    # viewUser = update_user_profile(role='member', userID=member_id)
    subStatus = get_sub_status(memberID)
    print(uname)
    member = get_a_profile('member', uname)

    return render_template('admin/update_member.html', member=member, subStatus=subStatus[0])




"""
save changes made to a member's profile.
"""


@admin_bp.route('/save/memberprofile/<memberID>_<uname>', methods=['GET','POST'])
def saveUpdateMemberProfile(memberID, uname):



    data = dict()

    data['ftn'] = request.form.get("fname")
    data['lsn'] = request.form.get("lname")
    data['gender'] = request.form.get("gender")
    data['email'] = request.form.get("email")

    data['house'] = request.form.get("house")
    data['street'] = request.form.get("street")
    data['town'] = request.form.get("town")
    data['city'] = request.form.get("city")
    data['pcode'] = request.form.get("postcode")
    data['phone'] = request.form.get("phone")


    data['intro'] = request.form.get("introduction")
    data['height'] = request.form.get("height")
    data['weight'] = request.form.get("weight")
    data['health'] = request.form.get("health_record")
    data['emp'] = request.form.get("emergent_person")
    data['empct'] = request.form.get("emergent_person_phone")

    data['subStatus'] = request.form.get("subStatus")

    # print(request.form.get("subStatus"))


    update_user_profile(role='member', userID=memberID, data=data, isAdmin=True)


    return redirect(f'/view/memberprofile/{uname}')


"""
Add a new member
"""

@admin_bp.route('/newmember', methods=['GET','POST'])
def addNewMember():
  
    form = RegistrationForm()


    if form.validate_on_submit():

        data = dict()

        
        data['username'] = form.username.data
        data['email'] = form.email.data
        data['first_name'] = form.first_name.data
        data['last_name'] = form.last_name.data
        data['gender'] = form.gender.data
        data['date_of_birth'] = form.dob.data

        data['house_number_name'] = form.housename.data
        data['street'] = form.street.data
        data['town'] = form.town.data
        data['city'] = form.city.data
        data['post_code'] = form.postcode.data
        data['phone'] = form.phone.data


        data['introductions'] = form.introduction.data
        data['height'] = form.height.data
        data['weight'] = form.weight.data
        data['health_record'] = form.health.data
        data['emergency_contact_person'] = form.emergentname.data
        data['emergency_contact_phone'] = form.emergentnum.data

        data['subStatus'] = form.sub.data

        # print(data)
        dbadd_new_member(data, datetime.today(), datetime.today()+timedelta(weeks=4))




        
        return redirect('/view-members')

    return render_template("admin/add_new_member.html", form=form)


"""
Write a message to a chosen member.

"""

@admin_bp.route('/send_message/<int:receiver_id>/<int:sending>/<name>/<username>', methods=['GET', 
'POST'])
def sendMessage(receiver_id, sending=0, name=None, username=None):
    if sending:
        data = dict()
        data['title'] = request.form.get("title")
        data['type'] = request.form.get("type")
        data['msg'] = request.form.get("message")
        data['sent'] = datetime.now()
        send_message_to(session['userID'], receiver_id, data)
        print("successfully sent!")
        return redirect(f'/view/memberprofile/{username}')
 

    return render_template('admin/messages/edit_message.html', receiver_id=receiver_id, name=name, username=username)
    
