class Message {
  String msgId = 'null';
  String content = "Hello!";
  int senderId = 1;
  String senderName = 'user1';
  late final DateTime sendTime;
  int groupId = 1;

  Message({
    this.msgId = 'null',
    this.content = "Hello!",
    this.senderId = 1,
    this.senderName = 'user1',
    DateTime? sendTime,
    this.groupId = 1,
  }) : this.sendTime = sendTime ?? DateTime.now();
}
