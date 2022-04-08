from flask import Flask, render_template, session, copy_current_request_context
from flask_socketio import SocketIO, emit, disconnect
from threading import Lock
import logging

import environment_params

logging.basicConfig(filename='botlog.log', encoding='utf-8', level=logging.INFO)


async def logmess(str, stateid=0):
    if stateid == 1:
        await logging.warning(str)
    else:
        await logging.info(str)


async_mode = None
app = Flask(__name__)
app.config['SECRET_KEY'] = environment_params.secret_key
socket_ = SocketIO(app, async_mode=async_mode, logger=True, engineio_logger=True)
thread = None
thread_lock = Lock()


@socket_.on('my_event', namespace='/test')
def test_message(message):
    logmess('my_event')
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response',
         {'data': message['data'], 'count': session['receive_count']})


@socket_.on('message', namespace='/test')
def handle_message(data):
    logmess('message: ' + data)
    print('handle_message - received message: ' + data)         


if __name__ == '__main__':
    socket_.run(app, debug=True)