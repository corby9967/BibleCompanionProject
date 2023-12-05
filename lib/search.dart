import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:project/detail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage(
      {super.key, required this.groupName, required this.groupCode});

  final String groupName;
  final String groupCode;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController controller = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    controller.clear();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        scrolledUnderElevation: 0,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 73,
                  height: 50,
                  child: TextField(
                    controller: controller,
                    autocorrect: false,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '검색할 단어를 입력하세요.',
                      hintStyle: TextStyle(
                        fontSize: 15,
                      ),
                      contentPadding: EdgeInsets.only(left: 5, right: 5),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      setState(() {
                        searchText = controller.text;
                        searchText = searchText.toLowerCase();
                      });
                    },
                    icon: const Icon(Icons.search))
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 1,
              decoration: const BoxDecoration(color: Colors.black12),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SizedBox(
                width: MediaQuery.of(context).size.height - 50,
                child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupCode)
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      List<DocumentSnapshot> posts = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          String content = posts[index]['content'];
                          String name = posts[index]['name'];
                          String uid = posts[index]['uid'];
                          String docId = posts[index].id;
                          String url = posts[index]['profileImage'];
                          var date = DateTime.fromMillisecondsSinceEpoch(
                              posts[index]['timestamp']);
                          String newDate =
                              '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}:${date.second}';

                          if (content.toLowerCase().contains(searchText)) {
                            return ListTile(
                              leading: ClipOval(
                                child: Image.network(
                                  url,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.fill,
                                ),
                              ),
                              title: Text(
                                content,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 15),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              onTap: () {
                                Get.to(() => DetailPage(
                                    groupCode: widget.groupCode,
                                    name: name,
                                    date: newDate,
                                    content: content,
                                    profile: url,
                                    uid: uid,
                                    docId: docId,
                                    autoFocus: false));
                              },
                            );
                          } else {
                            return Container();
                          }
                        },
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
