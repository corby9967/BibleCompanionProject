import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:project/home.dart';

class MakeGroupPage extends StatefulWidget {
  const MakeGroupPage({super.key});

  @override
  State<MakeGroupPage> createState() => _MakeGroupPageState();
}

class _MakeGroupPageState extends State<MakeGroupPage> {
  final controller = TextEditingController();
  bool isButtonActive = false;
  Set<String> generatedNumbers = <String>{};
  String groupCode = '';

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

  Future<Set<String>> getDocumentNamesFromCollection(
      String collectionName) async {
    Set<String> documentNames = <String>{};

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();

      for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
        documentNames.add(documentSnapshot.id);
      }
      return documentNames;
    } catch (e) {
      print("Error getting document names: $e");
      return documentNames;
    }
  }

  Future saveHouseName(String newCode) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(newCode)
        .set({'name': controller.text});
  }

  Future<String> generateHouseCode() async {
    generatedNumbers = await getDocumentNamesFromCollection('groups');
    int min = 1000;
    int max = 9999;
    int num = generatedNumbers.length;
    int next = num + 1;
    String newCode = '';

    while (true) {
      Random random = Random();
      int randomNumber = min + random.nextInt(max - min + 1);

      generatedNumbers.add(randomNumber.toString());
      if (generatedNumbers.length == next) {
        newCode = randomNumber.toString();
        break;
      }
    }
    saveHouseName(newCode);
    return newCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 만들기'),
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
          const SizedBox(height: 170),
          const Text(
            '새로운 모임의\n이름을 정해주세요.',
            style: TextStyle(fontSize: 25),
          ),
          const SizedBox(height: 88),
          SizedBox(
            height: 54,
            width: MediaQuery.of(context).size.width,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '이름 입력',
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE8E8E8)),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
              ),
            ),
          ),
          const SizedBox(height: 5),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(isButtonActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black12),
            ),
            onPressed: () async {
              if (isButtonActive) {
                FirebaseFirestore.instance
                    .collection('groups')
                    .doc(controller.text)
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .set({
                  'name': FirebaseAuth.instance.currentUser!.displayName,
                  'uid': FirebaseAuth.instance.currentUser!.uid,
                  'profileImage': FirebaseAuth.instance.currentUser!.photoURL
                });

                groupCode = await generateHouseCode();
                Get.to(() => HomePage(groupCode: groupCode));
              }
            },
            child: const Text('Generate'),
          )
        ],
      ),
    );
  }
}
