import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:project/detail.dart';
import 'package:project/edit.dart';
import 'package:project/group.dart';
import 'package:project/map.dart';
import 'package:project/notifi_service.dart';
import 'package:project/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/search.dart';
import 'package:project/stat.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.groupCode});
  final String groupCode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();
  String groupName = '';
  List<String> more = ['수정', '삭제'];
  List<bool> isLikedList = [];
  bool isCopied = false;
  int like = 0;

  @override
  void initState() {
    getHouseName();
    setState(() {
      isLikedList = [];
    });
    NotificationService().initLocalNotification();
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
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future(() => false),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            groupName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          scrolledUnderElevation: 0,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
                onPressed: () {
                  Get.to(() => SearchPage(
                        groupName: groupName,
                        groupCode: widget.groupCode,
                      ));
                },
                icon: const Icon(Icons.search)),
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
                  const SizedBox(height: 15),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          isCopied = true;
                        });
                        Clipboard.setData(
                            ClipboardData(text: widget.groupCode));

                        NotificationService().showNotification(
                            title: '믿음의 동역자', body: '그룹코드가 클립보드에 복사되었습니다!');
                      },
                      child: SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isCopied
                                ? const Text('복사 완료')
                                : const Text('그룹코드 복사'),
                            const SizedBox(width: 5),
                            isCopied
                                ? const Icon(Icons.check, size: 15)
                                : const Icon(Icons.copy, size: 15),
                          ],
                        ),
                      )),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('통계'),
                onTap: () {
                  Get.to(() => StatPage(groupCode: widget.groupCode));
                },
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('지도'),
                onTap: () {
                  Get.to(() => MapPage(
                        groupCode: widget.groupCode,
                      ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.redo_outlined),
                title: const Text('방 나가기'),
                onTap: () {
                  Get.to(() => const GroupPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.popUntil(context, ModalRoute.withName("/"));
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
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupCode)
                          .collection('prays')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (BuildContext context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (!snapshot.hasData) {
                          return Container();
                        }

                        final List<dynamic> profileImage = snapshot.data!.docs
                            .map((doc) => doc['profileImage'].toString())
                            .toList();

                        final List<dynamic> name = snapshot.data!.docs
                            .map((doc) => doc['name'].toString())
                            .toList();

                        final List<dynamic> content = snapshot.data!.docs
                            .map((doc) => doc['content'].toString())
                            .toList();

                        final List<dynamic> likes = snapshot.data!.docs
                            .map((doc) => doc['likes'])
                            .toList();

                        final List<dynamic> uid = snapshot.data!.docs
                            .map((doc) => doc['uid'])
                            .toList();

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: profileImage.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Row(
                                children: [
                                  const SizedBox(width: 13),
                                  GestureDetector(
                                    onTap: () {
                                      controller.clear();
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '새로운 기도제목',
                                                    style:
                                                        TextStyle(fontSize: 22),
                                                  ),
                                                ],
                                              ),
                                              content: SizedBox(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 300,
                                                child: TextField(
                                                  controller: controller,
                                                  style: const TextStyle(
                                                      fontSize: 17),
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  maxLines: null,
                                                  autocorrect: false,
                                                  textAlignVertical:
                                                      TextAlignVertical.center,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText: '기도제목을 나눠주세요.',
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Get.back();
                                                  },
                                                  child: const Text('취소'),
                                                ),
                                                FilledButton(
                                                  onPressed: () {
                                                    FirebaseFirestore.instance
                                                        .collection('groups')
                                                        .doc(widget.groupCode)
                                                        .collection('prays')
                                                        .doc(FirebaseAuth
                                                            .instance
                                                            .currentUser!
                                                            .uid)
                                                        .set({
                                                      'uid': FirebaseAuth
                                                          .instance
                                                          .currentUser!
                                                          .uid,
                                                      'name': FirebaseAuth
                                                          .instance
                                                          .currentUser!
                                                          .displayName,
                                                      'profileImage':
                                                          FirebaseAuth
                                                              .instance
                                                              .currentUser!
                                                              .photoURL,
                                                      'content':
                                                          controller.text,
                                                      'likes': 0,
                                                      'timestamp': DateTime
                                                              .now()
                                                          .millisecondsSinceEpoch,
                                                    });

                                                    Get.back();
                                                  },
                                                  child: const Text('올리기'),
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.6),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            width: 3,
                                            color:
                                                Colors.purple.withOpacity(0.4),
                                          )),
                                      child: const Icon(Icons.add,
                                          size: 30, color: Colors.black38),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                const SizedBox(width: 13),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      like = likes[index - 1];
                                    });

                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (context, setState) =>
                                                AlertDialog(
                                              title: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${name[index - 1]}의 기도제목',
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              content: SizedBox(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 300,
                                                child: ListView(
                                                  children: [
                                                    const SizedBox(height: 15),
                                                    Text(
                                                      '${content[index - 1]}',
                                                      style: const TextStyle(
                                                          fontSize: 17),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                Row(
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width -
                                                              200,
                                                          alignment: like <= 10
                                                              ? FractionalOffset(
                                                                  like / 10,
                                                                  1 -
                                                                      (like /
                                                                          10))
                                                              : const FractionalOffset(
                                                                  1, 0),
                                                          child:
                                                              FractionallySizedBox(
                                                            child:
                                                                Text('$like'),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 3),
                                                        LinearPercentIndicator(
                                                          percent: like <= 10
                                                              ? like / 10
                                                              : 1,
                                                          lineHeight: 10,
                                                          animation: true,
                                                          backgroundColor:
                                                              Colors.black12,
                                                          progressColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          barRadius:
                                                              const Radius
                                                                  .circular(4),
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width -
                                                              200,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 20),
                                                    IconButton.filled(
                                                      onPressed: () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'groups')
                                                            .doc(widget
                                                                .groupCode)
                                                            .collection('prays')
                                                            .doc(uid[index - 1])
                                                            .update({
                                                          'likes': FieldValue
                                                              .increment(1),
                                                        });
                                                        setState(() {
                                                          like++;
                                                        });
                                                      },
                                                      icon: const Icon(
                                                          Icons.favorite,
                                                          color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        });
                                  },
                                  child: Container(
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
                                        profileImage[index - 1],
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
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
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text(
                  '묵상을 올려주세요!',
                  style: TextStyle(fontSize: 16),
                ));
              }

              List<DocumentSnapshot> documents = snapshot.data!.docs;

              return ListView.builder(
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
                                        Text(
                                          documents[index].get('name'),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
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
                                          content:
                                              documents[index].get('content'),
                                          profile: documents[index]
                                              .get('profileImage'),
                                          autoFocus: false,
                                        ),
                                    transition: Transition.cupertino);
                              },
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Text(
                                  documents[index].get('content'),
                                  maxLines: 4,
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
                                  child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('groups')
                                          .doc(widget.groupCode)
                                          .collection('posts')
                                          .doc(documents[index].id)
                                          .collection('liked')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }

                                        int length = snapshot.data!.docs.length;

                                        return TextButton(
                                          onPressed: () async {
                                            final likedPostsRef =
                                                FirebaseFirestore.instance
                                                    .collection('groups')
                                                    .doc(widget.groupCode)
                                                    .collection('posts')
                                                    .doc(documents[index].id)
                                                    .collection('liked')
                                                    .doc(FirebaseAuth.instance
                                                        .currentUser!.uid);

                                            final likedPostsDoc =
                                                await likedPostsRef.get();

                                            if (likedPostsDoc.exists) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                content: Text('이미 공감했습니다!'),
                                                duration: Duration(seconds: 1),
                                              ));
                                            } else {
                                              likedPostsRef.set({
                                                'liked': true,
                                                'timestamp': DateTime.now()
                                                    .millisecondsSinceEpoch,
                                                'profileImage': FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .photoURL
                                              });
                                              FirebaseFirestore.instance
                                                  .collection('groups')
                                                  .doc(widget.groupCode)
                                                  .collection('posts')
                                                  .doc(documents[index].id)
                                                  .update({
                                                'likes':
                                                    FieldValue.increment(1),
                                              });
                                            }

                                            setState(() {
                                              isLikedList[index] = true;
                                            });
                                          },
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStatePropertyAll(
                                                      length >
                                                              0
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
                                                color: length > 0
                                                    ? Colors.white
                                                    : Colors.black,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Text('공감',
                                                  style: TextStyle(
                                                      color: length > 0
                                                          ? Colors.white
                                                          : Colors.black)),
                                            ],
                                          ),
                                        );
                                      }),
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
              );
            },
          ),
        ),
        floatingActionButton: SizedBox(
          width: 115,
          child: FloatingActionButton(
            onPressed: () {
              Get.to(() => PostPage(groupCode: widget.groupCode));
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 5),
                  Text(
                    '묵상 올리기',
                    style: TextStyle(fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
