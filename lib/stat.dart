import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:project/home.dart';

class StatPage extends StatefulWidget {
  const StatPage({super.key, required this.groupCode});
  final String groupCode;

  @override
  State<StatPage> createState() => _StatPageState();
}

class _StatPageState extends State<StatPage> {
  int numOfDocs = 0;
  int numOfDocs2 = 0;
  int numOfUsers = 0;
  int numOfPrays = 0;

  @override
  void initState() {
    super.initState();
  }

  Widget lastRidingProgress(double percent) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Container(
          width: MediaQuery.of(context).size.width - 51,
          alignment: FractionalOffset(percent, 1 - percent),
          child: const FractionallySizedBox(
            child: Icon(Icons.book, size: 20),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0'),
            LinearPercentIndicator(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              percent: percent,
              lineHeight: 10,
              animation: true,
              backgroundColor: Colors.black12,
              progressColor: Theme.of(context).colorScheme.primary,
              barRadius: const Radius.circular(4),
              width: MediaQuery.of(context).size.width - 50,
            ),
            const Text('7'),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        leading: IconButton(
          onPressed: () {
            Get.to(() => HomePage(groupCode: widget.groupCode));
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          const SizedBox(height: 40),
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupCode)
                  .collection('posts')
                  .where('uid',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (BuildContext context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  numOfDocs =
                      snapshot.data != null ? snapshot.data!.docs.length : 0;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이번주 나의 QT 횟수',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    lastRidingProgress(numOfDocs / 7),
                    Text('총 $numOfDocs회'),
                  ],
                );
              }),
          const SizedBox(height: 50),
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupCode)
                  .collection('posts')
                  .snapshots(),
              builder: (BuildContext context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  numOfDocs2 =
                      snapshot.data != null ? snapshot.data!.docs.length : 0;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupCode)
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      numOfUsers = snapshot.data?.docs.length ?? 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '이번주 전체 QT 횟수 평균',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          lastRidingProgress(numOfDocs2 / numOfUsers / 7),
                          Text('총 ${numOfDocs2 / numOfUsers}회'),
                          const SizedBox(height: 50),
                          const Text(
                            '이번주 전체 기도제목 & QT 횟수 비교',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('groups')
                                      .doc(widget.groupCode)
                                      .collection('prays')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    numOfPrays =
                                        snapshot.data?.docs.length ?? 0;

                                    return CircularPercentIndicator(
                                      radius: 110.0,
                                      animation: true,
                                      animationDuration: 1300,
                                      lineWidth: 30,
                                      percent: numOfDocs2 /
                                          (numOfDocs2 + numOfPrays),
                                      center: const Text(
                                        '기도제목 / QT',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      circularStrokeCap: CircularStrokeCap.butt,
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      progressColor: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    );
                                  }),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                );
              }),
        ],
      ),
    );
  }
}
