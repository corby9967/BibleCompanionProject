import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key, required this.groupCode});
  final String groupCode;

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  TextEditingController controller = TextEditingController();
  bool isButtonActive = false;

  @override
  void initState() {
    controller.addListener(() {
      final isButtonActive = controller.text.isNotEmpty;
      setState(() {
        this.isButtonActive = isButtonActive;
      });
    });
    super.initState();
  }

  void addPost() async {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupCode)
        .collection('posts')
        .doc()
        .set({
      'name': FirebaseAuth.instance.currentUser!.displayName,
      'uid': FirebaseAuth.instance.currentUser!.uid,
      'content': controller.text,
      'timestamp': Timestamp.now().millisecondsSinceEpoch,
      'profileImage': FirebaseAuth.instance.currentUser!.photoURL,
      'likes': 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: () {
              if (isButtonActive) {
                addPost();
                Navigator.pop(context);
              }
            },
            child: Text(
              'Done',
              style: TextStyle(
                  color: isButtonActive ? Colors.black : Colors.black26),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              width: MediaQuery.of(context).size.width,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                autocorrect: false,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
