from functools import wraps
from flask import Response, request, g, session
from models.all_users_func import *


def login_required(func):
    @wraps(func)
    def decorated_function(*args, **kwargs):
        if session['username'] and user_exists(session['role'], session['username']):
            return func(*args, **kwargs)
        
        return Response('Authorization failed', mimetype='text/plain', status=401)
    return decorated_function



def role_requires(role):
    def role_required(func):
        @wraps(func)
        def decorated_function(*args, **kwargs):
            
            if 'ADMIN'== role:
                return func(*args, **kwargs)
            
            
            return Response('Access Denied', mimetype='text/plain', status=401)
        return decorated_function
    return role_required

def subscription_required():
    def role_required(func):
        @wraps(func)
        def decorated_function(*args, **kwargs):
            
            if session['subStatus']:
                return func(*args, **kwargs)
            
            
            return Response('Access Denied', mimetype='text/plain', status=401)
        return decorated_function
    return role_required