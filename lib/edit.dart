import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditPage extends StatefulWidget {
  const EditPage(
      {super.key,
      required this.groupCode,
      required this.docId,
      required this.content});

  final String groupCode;
  final String docId;
  final String content;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  TextEditingController controller = TextEditingController();
  bool isButtonActive = false;

  @override
  void initState() {
    setState(() {
      controller.text = widget.content;
    });
    controller.addListener(() {
      final isButtonActive = controller.text.isNotEmpty;
      setState(() {
        this.isButtonActive = isButtonActive;
      });
    });
    super.initState();
  }

  void editPost() async {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupCode)
        .collection('posts')
        .doc(widget.docId)
        .update({
      'content': controller.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글 수정하기'),
        actions: [
          TextButton(
            onPressed: () {
              if (isButtonActive) {
                editPost();
                Navigator.pop(context);
              }
            },
            child: Text(
              '완료',
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
              width: MediaQuery.of(context).size.width,
              height: 300,
              child: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
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
