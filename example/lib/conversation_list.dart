import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twilio_conversation_sdk/twilio_conversation_sdk.dart';

class ConversationList extends StatefulWidget {
  const ConversationList(this.identity, this.twilioConversationSdkPlugin,
      {super.key});

  final String identity;
  final TwilioConversationSdk twilioConversationSdkPlugin;

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  //final _twilioConversationSdkPlugin = TwilioConversationSdk();
  late List conversationList = List.empty(growable: true);
  late List lastMessageList = List.empty(growable: true);
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
    listOfConversation();
  }

  Future<void> listOfConversation() async {
    var list =
        await widget.twilioConversationSdkPlugin.getConversations() ?? [];

    conversationList.clear();
    conversationList.addAll(list);
    print("Flutter$conversationList");
    for (dynamic conversation in conversationList) {
      var sid = conversation['sid'];
      if (sid != null) {
        //TODO unread msg count working

        var lastMessage = await widget.twilioConversationSdkPlugin
                .getLastMessages(conversationId: sid) ??
            [];
        print("Flutter LastMessage: $lastMessage");

        if (lastMessage.isNotEmpty) {
          // Extract the message body from the fetched last message
          var messageBody = lastMessage[0]['lastMessage'] ?? 'No message';
          var lastMessageDate =
              lastMessage[0]['lastMessageDate'] ?? 'No lastMessageDate';
          print("DevlastMessageDateFlutter--> $lastMessageDate");

          var friendlyIdentity = lastMessage[0]['friendlyIdentity'] ??
              'No friendlyIdentity'; // Default if no body

          // Find and update the conversation in conversationList by matching sid
          int index = conversationList.indexWhere((c) => c['sid'] == sid);
          if (index != -1) {
            // Update the conversation with the last message
            conversationList[index]['lastMessage'] =
                friendlyIdentity + ": " + messageBody;
          }
        }

        /*var lastUnReadMessageCount = await widget.twilioConversationSdkPlugin
                .getUnReadMsgCount(conversationId: sid) ??
            [];
        print("Flutter LastMessageUnReadCount: $lastUnReadMessageCount");

        if (lastUnReadMessageCount.isNotEmpty) {
          // Extract the message body from the fetched last message
          var messageBody = lastUnReadMessageCount[0]['unReadCount'] ??
              0; // Default if no body

          // Find and update the conversation in conversationList by matching sid
          int index = conversationList.indexWhere((c) => c['sid'] == sid);
          if (index != -1) {
            // Update the conversation with the last message
            conversationList[index]['unReadCount'] = messageBody;
          }
        }*/
      }
    }
    sorting();
    isLoading = false;

    setState(() {});
  }

  sorting() {
    conversationList.sort(
      (conversationOld, conversationNew) {
        var oldLastDate = conversationOld['lastMessageDate'] ?? "";
        var newLastDate = conversationNew['lastMessageDate'] ?? "";
        return oldLastDate == null && oldLastDate == ""
            ? 1
            : newLastDate == null && newLastDate == ""
                ? -1
                : -DateTime.parse(conversationOld['lastMessageDate'] ?? '')
                    .compareTo(DateTime.parse(
                        conversationNew['lastMessageDate'] ?? ''));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        titleSpacing: 10,
        title: Text(widget.identity),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop("data");
          },
          icon: const Icon(Icons.arrow_back_ios_new),
          iconSize: 30,
        ),
        actions: [
          IconButton(
            onPressed: () {
              listOfConversation();
            },
            icon: const Icon(Icons.refresh),
            iconSize: 30,
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(18.0),
                child: ListView.builder(
                  itemCount: conversationList.length,
                  itemBuilder: (context, index) {
                    int unreadIndex = 0;
                    var lastReadIndex =
                        conversationList.elementAt(index)['lastReadIndex'];
                    var lastMessageIndex =
                        conversationList.elementAt(index)['lastMessageIndex'];
                    if (lastMessageIndex != null && lastReadIndex != null) {
                      unreadIndex = lastMessageIndex - lastReadIndex;
                    }
                    /*if (conversationList.elementAt(index)['unReadCount'] !=
                        null) {
                      unreadIndex =
                          conversationList.elementAt(index)['unReadCount'];
                    }*/

                    var conversationName =
                        conversationList.elementAt(index)['conversationName'];
                    var lastMessage =
                        conversationList.elementAt(index)['lastMessage'];
                    String formattedTime = '';
                    if (conversationList.elementAt(index)['lastMessageDate'] !=
                        null) {
                      print(
                          "dateTime ; ${conversationList.elementAt(index)['lastMessageDate']}");
                      String time =
                          conversationList.elementAt(index)['lastMessageDate'];
                      DateTime dateTime = DateTime.parse(time).toLocal();
                      if (dateTime.isBefore(now)) {
                        formattedTime =
                            DateFormat('MM/dd/yyyy hh:mm a').format(dateTime);
                      } else {
                        formattedTime = DateFormat('hh:mm a').format(dateTime);
                      }
                    }

                    return InkWell(
                      onTap: () async {
                        await deleteConversation(
                            conversationList.elementAt(index)['sid'], index);
                      },
                      child: Card(
                        child: Dismissible(
                          key: Key(conversationList.elementAt(index)['sid']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) async {
                            await deleteConversation(
                                conversationList.elementAt(index)['sid'],
                                index);
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: Text(
                                        conversationName.substring(0, 1),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 25),
                                      )),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(conversationName),
                                        lastMessage != null
                                            ? Text(
                                                lastMessage,
                                                style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              )
                                            : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                            color: unreadIndex != 0
                                                ? Colors.green
                                                : Colors.grey,
                                            fontWeight: FontWeight.normal),
                                      ),
                                      unreadIndex != 0
                                          ? Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: const BoxDecoration(
                                                  color: Colors.black,
                                                  shape: BoxShape.circle),
                                              child: Text(
                                                unreadIndex.toString(),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ))
                                          : Container()
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  deleteConversation(String sid, int index) async {
    setState(() {
      isLoading = true;
    });
    await widget.twilioConversationSdkPlugin
        .deleteConversation(conversationId: sid)
        .then((result) {
      print(result);
      if (result == "Success") {
        conversationList.removeAt(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted'),
          ),
        );
      }
    });
    setState(() {
      isLoading = false;
    });
  }
}
