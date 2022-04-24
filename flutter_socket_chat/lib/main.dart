import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_socket_chat/common/texts.dart';
import 'package:flutter_socket_chat/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:uuid/uuid.dart';

import 'common/hasher.dart' as hasher;
import 'ignore_data/temp_data.dart' as temp_data;

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
  late Socket socket;
  late Future<String> clientId;
  String clientIdStr = '';
  var uuid = Uuid();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  final roomId_control = TextEditingController();
  final messString_control = TextEditingController();

  bool joinedRoom = false;

  Future<String> SetClientId() async {
    final SharedPreferences prefs = await _prefs;
    final String _clientId = (prefs.getString('clientId') ?? uuid.v4());

    setState(() {
      clientId = prefs.setString('clientId', _clientId).then((bool success) {
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

    clientId = SetClientId().then((String clientId) => clientIdStr = clientId);

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
      //setState(() {});
      String _hash = hasher.textToMd5(temp_data.usr_password);
      print(data['data']);
      Map<String, dynamic> connectData = ({
        //'socketId': socketId,
        //'clientId': clientIdStr,
        'user': temp_data.usr_login,
        'token': _hash,
      });
      socket.emit('connect_data', connectData);
    });

    socket.connect();

    roomId_control.addListener(_printrcvrId);
    messString_control.addListener(_printmessString);
  }

  void _printrcvrId() {
    //print('ID: ${rcvrId.text}');
  }

  void _printmessString() {
    //print('Mess: ${messString.text}');
  }

  void getEvent(data) {
    //print(data);
  }

  @override
  void dispose() {
    socket.dispose();
    roomId_control.dispose();
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
              const SizedBox(height: 15),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SIDcopyToClipboard_Btn(socketId: SID),
                  const SizedBox(width: 5),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_circle_down, size: 18),
                    label: Text('Paste SID'),
                    onPressed: () {
                      FlutterClipboard.paste().then((value) {
                        setState(() {
                          roomId_control.text = value;
                          SID = value;
                        });
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('SID pasted from clipboard'),
                      ));
                    },
                  ),
                ],
              ),
              SID_txtField(roomId: roomId_control),
              Message_txtField(messString: messString_control),
              Divider(),
              Row(mainAxisSize: MainAxisSize.min, children: [
                JoinRoom_Btn(
                    socket: socket, socketId: SID, clientIdStr: clientIdStr),
                const SizedBox(width: 5),
                Disconnect_Btn(socket: socket),
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
  const JoinRoom_Btn({
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
        Map<String, dynamic> connectData = ({
          'socketId': socketId,
          'clientId': clientIdStr,
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

class Disconnect_Btn extends StatelessWidget {
  // used
  const Disconnect_Btn({
    Key? key,
    required this.socket,
  }) : super(key: key);

  final Socket socket;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_chart, size: 18),
      label: Text('Disconnect'),
      onPressed: () {
        socket.emit('disconnect');
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
