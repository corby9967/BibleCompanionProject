import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key, required this.groupCode});
  final String groupCode;

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  TextEditingController controller = TextEditingController();
  bool isButtonActive = false;

  XFile? _image;
  final ImagePicker picker = ImagePicker();
  String scannedText = "";

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

  Future getImage(ImageSource imageSource) async {
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      setState(() {
        _image = XFile(pickedFile.path);
      });
      getRecognizedText(_image!);
    }
  }

  void getRecognizedText(XFile image) async {
    final InputImage inputImage = InputImage.fromFilePath(image.path);

    final textRecognizer =
        GoogleMlKit.vision.textRecognizer(script: TextRecognitionScript.korean);

    RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    scannedText = "";
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText = "$scannedText${line.text}\n";
      }
    }

    setState(() {
      controller.text = scannedText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새로운 글'),
        actions: [
          TextButton(
            onPressed: () {
              if (isButtonActive) {
                addPost();
                Navigator.pop(context);
              }
            },
            child: Text(
              '올리기',
              style: TextStyle(
                  color: isButtonActive ? Colors.black : Colors.black26),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    hintText: '오늘의 묵상을 나눠주세요.',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Text(
                '텍스트 인식',
                style: TextStyle(fontSize: 18),
              ),
              Row(
                children: [
                  FilledButton(
                    onPressed: () {
                      getImage(ImageSource.camera);
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      getImage(ImageSource.gallery);
                    },
                    child: const Icon(Icons.image),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
