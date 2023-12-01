import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:project/edit.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({
    super.key,
    required this.groupCode,
    required this.name,
    required this.date,
    required this.content,
    required this.profile,
    required this.uid,
    required this.docId,
    required this.autoFocus,
  });

  final String groupCode;
  final String name;
  final String uid;
  final String date;
  final String content;
  final String profile;
  final String docId;

  final bool autoFocus;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  TextEditingController controller = TextEditingController();
  String groupName = '';
  List<String> more = ['수정', '삭제'];

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

  void myDialog(String docId1, String docId2, String type) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            title: Column(
              children: <Widget>[
                Text(
                  '$type을 삭제하시겠습니까?',
                  style: const TextStyle(fontSize: 20),
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
                  type == '글'
                      ? FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupCode)
                          .collection('posts')
                          .doc(docId1)
                          .delete()
                      : FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupCode)
                          .collection('posts')
                          .doc(docId1)
                          .collection('comments')
                          .doc(docId2)
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
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: Column(
        children: [
          StreamBuilder<Object>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupCode)
                  .collection('posts')
                  .doc(widget.docId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                QuerySnapshot commentsSnapshot = snapshot.data as QuerySnapshot;

                List<DocumentSnapshot> commentDocuments = commentsSnapshot.docs;

                return SizedBox(
                  height: MediaQuery.of(context).size.height - 220,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: commentDocuments.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          ClipOval(
                                            child: Image.network(
                                              widget.profile,
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
                                                widget.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                widget.date,
                                                style: const TextStyle(
                                                    color: Colors.black38),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (String result) {
                                          result == '수정'
                                              ? Get.to(
                                                  () => EditPage(
                                                    groupCode: widget.groupCode,
                                                    docId: widget.docId,
                                                    content: widget.content,
                                                  ),
                                                )
                                              : myDialog(
                                                  widget.docId,
                                                  commentDocuments[index - 1]
                                                      .id,
                                                  '글');
                                        },
                                        itemBuilder:
                                            (BuildContext buildContext) {
                                          if (FirebaseAuth
                                                  .instance.currentUser!.uid ==
                                              widget.uid) {
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
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: Text(widget.content),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 110,
                              decoration: BoxDecoration(
                                  color: Colors.black12.withOpacity(0.05),
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18))),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StreamBuilder<Object>(
                                        stream: FirebaseFirestore.instance
                                            .collection('groups')
                                            .doc(widget.groupCode)
                                            .collection('posts')
                                            .doc(widget.docId)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          DocumentSnapshot documentSnapshot =
                                              snapshot.data as DocumentSnapshot;
                                          var likes =
                                              documentSnapshot.get('likes');
                                          return Row(
                                            children: [
                                              const Text(
                                                '공감',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '$likes',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                '댓글',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${commentDocuments.length}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                    const SizedBox(height: 6),
                                    StreamBuilder<Object>(
                                      stream: FirebaseFirestore.instance
                                          .collection('groups')
                                          .doc(widget.groupCode)
                                          .collection('posts')
                                          .doc(widget.docId)
                                          .collection('liked')
                                          .orderBy('timestamp',
                                              descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        QuerySnapshot likedSnapshot =
                                            snapshot.data as QuerySnapshot;

                                        List<DocumentSnapshot> likedDocuments =
                                            likedSnapshot.docs;

                                        return Expanded(
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            itemCount: likedDocuments.length,
                                            itemBuilder: (context, index) {
                                              return Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black26,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        width: 2,
                                                        color: Colors.purple
                                                            .withOpacity(0.8),
                                                      ),
                                                    ),
                                                    child: ClipOval(
                                                      child: Image.network(
                                                        likedDocuments[index]
                                                            .get(
                                                                'profileImage'),
                                                        fit: BoxFit.fill,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 1,
                              decoration:
                                  const BoxDecoration(color: Colors.black12),
                            ),
                          ],
                        );
                      } else {
                        var date = DateTime.fromMillisecondsSinceEpoch(
                            commentDocuments[index - 1].get('timestamp'));
                        String newDate =
                            '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}:${date.second}';
                        return Column(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 80,
                              decoration: BoxDecoration(
                                  color: Colors.black12.withOpacity(0.05)),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  children: [
                                    ClipOval(
                                      child: Image.network(
                                        commentDocuments[index - 1]
                                            .get('profileImage'),
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${commentDocuments[index - 1].get('name')}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 7),
                                            Text(
                                              newDate,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black38),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${commentDocuments[index - 1].get('comment')}',
                                          style: const TextStyle(),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Visibility(
                                      visible: commentDocuments[index - 1]
                                              .get('uid') ==
                                          FirebaseAuth
                                              .instance.currentUser!.uid,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        iconSize: 20,
                                        onPressed: () async {
                                          myDialog(
                                              widget.docId,
                                              commentDocuments[index - 1].id,
                                              '댓글');
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 1,
                              decoration:
                                  const BoxDecoration(color: Colors.black12),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                );
              }),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 1,
            decoration: const BoxDecoration(color: Colors.black12),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 90,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    width: MediaQuery.of(context).size.width - 80,
                    child: TextField(
                      controller: controller,
                      autofocus: widget.autoFocus,
                      autocorrect: false,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요.',
                        hintStyle: TextStyle(
                          fontSize: 15,
                        ),
                        contentPadding:
                            EdgeInsets.only(top: 0, left: 10, right: 10),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE8E8E8)),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('groups')
                            .doc(widget.groupCode)
                            .collection('posts')
                            .doc(widget.docId)
                            .collection('comments')
                            .doc()
                            .set({
                          'uid': FirebaseAuth.instance.currentUser!.uid,
                          'name':
                              FirebaseAuth.instance.currentUser!.displayName,
                          'profileImage':
                              FirebaseAuth.instance.currentUser!.photoURL,
                          'comment': controller.text,
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                        });

                        controller.clear();
                      },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
