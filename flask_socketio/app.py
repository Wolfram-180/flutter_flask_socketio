from flask import Flask, render_template, session, copy_current_request_context, request
from flask_socketio import SocketIO, emit, send, join_room, leave_room, disconnect, ConnectionRefusedError
from threading import Lock
import logging
import json

import environment_params

logging.basicConfig(filename='servlog.log', encoding='utf-8', level=logging.INFO)

def logmess(str, stateid=0):
    if stateid == 1:
        logging.warning(str)
    else:
        logging.info(str)


async_mode = None
app = Flask(__name__)
app.config['SECRET_KEY'] = environment_params.secret_key
socketio = SocketIO(app, async_mode=async_mode, logger=True, engineio_logger=True)
thread = None
thread_lock = Lock()        


@app.route('/')
def index():
    return render_template('index.html', async_mode=socketio.async_mode)        


def authenticate(auth):
    # return False
    return True


# auth to be passed in dictionary format
#  connection and disconnection events are sent individually on each namespace used
@socketio.on('connect')
def on_connect():
    print('client connected')
    emit('connected', {'data': 'Server response on "connect": connected'})


@socketio.on('connect_data')
def handle_connect_data(data):
    print(data['user'])
    print(data['token'])
    #if not authenticate(request.args):
    #    raise ConnectionRefusedError('unauthorized!')


@socketio.on('disconnect')
def on_disconnect():
    print('client disconnected')


@socketio.on('join')
def on_join(data):
    sid = data['sid']
    room = data['room']
    namespace = data['namespace']
    username = data['username']
    join_room(room, sid=sid, namespace=namespace)
    print(username + ' entered the room ' + room)
    emit('enteredtheroom', {'username':username, 'room':room, 'namespace':namespace})


@socketio.on('leave')
def on_leave(data):
    sid = data['sid']
    room = data['room']
    namespace = data['namespace']
    username = data['username']   
    leave_room(room, sid=sid, namespace=namespace)
    emit('lefttheroom', {'username':username, 'room':room, 'namespace':namespace})


@socketio.on('messtoroom')
def mess_to_room(mess, room):
    socketio.emit('send_to_room', {'mess':mess}, to=room)
    print('received message: ' + mess)
    print('message sent to room : ' + room)


@socketio.on('message')
def handle_message(message, data):
    print('received message: ' + message)
    print('received data: ' + data)
    send('received message: ' + message)
    send('received data: ' + data)
    send('received message in namespace="/chat": ' + message, namespace='/chat')
    send('received data in namespace="/chat": ' + data, namespace='/chat')    


@socketio.on('json')
def handle_json(json):
    print('received json: ' + str(json))    
    send(json, json=True)


@socketio.on('event1')
def handle_event1(json):
    print('event1 received json : ' + str(json))
    emit('event1 response', json)


@socketio.on('event2')
def handle_event2(arg1, arg2, arg3):
    print('event2 received args : ' + arg1 + arg2 + arg3)

# returns error: 'SocketIO' object has no attribute 'event'
# https://flask-socketio.readthedocs.io/en/latest/getting_started.html#receiving-messages
# @socketio.event
# look later
#@socketio.event
#def my_custom_event(arg1, arg2, arg3):
#    print('received args jaja2: ' + arg1 + arg2 + arg3)


@socketio.on('test_nmspc_event', namespace='/test')
def test_nmspc_event(json):
    print('received json test_nmspc_event: ' + str(json))


def event4_handler(data):
    print('event4_handler received data: ' + str(data))


socketio.on_event('event4', event4_handler, namespace='/test')


@socketio.on('event5')
def handle_my_custom_event(json):
    print('event5 received json: ' + str(json))
    return 'one', 2


# server-side emit, broadcast=True is assumed
def some_function():
    socketio.emit('some event', {'data': 42})


@socketio.on_error_default  # handles all namespaces without an explicit error handler
def default_error_handler(e):
    print('error e: ', str(e))
    print('request.event["message"] : ', request.event["message"]) 
    print('request.event["args"] : ', request.event["args"])    
    pass


if __name__ == '__main__':
    socketio.run(app, debug=True)