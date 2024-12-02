part of '../pages.dart';

class DetailOcr extends StatefulWidget {
  final String file;
  final String title;

  DetailOcr({required this.file, required this.title});

  @override
  State<DetailOcr> createState() => _DetailOcrState();
}

class _DetailOcrState extends State<DetailOcr> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller.text = widget.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: '07489E'.toColor(),
        actions: [
          IconButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) {
                showToast(
                  context: context,
                  text: "Title cannot be empty",
                  color: Colors.orange,
                  icon: Icons.warning,
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  throw Exception("User not logged in");
                }
                final uid = user.uid;

                final docRef = FirebaseFirestore.instance
                    .collection('ocr_results')
                    .doc(uid);
                final snapshot = await docRef.get();
                final data = snapshot.data();

                if (data != null && data.containsKey('files')) {
                  final files = List<Map<String, dynamic>>.from(data['files']);
                  final fileIndex =
                      files.indexWhere((file) => file['title'] == widget.title);

                  if (fileIndex != -1) {
                    files[fileIndex]['title'] = newTitle;

                    await docRef.update({'files': files});

                    showToast(
                      context: context,
                      text: "Title updated successfully",
                      color: Colors.green,
                      icon: Icons.check,
                    );

                    // Navigator.pop(context);
                  } else {
                    throw Exception("File not found");
                  }
                }
              } catch (e) {
                print('ERRRRRRORRRRRROORORRR : $e');
                showToast(
                  context: context,
                  text: e.toString(),
                  color: Colors.red,
                  icon: Icons.error,
                );
              }
            },
            icon: Icon(Icons.save, color: Colors.white, size: 20),
          )
        ],
        leading: BackButton(color: Colors.white),
        title: TextFormField(
          textCapitalization: TextCapitalization.sentences,
          controller: controller,
          cursorColor: Colors.white,
          style: StyleText(color: Colors.white),
          decoration: InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.only(left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                "OCR Text:",
                style: GoogleFonts.poppins().copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: 8),
              SelectionArea(
                child: Text(
                  widget.file,
                  style: StyleText(fontSize: 13),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
