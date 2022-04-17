from flask import Flask, render_template, session, copy_current_request_context
from flask_socketio import SocketIO, emit, disconnect
from flask_socketio import join_room
from threading import Lock
import logging

import environment_params

logging.basicConfig(filename='botlog.log', encoding='utf-8', level=logging.INFO)


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


@socketio.on('connect')
def connect():
    print('client connected')


@socketio.on('disconnect')
def disconnect():
    print('client disconnected')


@socketio.on('message')
def handle_message(data):
    print('received message: ' + data)


@socketio.on('json')
def handle_json(json):
    print('received json: ' + str(json))    


@socketio.on('event1')
def handle_event1(json):
    print('received json event1: ' + str(json))


@socketio.on('event2')
def handle_event2(arg1, arg2, arg3):
    print('received args event2: ' + arg1 + arg2 + arg3)


@socketio.event
def event3(arg1, arg2, arg3):
    print('received args event3: ' + arg1 + arg2 + arg3)


@socketio.on('test_nmspc_event', namespace='/test')
def test_nmspc_event(json):
    print('received json test_nmspc_event: ' + str(json))


def event4_handler(data):
    print('event4_handler received data: ' + str(data))

socketio.on_event('event4', event4_handler, namespace='/test')



@socketio.on('join')
def join_group_room(room_id, client_id):
    join_room(room_id)
    print('client ', client_id, ' joined to ', room_id)
    emit('joined', client_id)


if __name__ == '__main__':
    socketio.run(app, debug=True)