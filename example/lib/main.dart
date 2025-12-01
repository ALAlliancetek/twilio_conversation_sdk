import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:twilio_conversation_sdk/twilio_conversation_sdk.dart';
import 'package:twilio_conversation_sdk_example/conversation_list.dart';

DateFormat get formatterYYYYMMddTHHMMss => DateFormat('yyyy-MM-ddTHH:mm:ss');

DateFormat get formatterHHMMAA => DateFormat('yyyy-MM-dd hh:mm a');

DateFormat get formatterYYYYMMddTHHMMssSSS =>
    DateFormat('yyyy-MM-ddTHH:mm:ss.SSS');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Twilio Conversation SDK',
      home: Conversation(),
    );
  }
}

class Conversation extends StatefulWidget {
  const Conversation({super.key});

  @override
  State<Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  static var accountSid = '';
  static var apiKey = '';
  static var apiSecret = '';
  static var serviceSid =
      ''; // Default Conversation Service SID
  static var pushSid = '';
  static var identity = '';
  static var participantIdentity = '';
  String? accessToken = "";

  final _twilioConversationSdkPlugin = TwilioConversationSdk();

  //var conversationId = "";
  //var conversationId = "";
  var conversationId = "";
  var conversationName = "";
  List messages = List.empty(growable: true);
  List participantList = List.empty(growable: true);
  TextEditingController message = TextEditingController();
  final ScrollController _controller = ScrollController();
  final double _height = 100.0;
  String authorName = "";
  String selectedDocPath = "";
  String fileName = "";
  bool isSendMedia = false;
  double _progress = 0;
  int totalBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _animateToIndex(messages.length);
    });
  }

  void getAccessToken(String accountSid, String apiKey, String apiSecret,
      String identity, String serviceSid, String pushSid) async {
    accessToken = await _twilioConversationSdkPlugin.generateToken(
        accountSid: accountSid,
        apiKey: apiKey,
        apiSecret: apiSecret,
        identity: identity,
        serviceSid: serviceSid,
        pushSid: pushSid);

    final String? resultInitialization = await _twilioConversationSdkPlugin
        .initializeConversationClient(accessToken: accessToken!);
    if (resultInitialization!.isNotEmpty) {
      _twilioConversationSdkPlugin.onClientSyncStatusChanged.listen((event) {
        print("Client Status Received ${event.toString()}");
        if (event['status'] != null) {
          if (event['status'] == 2) {
            checkOrCreateConversation();
          }
        }
      });
    }
    setState(() {});
  }

  checkOrCreateConversation() async {
    List conversationList =
        await _twilioConversationSdkPlugin.getConversations() ?? [];
    print("Conversation List $conversationList");
    if (conversationList.isNotEmpty) {
      bool isParticipantFound = false;
      for (Map conversation in conversationList) {
        print("Conversation $conversation");
        participantList = await _twilioConversationSdkPlugin
                .getParticipantsWithName(conversationId: conversation["sid"]) ??
            [];
        for (Map participant in participantList) {
          print("Participant $participant");
          if (participant["identity"] == participantIdentity) {
            isParticipantFound = true;
            conversationId = conversation["sid"];
            conversationName = conversation["conversationName"];
            subscribe();
            break;
          }
        }
        if (isParticipantFound) {
          break;
        }
      }
      if (!isParticipantFound) {
        createConversation();
      }
    } else {
      createConversation();
    }
    setState(() {});
  }

  unsubscribe() {
    _twilioConversationSdkPlugin.unSubscribeToMessageUpdate(
        conversationSid: conversationId);
  }

  subscribe() {
    _twilioConversationSdkPlugin.subscribeToMessageUpdate(
        conversationSid: conversationId);
    _twilioConversationSdkPlugin.onMessageReceived.listen((event) async {
      if (event['status'] != null) {
        print("Conversation Status Received ${event.toString()}");
        if (event['status'] == 3) {
          await getAllMessages();
        }
      } else if (event['author'] != null) {
        print("Conversation Message Received ${event.toString()}");
        messages.add(event);
        _animateToIndex(messages.length);
        setState(() {});
      } else if (event['mediaStatus'] != null) {
        if (event['mediaStatus'] == "Completed" ||
            event['mediaStatus'] == "Failed") {
          setState(() {
            _progress = 0;
            totalBytes = 0;
            isSendMedia = false;
          });
        }
        print("Conversation Message Received ${event.toString()}");
      } else if (event['bytesSent'] != null) {
        print("Conversation Message Received ${event.toString()}");
        setState(() {
          final bytesSent = event['bytesSent'];
          _progress = bytesSent / totalBytes;
        });
      } else if (event['messageStatus'] != null) {
        if (event['messageStatus'] == "Failed") {
          setState(() {
            _progress = 0;
            totalBytes = 0;
            isSendMedia = false;
          });
        }
        print("Conversation Message Received ${event.toString()}");
      }
    });
    /* _twilioConversationSdkPlugin.onMediaProgressReceived.listen((event) async {
      if (event['messageStatus'] != null) {
        print("onMediaProgressReceived ${event.toString()}");
      } else if (event['mediaStatus'] != null) {
        print("onMediaProgressReceived ${event.toString()}");
      } else if (event['bytesSent'] != null) {
        print("onMediaProgressReceived ${event.toString()}");
      }
    });*/
    setState(() {});
  }

  createConversation() async {
    //String timeStamp = DateTime.now().toString();
    //String conversationName = "Flutter - $timeStamp";
    String conversationFriendlyName = "$identity-$participantIdentity";
    conversationId = (await _twilioConversationSdkPlugin.createConversation(
        conversationName: conversationFriendlyName, identity: identity))!;
    print("Result $conversationId");
    conversationName = conversationFriendlyName;
    joinConversation();
    addParticipant();

    subscribe();
  }

  joinConversation() async {
    String? joinResult = (await _twilioConversationSdkPlugin.joinConversation(
        conversationId: conversationId))!;
    print("Result $joinResult");
  }

  sendMessage({bool isSendAttribute = false}) async {
    String timeStamp = DateTime.now().toString();
    Map<String, dynamic> attribute;
    if (isSendAttribute) {
      attribute = {
        "body": message.text.toString().trim(),
        "url": "http://www.google.com",
        "cardId": timeStamp,
      };
    } else {
      attribute = {
        "body": message.text.toString().trim(),
        "cardId": timeStamp,
      };
    }

    final String? sendMessage = await _twilioConversationSdkPlugin.sendMessage(
        conversationId: conversationId,
        message: message.text.toString().trim(),
        attribute: attribute);
    print("Result $sendMessage");
    message.text = "";
    setState(() {});
  }

  sendMessageWithMedia() async {
    Map<String, dynamic> attribute;

    attribute = {"hasMedia": true};

    final String? sendMessage =
        await _twilioConversationSdkPlugin.sendMessageWithMedia(
            message: "",
            conversationId: conversationId,
            attribute: attribute,
            mediaFilePath: selectedDocPath,
            mimeType: getMimeType(selectedDocPath),
            fileName: fileName);
    print("Result $sendMessage");
    _progress = 0;
    totalBytes = 0;
    isSendMedia = false;
    setState(() {});
  }

  getAllMessages() async {
    print("Get Message for $conversationId");
    messages.clear();
    var messageList = await _twilioConversationSdkPlugin.getMessages(
            conversationId: conversationId) ??
        [];
    messages.addAll(messageList);
    print("Messages $messages");
    setState(() {});
    Future.delayed(const Duration(milliseconds: 500));
    _animateToIndex(messages.length);
  }

  addParticipant() async {
    final String? addSecondParticipantConversation =
        await _twilioConversationSdkPlugin.addParticipant(
            conversationId: conversationId,
            participantName: participantIdentity);
    print("Result Second $addSecondParticipantConversation");
    unsubscribe();
    subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        titleSpacing: 10,
        leading: participantIdentity.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Colors.black, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  participantIdentity.substring(0, 1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25),
                ))
            : Container(),
        title: Text(identity.isEmpty
            ? "Twilio Conversation SDK"
            : "$participantIdentity - $conversationName"),
        actions: [
          accessToken!.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    getAllMessages();
                  },
                  icon: const Icon(Icons.refresh),
                  iconSize: 30,
                )
              : Container(),
          accessToken!.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ConversationList(
                              identity, _twilioConversationSdkPlugin);
                        },
                      ),
                    ).then((data) {
                      subscribe();
                    });
                    unsubscribe();
                  },
                  icon: const Icon(Icons.chat),
                  iconSize: 30,
                )
              : Container(),
        ],
      ),
      body: Center(
        child: Container(
          color: Colors.black12,
          child: Column(
            children: [
              accessToken!.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (value) {
                          identity = value;
                        },
                        decoration: const InputDecoration(
                            labelText: 'Enter your identity'),
                      ),
                    )
                  : Container(),
              accessToken!.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (value) {
                          participantIdentity = value;
                        },
                        decoration: const InputDecoration(
                            labelText: 'Enter participant identity'),
                      ),
                    )
                  : Container(),
              accessToken!.isEmpty
                  ? ElevatedButton(
                      onPressed: () {
                        if (identity.isNotEmpty) {
                          getAccessToken(accountSid, apiKey, apiSecret,
                              identity, serviceSid, pushSid);
                        }
                      },
                      child: Text("Get Access Token"),
                    )
                  : Container(),
              Expanded(
                  child: messages.isNotEmpty
                      ? Column(
                          children: [
                            Visibility(
                              visible: isSendMedia,
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight:
                                    20.0, // Set the height of the progress bar
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  controller: _controller,
                                  shrinkWrap: true,
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    List? attachMedia =
                                        messages[index]['attachMedia'] ?? [];
                                    return InkWell(
                                        onTap: () async {
                                          await _twilioConversationSdkPlugin
                                              .deleteMessageWithSid(
                                                  conversationId:
                                                      conversationId,
                                                  messageSid: messages[index]
                                                      ["sid"],
                                                  messageCount: 1000)
                                              .then((result) async {
                                            if (result == "Success") {
                                              await getAllMessages();
                                            }
                                            print(result);
                                          });
                                        },
                                        child: getMessageView(
                                            messages[index]["attributes"],
                                            messages[index]["body"],
                                            messages[index]["author"],
                                            messages[index]["dateCreated"],
                                            attachMedia));
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Text(
                            "No message yet",
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          ),
                        )),
              accessToken!.isNotEmpty
                  ? Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: TextField(
                                    controller: message,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Message',
                                      hintStyle: TextStyle(color: Colors.white),
                                      contentPadding: EdgeInsets.only(
                                          left: 15,
                                          bottom: 11,
                                          top: 11,
                                          right: 15),
                                    ),
                                  ),
                                ),
                                isSendMedia
                                    ? const CircularProgressIndicator()
                                    : IconButton(
                                        onPressed: () async {
                                          if (message.text.isNotEmpty) {
                                            sendMessage();
                                          } else {
                                            showAlert(
                                                "Please type your message");
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                        ),
                                        iconSize: 30,
                                      ),
                              ],
                            ),
                          ),
                        ),
                        isSendMedia
                            ? const CircularProgressIndicator()
                            : Container(
                                decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: IconButton(
                                  onPressed: () async {
                                    pickFileFromDevice();
                                    /*if (message.text.isNotEmpty) {
                                sendMessage(isSendAttribute: true);
                              } else {
                                showAlert("Please type your message");
                              }*/
                                  },
                                  icon: const Icon(
                                    Icons.attach_file,
                                    color: Colors.white,
                                  ),
                                  iconSize: 30,
                                ),
                              ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  getMessageView(String attribute, String message, String author, String date,
      List<dynamic>? attachMedia) {
    String timeAgo = convertUTCToLocalChat(
        utcDateTime: date,
        inputDateFormat: formatterYYYYMMddTHHMMss,
        outputDateFormat: formatterHHMMAA);

    for (Map participant in participantList) {
      if (participant["friendlyIdentity"] == author) {
        authorName = participant["friendlyName"] != null &&
                participant["friendlyName"].toString().isNotEmpty
            ? participant["friendlyName"]
            : participant["friendlyIdentity"];
        print("authorName>>$authorName");
        break;
      }
    }
    if (attribute.contains("hasMedia")) {
      String? mediaUrl;
      String? contentType;
      String? filename;
      for (var media in attachMedia!) {
        filename = media['filename'];
        mediaUrl = media['mediaUrl'];
        contentType = media['contentType'];
        //String? sid = media['sid'];
      }
      print("mediaUrl${mediaUrl}");
      return Align(
        alignment:
            author == identity ? Alignment.centerRight : Alignment.centerLeft,
        child: Card(
          margin: const EdgeInsets.all(10),
          color: author == identity ? Colors.blue : Colors.black,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                authorName.isNotEmpty
                    ? Text(
                        textAlign: TextAlign.end,
                        authorName,
                        style: const TextStyle(color: Colors.red, fontSize: 10),
                      )
                    : const SizedBox(),
                mediaUrl != null && mediaUrl.isNotEmpty
                    ? contentType == "application/pdf" ||
                            contentType == "video/mp4"
                        ? Text(
                            textAlign: TextAlign.end,
                            filename ?? "",
                            style: TextStyle(
                                color: author == identity
                                    ? Colors.white
                                    : Colors.white,
                                fontSize: 16),
                          )
                        : SizedBox(
                            height: 200,
                            width: 150,
                            child: CachedNetworkImage(
                                imageUrl: mediaUrl,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                      height: 200,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    )),
                          )
                    : const SizedBox(),
                message.isNotEmpty
                    ? Text(
                        textAlign: TextAlign.end,
                        message,
                        style: TextStyle(
                            color: author == identity
                                ? Colors.white
                                : Colors.white,
                            fontSize: 10),
                      )
                    : const SizedBox(),
                Text(
                  textAlign: TextAlign.end,
                  timeAgo,
                  style: TextStyle(
                      color: author == identity ? Colors.white : Colors.white,
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (attribute.contains("url")) {
      Map<String, String> attributeModel = Map.castFrom(json.decode(attribute));
      if (attributeModel['url'] != null) {
        return Align(
          alignment:
              author == identity ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            margin: const EdgeInsets.all(10),
            color: author == identity ? Colors.blue : Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        textAlign: TextAlign.center,
                        attributeModel['url']!,
                        style: TextStyle(
                            color: author == identity
                                ? Colors.white
                                : Colors.white,
                            fontSize: 14),
                      ),
                    ),
                    Text(
                      textAlign: TextAlign.end,
                      timeAgo,
                      style: TextStyle(
                          color:
                              author == identity ? Colors.white : Colors.white,
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return Align(
          alignment:
              author == identity ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  authorName.isNotEmpty
                      ? Text(
                          textAlign: TextAlign.end,
                          authorName,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 10),
                        )
                      : const SizedBox(),
                  Text(
                    message,
                    style: TextStyle(
                        color: author == identity ? Colors.blue : Colors.black,
                        fontSize: 14),
                  ),
                  Text(
                    textAlign: TextAlign.end,
                    timeAgo,
                    style: TextStyle(
                        color: author == identity ? Colors.blue : Colors.black,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      return Align(
        alignment:
            author == identity ? Alignment.centerRight : Alignment.centerLeft,
        child: Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                authorName.isNotEmpty
                    ? Text(
                        textAlign: TextAlign.end,
                        authorName,
                        style: const TextStyle(color: Colors.red, fontSize: 10),
                      )
                    : const SizedBox(),
                Text(
                  message,
                  style: TextStyle(
                      color: author == identity ? Colors.blue : Colors.black,
                      fontSize: 14),
                ),
                Text(
                  timeAgo,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: author == identity ? Colors.blue : Colors.black,
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  String convertUTCToLocalChat(
      {required String utcDateTime,
      required DateFormat inputDateFormat,
      required DateFormat outputDateFormat}) {
    try {
      // Parse the UTC date string
      DateTime utcDate = inputDateFormat.parseUtc(utcDateTime);
      String inputLocalDate = inputDateFormat.format(utcDate.toLocal());
      DateTime outputLocalDateTime = inputDateFormat.parse(inputLocalDate);
      return outputDateFormat.format(outputLocalDateTime).toString();
    } catch (e) {
      debugPrint(e.toString());
      return utcDateTime;
    }
  }

  void _animateToIndex(int index) {
    if (_controller.hasClients) {
      _controller.animateTo(
        index * _height,
        duration: const Duration(seconds: 2),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void showAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future pickFileFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'pdf', 'png', 'doc', 'docx'],
    );

    if (result != null &&
            result.files.single.path!
                .isNotEmpty /*&&
            result.files.single.path!.contains(".pdf") ||
        result!.files.single.path!.contains(".jpg") ||
        result.files.single.path!.contains(".jpeg") ||
        result.files.single.path!.contains(".png") ||
        result.files.single.path!.contains(".doc") ||
        result.files.single.path!.contains(".docx")*/
        ) {
      selectedDocPath = result.files.single.path!;
      fileName = result.files.single.name;
      totalBytes = result.files.single.size;
      debugPrint("Selected file path: $selectedDocPath");
      isSendMedia = true;
      setState(() {});
      await sendMessageWithMedia();
    } else {
      debugPrint("File picking canceled.");
    }
  }

  String getMimeType(String filePath) {
    // Use the lookupMimeType function from the mime package
    String? mimeType = lookupMimeType(filePath);
    // Return the detected MIME type or default to "application/octet-stream"
    return mimeType ?? "application/octet-stream";
  }
}
