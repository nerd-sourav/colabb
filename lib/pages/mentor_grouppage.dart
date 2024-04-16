import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colabb/components/chat_bubble.dart';
import 'package:colabb/services/auth/auth_service.dart';
import 'package:colabb/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import '../components/my_textfield.dart';
import 'package:flutter/material.dart';

class MentorRoom extends StatefulWidget {
  static const String id = "mentorroomid";
  MentorRoom({super.key});

  @override
  State<MentorRoom> createState() => _MentorRoomState();
}

class _MentorRoomState extends State<MentorRoom> {
  final TextEditingController _messageController = TextEditingController();
  AuthService _auth = AuthService();
  ChatService _chatService = ChatService();

  // for textfield focus
  FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    getList();

    // add listener to focus node
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // cause a delay so that the keyboard has time to show up
        //then the amount of remaining space will be calculated,
        //the scroll down
        Future.delayed(
          const Duration(milliseconds: 500),
          () => scrollDown(),
        );
      }
    });

    // wait a bit for listview to be built, then scrollto bottom
    Future.delayed(
      const Duration(milliseconds: 500),
      () => scrollDown(),
    );
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // scroll controller
  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  List mentorroomlist = [];

  void getList() async {
    String? uid = _auth.getCurrentUser()?.uid;

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('mentor_room')
        .get()
        .then((value) {
      setState(() {
        mentorroomlist = value.docs;
      });
    });
  }

  // send message
  void sendmessage() async {
    // if there is something inside the textfield
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMentorRoomMessage(
          _messageController.text, 'text', mentorroomlist[0]['chat_room_id']);

      // clear text controller
      _messageController.clear();
    }

    scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          title: const Text(
            "Mentor's Room",
            style: TextStyle(fontSize: 50, fontWeight: FontWeight.w200),
          ),
          backgroundColor: Colors.transparent,
        ),
        // bottomNavigationBar: MyBottomAppBar(),
        body: _buildMessageList()
        // SingleChildScrollView(
        //   // margin: EdgeInsets.only(top: 32),
        //   // alignment: Alignment.center,
        //   child: Column(
        //     children: [
        //       CircleAvatar(
        //         radius: 46,
        //       ),
        //       SizedBox(
        //         height: 16,
        //       ),
        //       Text('mentor'),
        //       Container(child: _buildMessageList()),
        //     ],
        //   ),
        // ),
        );
  }

  // build message list
  Widget _buildMessageList() {
    String chatRoomID = mentorroomlist[0]['chat_room_id'];
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: _chatService.getRoomMessages(chatRoomID),
            builder: (context, snapshot) {
              // Remaining code for StreamBuilder...
              // errors
              if (snapshot.hasError) {
                return const Text("Error");
              }

              // loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Loading");
              }

              // return list view
              return ListView(
                shrinkWrap: true,
                controller: _scrollController,
                children: snapshot.data!.docs
                    .map((doc) => _buildMessageItem(doc))
                    .toList(),
              );
            },
          ),
        ),
        _buildUserInput(),
      ],
    );
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // is current user
    User loggedInUser = _auth.getCurrentUser()!;
    bool isCurrentUser = data['senderId'] == loggedInUser.uid;

    // align message to the right if sender is the current user, otherwise left
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data["message"],
            isCurrentUser: isCurrentUser,
            type: data['type'],
          )
        ],
      ),
    );
  }

  //build message input
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Row(
        children: [
          // textfield should take upmost of the space
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Type a message",
              obscureText: false,
              focusNode: myFocusNode,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            margin: EdgeInsets.only(right: 25.0),
            child: IconButton(
              onPressed: sendmessage,
              icon: Icon(
                Icons.arrow_upward,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
