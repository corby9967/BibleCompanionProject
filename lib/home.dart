import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:project/detail.dart';
import 'package:project/edit.dart';
import 'package:project/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.groupCode});
  final String groupCode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String groupName = '';
  List<String> more = ['수정', '삭제'];
  List<bool> isLikedList = [];

  @override
  void initState() {
    getHouseName();
    super.initState();
  }

  void getHouseName() async {
    final documentSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupCode)
        .get();

    setState(() {
      groupName = documentSnapshot.get('name');
    });
  }

  void checkIfLiked(int index, String postId) async {
    final likedPostsRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupCode)
        .collection('posts')
        .doc(postId)
        .collection('liked')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    final likedPostsDoc = await likedPostsRef.get();

    setState(() {
      isLikedList[index] = likedPostsDoc.exists;
    });
  }

  void myDialog(String docId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            title: const Column(
              children: <Widget>[
                Text(
                  '정말 삭제하시겠습니까?',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.all(0),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            actionsAlignment: MainAxisAlignment.end,
            actions: <Widget>[
              TextButton(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FilledButton(
                child: const Text('삭제'),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupCode)
                      .collection('posts')
                      .doc(docId)
                      .delete();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const SizedBox(height: 50),
            Column(
              children: [
                ClipOval(
                  child: Image.network(
                    FirebaseAuth.instance.currentUser!.photoURL.toString(),
                    width: 60,
                    height: 60,
                    fit: BoxFit.fill,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  FirebaseAuth.instance.currentUser!.displayName.toString(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser!.email.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                width: MediaQuery.of(context).size.width,
                child: StreamBuilder<Object>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupCode)
                        .collection('users')
                        .snapshots(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final List<dynamic> fieldValues = snapshot.data!.docs
                          .map((doc) => doc['profileImage'].toString())
                          .toList();

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: fieldValues.length,
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              const SizedBox(width: 7),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 3,
                                    color: Colors.purple.withOpacity(0.8),
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    fieldValues[index],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                            ],
                          );
                        },
                      );
                    }),
              ),
            ),
          ];
        },
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupCode)
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            List<DocumentSnapshot> documents = snapshot.data!.docs;

            return Expanded(
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  var date = DateTime.fromMillisecondsSinceEpoch(
                      documents[index].get('timestamp'));
                  String newDate =
                      '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}:${date.second}';

                  if (isLikedList.length <= index) {
                    isLikedList.add(false);
                    checkIfLiked(index, documents[index].id);
                  }

                  bool isLiked = isLikedList[index];

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 250,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ClipOval(
                                      child: Image.network(
                                        documents[index].get('profileImage'),
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(documents[index].get('name')),
                                        Text(
                                          newDate,
                                          style: const TextStyle(
                                              color: Colors.black38),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  onSelected: (String result) {
                                    result == '수정'
                                        ? Get.to(
                                            () => EditPage(
                                              groupCode: widget.groupCode,
                                              docId: documents[index].id,
                                              content: documents[index]
                                                  .get('content'),
                                            ),
                                          )
                                        : myDialog(documents[index].id);
                                  },
                                  itemBuilder: (BuildContext buildContext) {
                                    if (FirebaseAuth
                                            .instance.currentUser!.uid ==
                                        documents[index].get('uid')) {
                                      return [
                                        for (var value in more)
                                          PopupMenuItem(
                                            value: value,
                                            child: Text(value),
                                          )
                                      ];
                                    } else {
                                      return [];
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () {
                                Get.to(
                                  () => DetailPage(
                                    groupCode: widget.groupCode,
                                    docId: documents[index].id,
                                    name: documents[index].get('name'),
                                    uid: documents[index].get('uid'),
                                    date: newDate,
                                    content: documents[index].get('content'),
                                    profile:
                                        documents[index].get('profileImage'),
                                    autoFocus: false,
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Text(
                                  documents[index].get('content'),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '공감 ${documents[index].get('likes')}',
                                  style: const TextStyle(color: Colors.black38),
                                ),
                              ],
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 1,
                              decoration:
                                  const BoxDecoration(color: Colors.black12),
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width / 2 -
                                      20,
                                  child: TextButton(
                                    onPressed: () async {
                                      final likedPostsRef = FirebaseFirestore
                                          .instance
                                          .collection('groups')
                                          .doc(widget.groupCode)
                                          .collection('posts')
                                          .doc(documents[index].id)
                                          .collection('liked')
                                          .doc(FirebaseAuth
                                              .instance.currentUser!.uid);

                                      final likedPostsDoc =
                                          await likedPostsRef.get();

                                      if (likedPostsDoc.exists) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text('이미 공감했습니다!')));
                                      } else {
                                        FirebaseFirestore.instance
                                            .collection('groups')
                                            .doc(widget.groupCode)
                                            .collection('posts')
                                            .doc(documents[index].id)
                                            .collection('liked')
                                            .doc(FirebaseAuth
                                                .instance.currentUser!.uid)
                                            .set({
                                          'liked': true,
                                          'timestamp': DateTime.now()
                                              .millisecondsSinceEpoch,
                                          'profileImage': FirebaseAuth
                                              .instance.currentUser!.photoURL
                                        });
                                        FirebaseFirestore.instance
                                            .collection('groups')
                                            .doc(widget.groupCode)
                                            .collection('posts')
                                            .doc(documents[index].id)
                                            .update({
                                          'likes': FieldValue.increment(1),
                                        });
                                      }

                                      setState(() {
                                        isLikedList[index] = true;
                                      });
                                    },
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStatePropertyAll(isLiked
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0))),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.face_5_outlined,
                                          color: isLiked
                                              ? Colors.white
                                              : Colors.black,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text('공감',
                                            style: TextStyle(
                                                color: isLiked
                                                    ? Colors.white
                                                    : Colors.black)),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width / 2 -
                                      20,
                                  child: TextButton(
                                    onPressed: () {
                                      Get.to(
                                        () => DetailPage(
                                          groupCode: widget.groupCode,
                                          name: documents[index].get('name'),
                                          date: newDate,
                                          content:
                                              documents[index].get('content'),
                                          profile: documents[index]
                                              .get('profileImage'),
                                          uid: documents[index].get('uid'),
                                          docId: documents[index].id,
                                          autoFocus: true,
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.message_rounded,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Text('댓글',
                                            style:
                                                TextStyle(color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => PostPage(groupCode: widget.groupCode));
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
