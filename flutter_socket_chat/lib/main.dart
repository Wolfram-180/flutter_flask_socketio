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
            Text(
              'Room ID: ' + socketId,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Client ID: ' + (clientIdStr != null ? clientIdStr : ''),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Room ID',
              ),
              controller: rcvrId,
            ),
            /*
            TextField(
              decoration: const InputDecoration(
                hintText: 'Client ID',
              ),
              controller: rcvrId,
            ),
             */
            TextField(
              decoration: const InputDecoration(
                hintText: 'Message',
              ),
              controller: messString,
            ),
            Divider(),
            /*
            InkWell(
              onTap: () {
                sendMess();
                //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                //  content: Text('Tap'),
                //));
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Send to Room'),
              ),
            ),
             */
            /*
            InkWell(
              onTap: () {
                sendMess();
                //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                //  content: Text('Tap'),
                //));
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Send to Client'),
              ),
            ),
            */
            InkWell(
              onTap: () {
                //connect();
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Join room'),
              ),
            ),
            InkWell(
              onTap: () {
                //connect();
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Leave room'),
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
