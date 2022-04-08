from flask import Flask, render_template, session, copy_current_request_context
from flask_socketio import SocketIO, emit, disconnect
from threading import Lock


async_mode = None
app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socket_ = SocketIO(app, async_mode=async_mode)
thread = None
thread_lock = Lock()


@app.route('/')
def index():
    return render_template('index.html', async_mode=socket_.async_mode)


@socket_.on('my_event', namespace='/test')
def test_message(message):
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response',
         {'data': message['data'], 'count': session['receive_count']})


@socket_.on('my_broadcast_event', namespace='/test')
def test_broadcast_message(message):
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response',
         {'data': message['data'], 'count': session['receive_count']},
         broadcast=True)


@socket_.on('disconnect_request', namespace='/test')
def disconnect_request():
    @copy_current_request_context
    def can_disconnect():
        disconnect()

    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response',
         {'data': 'Disconnected!', 'count': session['receive_count']},
         callback=can_disconnect)


@socket_.on('message')
def handle_message(data):
    print('received message: ' + data)         


@socket_.on('json')
def handle_json(json):
    print('received json: ' + str(json))


@socket_.on('my event_no_args')
def handle_my_custom_event_no_args(json):
    print('received json: ' + str(json))


@socket_.on('my_event_args')
def handle_my_custom_event_args(arg1, arg2, arg3):
    print('received args: ' + arg1 + arg2 + arg3)


if __name__ == '__main__':
    socket_.run(app, debug=True)