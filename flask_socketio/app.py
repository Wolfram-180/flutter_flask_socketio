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


@socketio.on('join')
def join_group_room(room_id, client_id):
    join_room(room_id)
    print('client ', client_id, ' joined to ', room_id)
    emit('joined', client_id)


@socketio.on('message')
def message_room(data):
    print(data)


if __name__ == '__main__':
    socketio.run(app, debug=True)