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
    return render_template('index0.html', async_mode=socketio.async_mode)             


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
    
    #print(data)
    #join_room(data['groupId'])
    """
    token = data['token']
    if token in user_token.keys():
        group = Group.query.filter_by(id=int(data['groupId'])).first()
        if group.temp_participants is None:
            group.temp_participants = data['userId'] + ','
        else:
            group.temp_participants += data['userId'] + ','

        db.session.commit()
        join_room(data['groupId'])
        #print(rooms())
    else:
        emit('error', 'Invalid token')
    """


@socketio.on('message')
def message_room(data):
    print(data)

    """
    token = data['token']
    if token in user_token.keys():
        message = Message(content=data['message'], groupid=int(data['groupId']), username=user_token[token],
                          datetime=data['datetime'])

        db.session.add(message)
        db.session.commit()

        participants = Group.query.filter_by(id=message.groupid).first().participants.split(",")
        temp_participants = Group.query.filter_by(id=message.groupid).first().temp_participants.split(",")

        for participant in participants:
            if participant not in temp_participants:
                pushbots.push_batch(platform=pushbots.PLATFORM_ANDROID,
                                              alias=participant,
                                              msg='A new message arrived', payload={'data': {'message': message.content,
                                                                                             'messageId': message.id,
                                                                                             'username': user_token[
                                                                                                 token],
                                                                                             'datetime': message.datetime,
                                                                                             'groupId': message.groupid,
                                                                                             'userId': User.query.filter_by(
                                                                                                 username=user_token[
                                                                                                    token]).first().id}})
        print("Emitting")
        emit('message', {'message': message.content, 'messageId': message.id,
                         'username': user_token[token], 'datetime': message.datetime,
                         'groupId': message.groupid,
                         'userId': User.query.filter_by(username=user_token[token]).first().id},
             room=message.groupid)
        sock.sleep(0)

    else:
        emit('error', 'Invalid token')
    """        


if __name__ == '__main__':
    socketio.run(app, debug=True)

"""
@socketio.on('leave')
def leave_group_room(data):
    print(data)
    token = data['token']
    if token in user_token.keys():
        group = Group.query.filter_by(id=int(data['groupId'])).first()
        group.temp_participants = str(group.temp_participants.split(",").remove(data['userId'])).strip('[]')
        db.session.commit()

        leave_room(data['groupId'])
    emit('error', 'Invalid token')



@socketio.on('my_event', namespace='/test')
def test_message(message):
    logmess('my_event')
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response',
         {'data': message['data'], 'count': session['receive_count']})


@socketio.on('message2')
def handle_message(data):
    logmess('message: ' + data)
    print('handle_message - received message: ' + data)
    emit('serv_response_message',
         {'data': data, 'count': 100})
"""


