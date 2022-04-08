
@socket_.on('disconnect_request', namespace='/test')
def disconnect_request():
    logmess('disconnect_request')
    @copy_current_request_context
    def can_disconnect():
        disconnect()

    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response',
         {'data': 'Disconnected!', 'count': session['receive_count']},
         callback=can_disconnect)

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
    print('handle_message - received message: ' + data)         


@socket_.on('json')
def handle_json(json):
    print('handle_json - received json: ' + str(json))


@socket_.on('my event_no_args')
def handle_my_custom_event_no_args(json):
    print('handle_my_custom_event_no_args - received json: ' + str(json))


@socket_.on('my_event_args')
def handle_my_custom_event_args(arg1, arg2, arg3):
    print('handle_my_custom_event_args - received args: ' + arg1 + arg2 + arg3)


@socket_.event
def my_custom_event(arg1, arg2, arg3):
    print('my_custom_event - received args: ' + arg1 + arg2 + arg3)    


@socket_.on('my_event_test_nmspc', namespace='/test')
def handle_my_custom_namespace_event(json):
    print('handle_my_custom_namespace_event - received json: ' + str(json))    