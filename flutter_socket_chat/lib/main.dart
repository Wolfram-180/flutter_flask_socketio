import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();

    // Start listening to changes.
    rcvrId.addListener(_printrcvrId);
    messString.addListener(_printmessString);
  }

  @override
  void dispose() {
    rcvrId.dispose();
    messString.dispose();
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
            SendButton(),
          ],
        ),
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  const SendButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The InkWell wraps the custom flat button widget.
    return InkWell(
      // When the user taps the button, show a snackbar.
      onTap: () {
        //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        //  content: Text('Tap'),
        //));
      },
      child: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Send'),
      ),
    );
  }
}
