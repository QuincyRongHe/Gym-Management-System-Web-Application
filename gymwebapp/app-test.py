#!/usr/bin/env python
# encoding: utf-8
from flask import Flask, request, jsonify, abort
from werkzeug.security import check_password_hash
from flask_login import LoginManager, login_user, current_user, login_required
import base64
from functools import wraps
from enum import IntEnum


app = Flask(__name__)
app.secret_key = "ITJUSTDOESNTMATTER"

login_manager = LoginManager()
login_manager.init_app(app)


class Role(IntEnum):
    ADMIN = 1
    TRAINER = 2
    MEMBER = 3


class User:
    def __init__(self, name, role):
        self.name = name
        self.access_level = Role.MEMBER
        if role == 'manager':
            self.access_level = Role.ADMIN
        elif role == 'warehouse':
            self.access_level = Role.TRAINER

    @staticmethod
    def is_authenticated():
        return True

    @staticmethod
    def is_active():
        return True

    @staticmethod
    def is_anonymous():
        return False

    def get_id(self):
        return self.name

    def get_role(self):
        return self.access_level

    def allowed(self, access_level):
        return self.access_level >= access_level


def check_access(access_level):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not current_user.is_authenticated:
                return abort(401)

            if not current_user.allowed(access_level):
                return abort(401)
            return f(*args, **kwargs)
        return decorated_function
    return decorator


# Retrieve an item
@app.route('/api/inventory', methods=['GET'])
@check_access(Role.SALES)
def query_records():
    try:
        name = request.args.get('name')
        with sqlite3.connect("database.db") as con:
            con.row_factory = sqlite3.Row
            cur = con.cursor()
            cur.execute("select data from inventory where name=?", (name, ))
            row = cur.fetchone()
            return row["data"] if row else ("{} not found".format(name), 400)
    except Exception as e:
        abort(500, e)


if __name__ == '__main__':
    app.run()