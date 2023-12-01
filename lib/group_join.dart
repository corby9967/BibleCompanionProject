import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:project/home.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final controller = TextEditingController();
  String errorMsg = '';
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

  void codeVerification() {
    final DocumentReference myDocument =
        FirebaseFirestore.instance.collection('groups').doc(controller.text);

    myDocument.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        myDocument
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({
          'name': FirebaseAuth.instance.currentUser!.displayName,
          'uid': FirebaseAuth.instance.currentUser!.uid,
          'profileImage': FirebaseAuth.instance.currentUser!.photoURL,
        });

        Get.to(() => HomePage(groupCode: controller.text));
      } else {
        setState(() {
          errorMsg = '존재하지 않는 코드입니다.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 참여하기'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const SizedBox(height: 210),
          const Text(
            '4자리 코드를 입력해주세요.',
            style: TextStyle(fontSize: 25),
          ),
          const SizedBox(height: 65),
          SizedBox(
            height: 54,
            width: MediaQuery.of(context).size.width,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '코드 입력',
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE8E8E8)),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                errorMsg,
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(isButtonActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black12),
            ),
            onPressed: () {
              isButtonActive ? codeVerification() : null;
            },
            child: const Text('Enter'),
          )
        ],
      ),
    );
  }
}
