"""
This module contains contains the core logic of the server. It provides the mapping of all
communication between users, friends and the database. We are using the Flask framework to
handle the server logic.

Endpoints will be exposed at http://localhost:3001/<endpoint>

Design Pattern
----------------------
This component of our application follows the Mediator design pattern as it
    1. Promotes loose coupling by keeping users from referring to each other explicitly.
       Any request for data, locations, updating information must go through this module
    2. Promotoes a many-to-many relationship. Each user must communicate with every one of
       its friends, and every user has a different friend list. This complicated communication
       is abstracted away by the mediator (app.py)


Information Hiding Principle
----------------------
All modules that interact with this module must conform to the interface of this class. The only
parts exposed to other classes are fundamental methods that are not likely to change.


A Note on Return Types
----------------------
Each endpoint, denoted by "@app.route", receives an HTTP Request as its argument and returns
a Flask Response object, containing the HTTP status and a data field.
"""

import logging
import json
from flask import Flask, request, Response
from db import Db

app = Flask(__name__)
db = Db()


def create_test_app(uri):
    db = Db(uri)
    return app


@app.route('/addUser', methods=['GET'])
def add_user():
    """
    Endpoint: /addUser
    Adds a new user to the database.

    Arguments
    --------------------
        user_name       -- a string, username of a new user

    Response
    --------------------
        Code: 200       -- Success
        Code: 400       -- User already exists
                        -- No username provided
    """
    user_name = request.args.get('user_name')
    if not user_name:
        logging.info('/addUser: no user name')
        return Response('Must provide user name', status=400)
    added = db.add_user(user_name)
    if added:
        return Response("Signed up!", status=200)
    return Response('User already exists', status=400)


@app.route('/addFriend', methods=['GET'])
def add_friend():
    """
    Endpoint: /addUser
    Adds friend to user's friends list. Enpoint /addFriend.

    Arguments
    --------------------
        user_name       -- a string, user
        friend_name     -- a string, friend to be added

    Response
    --------------------
        Code: 200       -- Success
        Code: 400       -- User does not exist
                        -- No username or friend was provided
    """
    user_name = request.args.get('user_name')
    friend_name = request.args.get('friend_name')
    if not user_name or not friend_name:
        logging.info('/add_friend: no user name or friend name')
        return Response('Must provide user name and friend name', status=400)
    res = db.add_friend(user_name, friend_name)
    if res:
        return Response('Added!', status=200)
    return Response("Cannot add friend to user's friends list, user does not exist", status=400)


@app.route('/deleteFriend', methods=['GET'])
def delete_friend():
    """
    Enpoint: /addFriend.
    Adds friend to user's friends list.

    Arguments
    --------------------
        user_name       -- a string, user
        friend_name     -- a string, friend to be added

    Response
    --------------------
        Code: 200       -- Success
        Code: 400       -- Friend does not exist
                        -- No username or friend was provided
    """
    user_name = request.args.get('user_name')
    friend_name = request.args.get('friend_name')
    if not user_name or not friend_name:
        logging.info('/delete_friend: no user name or friend name')
        return Response('Must provide user name and friend name', status=400)
    res = db.delete_friend(user_name, friend_name)
    if res:
        return Response('Removed!', status=200)
    return Response('Friend does not exist', status=400)


@app.route('/registerLocation', methods=['POST'])
def register():
    """
    Endpoint: /registerLocation
    Register a user's most recent location.

    Arguments
    --------------------
        user_name       -- a string, user
        location        -- JSON object, Location object formatted as JSON. Contains either GPS data
                           for outdoor locations or Indoor Formatted for indoor locations.

    Response
    --------------------
        Code: 200       -- Success
        Code: 400       -- No such user
    """
    user_name = request.args.get('user_name')
    location = request.json
    res = db.set_location(user_name, location)
    if res:
        return Response('Updated!', status=200)
    return Response('No such user', status=400)


@app.route('/lookup', methods=['GET'])
def lookup_loc():
    """
    Endpoint: /register
    Looks up location of a friend for a given user.

    Arguments
    --------------------
        user_name       -- a string, user
        friend_name     -- a string, friend who's location is requested

    Response
    --------------------
        Code: 200       --  Returns a JSON Object containing user's location data
        Code: 400       --  No such user
        Code: 401       --  Access Denied
                        --  Requested friend has not enable location sharing
    """
    user_name = request.args.get('user_name')
    friend_name = request.args.get('friend_name')
    if not friend_name:
        print('no friend_name')
        logging.info('/lookup_loc: no friend name')
        return Response('Must provide a friend name', status=400)

    # Ensure user exists is allowed to view location still
    friends_list = db.get_friends_list(user_name)
    if friends_list is None:
        return Response('No such user', status=400)

    is_available = db.location_available(user_name)
    if not is_available and is_available != None:
        return Response('Friend has location toggled off', status=401)

    if friend_name not in friends_list:
        print('access denied')
        logging.info('/lookup_loc: illegal friend lookup')
        return Response("Not authroized to view this user's location", status=401)

    location = db.get_location(friend_name)
    if location is None:
        return Response('No such user', status=400)
    return Response(json.dumps(location), status=200)


@app.route('/toggle', methods=['GET'])
def toggle_loc():
    """
    Toggle user's location sharing on and off. Endpoint /toggle.

    Arguments
    --------------------
        user_name       -- a string, user who is toggling their location

    Response
    --------------------
        Code: 200       -- Success
        Code: 400       -- No user name provided.
    """
    user_name = request.args.get('user_name')
    if not user_name:
        logging.info('/toggle: No user name')
        return Response('Must provide a user name', status=400)
    res = db.toggle(user_name)
    if not res:
        return Response("User doesn't exist", status=400)
    return Response("Toggled!", status=200)


if __name__ == '__main__':
    app.run(host='0.0.0.0')
