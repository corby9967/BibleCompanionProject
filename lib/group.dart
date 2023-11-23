import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:project/group_join.dart';
import 'package:project/group_make.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout, size: 25)),
          const SizedBox(width: 20)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 170),
          const Text(
            '모임에 참여하거나\n모임을 만들어보세요!',
            style: TextStyle(fontSize: 25),
          ),
          const SizedBox(height: 100),
          FilledButton(
            onPressed: () {
              Get.to(() => const JoinGroupPage());
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: const Center(
                child: Text(
                  '모임 참여하기',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Get.to(() => const MakeGroupPage());
            },
            style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(Colors.black26)),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: const Center(
                child: Text(
                  '모임 만들기',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
