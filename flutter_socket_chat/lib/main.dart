import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_socket_chat/common/texts.dart';
import 'package:flutter_socket_chat/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:uuid/uuid.dart';

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
  String socketId = '';
  // String clientId = '';
  final rcvrId = TextEditingController();
  final messString = TextEditingController();

  late Socket socket;
  late Future<String> clientId;
  String clientIdStr = '';
  var uuid = Uuid();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool joinedRoom = false;

  // in fact not used as clientId is permanent and decided in initState
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
        OptionBuilder().setTransports(['websocket']) // for Flutter or Dart VM
            // .disableAutoConnect() // disable auto-connection
            .setExtraHeaders({'websocket': 'chat'}) // optional
            .build());

    socket.on('serv_response_message', (data) => getEvent(data));
    socket.on('get_mess_event', (data) {
      final dataList = data as List;
      final ack = dataList.last as Function;
      ack(null);
    });

    //socket.on("connect", (_) => print('Connected'));
    //socket.on("disconnect", (_) => print('Disconnected'));
    socket.onConnect((_) {
      setState(() {
        socketId = socket.id!;
      });
      print('connect');
    });
    /*
        socket.emitWithAck(
          'msg',
          'init',
          ack: (data) {
            print('ack $data');
            if (data != null) {
              print('from server $data');
            } else {
              print("Null");
            }
          },
        );*/
    socket.on("disconnect", (_) => print('Disconnected'));

    socket.connect();

    rcvrId.addListener(_printrcvrId);
    messString.addListener(_printmessString);
  }

  void getEvent(data) {
    print(data);
  }

  @override
  void dispose() {
    rcvrId.dispose();
    messString.dispose();
    socket.dispose();
    super.dispose();
  }

  void _printrcvrId() {
    print('ID: ${rcvrId.text}');
  }

  void _printmessString() {
    print('Mess: ${messString.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                RoomIDcopyToClipboard(socketId: socketId),
                Flexible(
                  child: Text(
                    'Room ID: ' + socketId,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontFamily: 'Roboto',
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(children: [
              InkWell(
                onTap: () {
                  FlutterClipboard.paste().then((value) {
                    setState(() {
                      rcvrId.text = value;
                      socketId = value;
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Room ID pasted from clipboard'),
                  ));
                },
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Paste Room ID from clipboard to field'),
                ),
              ),
            ]),
            Text(
              'Client ID: ' + (clientIdStr != null ? clientIdStr : ''),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            RoomID_txtField(rcvrId: rcvrId),
            Message_txtField(messString: messString),
            Divider(),
            InkWell(
              onTap: () {
                socket.emit('join', [socketId, clientIdStr]);
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Join room'),
              ),
            ),
            InkWell(
              onTap: () {
                socket.emit('disconnect');
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Leave room'),
              ),
            ),
            InkWell(
              onTap: () {
                socket.emit('message', [socketId, clientIdStr]);
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Send mess to room'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void connect() {}

  void sendMess() {
    print('ID: ${rcvrId.text}');
    print('Mess: ${messString.text}');
    socket.emit('message', messString.text);
/*    socket.emit('msg', 'test');
    socket.emit("sendMessage",
        [messageController.text, widget.roomId, widget.username]);*/
  }
}

class RoomIDcopyToClipboard extends StatelessWidget {
  const RoomIDcopyToClipboard({
    Key? key,
    required this.socketId,
  }) : super(key: key);

  final String socketId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        FlutterClipboard.copy(socketId).then((value) => print(socketId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Room ID copied to clipboard'),
        ));
      },
      child: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Copy Room ID to clipboard'),
      ),
    );
  }
}

class Message_txtField extends StatelessWidget {
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

class RoomID_txtField extends StatelessWidget {
  const RoomID_txtField({
    Key? key,
    required this.rcvrId,
  }) : super(key: key);

  final TextEditingController rcvrId;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Room ID',
      ),
      controller: rcvrId,
    );
  }
}
