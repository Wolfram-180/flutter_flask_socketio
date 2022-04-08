from flask import Flask, render_template, session, copy_current_request_context
from flask_socketio import SocketIO, emit, disconnect
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


@socketio.on('my_event', namespace='/test')
def test_message(message):
    logmess('my_event')
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response',
         {'data': message['data'], 'count': session['receive_count']})


@socketio.on('message')
def handle_message(data):
    logmess('message: ' + data)
    print('handle_message - received message: ' + data)
    emit('serv_response_message',
         {'data': data, 'count': 100})


@app.route('/')
def index():
    return render_template('index0.html', async_mode=socketio.async_mode)             


@socketio.on('connect')
def connect():
    print("a client connected")


@socketio.on('disconnect')
def disconnect():
    print('Client disconnected')


if __name__ == '__main__':
    socketio.run(app, debug=True)