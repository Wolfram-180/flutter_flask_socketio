import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Retrieve Text Input',
      home: MyCustomForm(),
    );
  }
}

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({Key? key}) : super(key: key);

  @override
  _MyCustomFormState createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final rcvrId = TextEditingController();
  final messString = TextEditingController();
  late Socket socket;

  @override
  void initState() {
    super.initState();

    rcvrId.addListener(_printrcvrId);
    messString.addListener(_printmessString);

    socket = io(
        'http://10.0.2.2:3000',
        OptionBuilder().setTransports(['websocket']) // for Flutter or Dart VM
            // .disableAutoConnect() // disable auto-connection
            .setExtraHeaders({'websocket': 'chat'}) // optional
            .build());

    socket.onConnect(
      (_) {
        print('connect');
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
        );
      },
    );

    socket.on('get_mess_event', (data) => getEvent(data));
/*    socket.on(
      'get_mess_event',
      (data) {
        final dataList = data as List;
        final ack = dataList.last as Function;
        ack(null);
      },
    );*/

    socket.connect();
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
        title: const Text('Send / Receive WebSocket mess'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
/*            InkWell(
              onTap: () {
                connect();
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Connect'),
              ),
            ),*/
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter client ID',
              ),
              controller: rcvrId,
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter message',
              ),
              controller: messString,
            ),
            Divider(),
            InkWell(
              onTap: () {
                sendMess();
                //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                //  content: Text('Tap'),
                //));
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Send'),
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
    socket.emit('msg', 'test');
  }
}
