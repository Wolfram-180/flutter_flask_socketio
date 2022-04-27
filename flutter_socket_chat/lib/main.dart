import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_socket_chat/common/texts.dart';
import 'package:flutter_socket_chat/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:uuid/uuid.dart';

import 'common/hasher.dart' as hasher;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      home: ChatForm(),
    );
  }
}

class ChatForm extends StatefulWidget {
  const ChatForm({Key? key}) : super(key: key);

  @override
  _ChatFormState createState() => _ChatFormState();
}

class _ChatFormState extends State<ChatForm> {
  String SID = '';
  String nameSpace = 'default';

  String userName = 'User';
  String roomName = 'Room';

  String messageTxt = '';

  late Future<String> clientId;
  String clientIdStr = '';
  var uuid = Uuid();

  late Socket socket;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  //final SID_control = TextEditingController();
  final roomString_control = TextEditingController();
  final nmspcString_control = TextEditingController();
  final usrnmString_control = TextEditingController();
  final messString_control = TextEditingController();

  final String pref_clientId = 'clientId';
  final String pref_roomName = 'roomName';
  final String pref_nameSpace = 'nameSpace';
  final String pref_userName = 'userName';

  bool joinedRoom = false;

  Future<String> SetClientData() async {
    final SharedPreferences prefs = await _prefs;
    final String _clientId = (prefs.getString(pref_clientId) ?? uuid.v4());

    roomName = (prefs.getString(pref_roomName) ?? 'Room');
    nameSpace = (prefs.getString(pref_nameSpace) ?? 'default');
    userName = (prefs.getString(pref_userName) ?? 'User');

    setState(() {
      clientId = prefs.setString(pref_clientId, _clientId).then((bool success) {
        return _clientId;
      });
    });
    return _clientId;
  }

  Message msg = Message(
      msgId: 'null',
      content: "Hello!",
      senderId: 1,
      senderName: 'user1',
      sendTime: DateTime.now(),
      groupId: 1);

  @override
  void initState() {
    super.initState();

    clientId =
        SetClientData().then((String clientId) => clientIdStr = clientId);

    socket = io(
        'http://10.0.2.2:5000',
        OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .disableAutoConnect() // disable auto-connection
            .setExtraHeaders({'auth': 'token_val'}) // optional
            .build());

    socket.onConnect((_) {
      setState(() {
        SID = socket.id!;
      });
      print('onConnect : socketId = ${SID}');
    });

    socket.on("disconnect", (_) {
      setState(() {
        SID = '';
      });
      print('disconnected');
    });

    socket.on("connected", (data) {
      String _hash = hasher.textToMd5(userName);
      print(data['data']);
      Map<String, dynamic> connectData = ({
        'user': userName,
        'token': _hash,
      });
      socket.emit('connect_data', connectData);
    });

    socket.on('entered_the_room', (data) {
      print('entered the room' + ' : ' + data['username']);
    });

    socket.connect();

    roomString_control.addListener(_lstnrRoomString);
    nmspcString_control.addListener(_lstnrNmspcString);
    usrnmString_control.addListener(_lstnrUsrnmString);
    messString_control.addListener(_lstnrMessString);

    roomString_control.text = roomName;
    nmspcString_control.text = nameSpace;
    usrnmString_control.text = userName;
  }

  void _lstnrRoomString() async {
    roomName = roomString_control.text;
    final SharedPreferences prefs = await _prefs;
    prefs.setString(pref_roomName, roomName).then((bool success) {});
  }

  void _lstnrNmspcString() async {
    nameSpace = nmspcString_control.text;
    final SharedPreferences prefs = await _prefs;
    prefs.setString(pref_nameSpace, nameSpace).then((bool success) {});
  }

  void _lstnrUsrnmString() async {
    userName = usrnmString_control.text;
    final SharedPreferences prefs = await _prefs;
    prefs.setString(pref_userName, userName).then((bool success) {});
  }

  void _lstnrMessString() async {
    messageTxt = messString_control.text;
  }

  void getEvent(data) {
    //print(data);
  }

  @override
  void dispose() {
    socket.dispose();
    //SID_control.dispose();
    roomString_control.dispose();
    nmspcString_control.dispose();
    usrnmString_control.dispose();
    messString_control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                children: [
                  Flexible(child: ClientID_Text(clientIdStr: clientIdStr)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Flexible(child: SID_Text(socketId: SID)),
                ],
              ),
              Room_txtField(roomString: roomString_control),
              Nmspc_txtField(nmspcString: nmspcString_control),
              Usrnm_txtField(messString: usrnmString_control),
              Message_txtField(messString: messString_control),
              Row(mainAxisSize: MainAxisSize.min, children: [
                JoinRoom_Btn(
                    socket: socket,
                    sid: SID,
                    room: roomName,
                    namespace: nameSpace,
                    username: userName),
                const SizedBox(width: 5),
                LeaveRoom_Btn(
                    socket: socket,
                    sid: SID,
                    room: roomName,
                    namespace: nameSpace,
                    username: userName),
              ]),
              SendMessToRoom_Btn(
                  socket: socket, socketId: SID, clientIdStr: clientIdStr),
              const Divider(
                color: Colors.grey,
                height: 20,
                thickness: 1,
                indent: 0,
                endIndent: 0,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_chart, size: 18),
                label: Text('Send mess to room'),
                onPressed: () {
                  socket.emit('message', [SID, clientIdStr]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void connect() {
    socket.connect();
  }
}

class SendMessToRoom_Btn extends StatelessWidget {
  // used
  const SendMessToRoom_Btn({
    Key? key,
    required this.socket,
    required this.socketId,
    required this.clientIdStr,
  }) : super(key: key);

  final Socket socket;
  final String socketId;
  final String clientIdStr;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_chart, size: 18),
      label: Text('Send mess to room'),
      onPressed: () {
        socket.emit('message', [socketId, clientIdStr]);
      },
    );
  }
}

class JoinRoom_Btn extends StatelessWidget {
  //used
  const JoinRoom_Btn(
      {Key? key,
      required this.socket,
      required this.sid,
      required this.room,
      required this.namespace,
      required this.username})
      : super(key: key);

  final Socket socket;
  final String sid;
  final String room;
  final String namespace;
  final String username;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add, size: 18),
      label: Text('Join room'),
      onPressed: () {
        Map<String, dynamic> connectData = ({
          'sid': sid,
          'room': room,
          'namespace': namespace,
          'username': username,
        });
        socket.emit('join', [connectData]);
      },
    );
  }
}

class ClientID_Text extends StatelessWidget {
  // used
  const ClientID_Text({
    Key? key,
    required this.clientIdStr,
  }) : super(key: key);

  final String clientIdStr;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Client ID: ' + (clientIdStr != null ? clientIdStr : ''),
      textAlign: TextAlign.left,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 16.0,
        fontFamily: 'Roboto',
        color: Color(0xFF212121),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class SID_Text extends StatelessWidget {
  // used
  const SID_Text({
    Key? key,
    required this.socketId,
  }) : super(key: key);

  final String socketId;

  @override
  Widget build(BuildContext context) {
    return Text(
      'SID: ' + socketId,
      textAlign: TextAlign.left,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 16.0,
        fontFamily: 'Roboto',
        color: Color(0xFF212121),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class SIDcopyToClipboard_Btn extends StatelessWidget {
  // used
  const SIDcopyToClipboard_Btn({
    Key? key,
    required this.socketId,
  }) : super(key: key);

  final String socketId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add_chart, size: 18),
            label: Text('Copy SID to clip'),
            onPressed: () {
              String _mess = 'SID ' + socketId + ' copied to clipboard';
              FlutterClipboard.copy(socketId).then((value) => print(_mess));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_mess),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class SID_txtField extends StatelessWidget {
  // used
  const SID_txtField({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  final TextEditingController roomId;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'SID',
      ),
      controller: roomId,
    );
  }
}

class Usrnm_txtField extends StatelessWidget {
  // used
  const Usrnm_txtField({
    Key? key,
    required this.messString,
  }) : super(key: key);

  final TextEditingController messString;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'User name',
      ),
      controller: messString,
    );
  }
}

class Message_txtField extends StatelessWidget {
  // used
  const Message_txtField({
    Key? key,
    required this.messString,
  }) : super(key: key);

  final TextEditingController messString;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Message',
      ),
      controller: messString,
    );
  }
}

class Room_txtField extends StatelessWidget {
  // used
  const Room_txtField({
    Key? key,
    required this.roomString,
  }) : super(key: key);

  final TextEditingController roomString;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Room',
      ),
      controller: roomString,
    );
  }
}

class Nmspc_txtField extends StatelessWidget {
  // used
  const Nmspc_txtField({
    Key? key,
    required this.nmspcString,
  }) : super(key: key);

  final TextEditingController nmspcString;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Namespace',
      ),
      controller: nmspcString,
    );
  }
}

class LeaveRoom_Btn extends StatelessWidget {
  //used
  const LeaveRoom_Btn(
      {Key? key,
      required this.socket,
      required this.sid,
      required this.room,
      required this.namespace,
      required this.username})
      : super(key: key);

  final Socket socket;
  final String sid;
  final String room;
  final String namespace;
  final String username;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_remove, size: 18),
      label: Text('Leave room'),
      onPressed: () {
        Map<String, dynamic> leaveData = ({
          'sid': sid,
          'room': room,
          'namespace': namespace,
          'username': username,
        });
        socket.emit('leave', [leaveData]);
      },
    );
  }
}

/*class Connect_Btn extends StatelessWidget {
  const Connect_Btn({
    Key? key,
    required this.socket,
    required this.socketId,
    required this.clientIdStr,
  }) : super(key: key);

  final Socket socket;
  final String socketId;
  final String clientIdStr;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_chart, size: 18),
      label: Text('Join room'),
      onPressed: () {
        if (socket.connected == false) {
          socket.connect();
        }
        socket.emit('join', [socketId, clientIdStr]);
      },
    );
  }
}*/
