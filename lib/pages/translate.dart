part of '../pages.dart';

class ScanTranslateScreen extends StatefulWidget {
  final String imagePath;
  final String ocrText;

  ScanTranslateScreen({
    required this.imagePath,
    required this.ocrText,
    Key? key,
  }) : super(key: key);

  @override
  _ScanTranslateScreenState createState() => _ScanTranslateScreenState();
}

class _ScanTranslateScreenState extends State<ScanTranslateScreen> {
  bool _isLoading = false;
  final TextEditingController _titleController =
      TextEditingController(text: 'Document');
  final TextEditingController _textController = TextEditingController();
  final translator = GoogleTranslator();
  late String _croppedImagePath = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _textController.text = TextEditingController(text: widget.ocrText).text;
  }

  Future<void> _cropImage() async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.black,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio4x3,
            ],
            activeControlsWidgetColor: Colors.blue,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _croppedImagePath = croppedFile.path;
        });

        final detectedText = await _detectTextFromImage(_croppedImagePath);

        if (detectedText is String && detectedText.isEmpty) {
          showToast(
            context: context,
            text: "Text not detected from image.",
            color: Colors.orange,
            icon: Icons.warning,
          );
          return;
        }

        if (detectedText is String) {
          setState(() {
            _textController.text = detectedText.toString();
          });
        } else
          setState(() {
            _textController.text = detectedText.values.join("\n");
          });
      }
    } catch (e) {
      print("Terjadi kesalahan saat memotong gambar atau mendeteksi teks: $e");
    }
  }

  Future<Map<String, String>> _detectTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final imageFile = File(imagePath);
    final decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
    final imageWidth = decodedImage.width.toDouble();
    final imageHeight = decodedImage.height.toDouble();

    String title = '', subtitle = '', otherText = '';

    for (var block in recognizedText.blocks) {
      final boundingBox = block.boundingBox;
      final centerX = (boundingBox.left + boundingBox.right) / 2;
      final centerY = (boundingBox.top + boundingBox.bottom) / 2;

      if (centerX > imageWidth * 0.3 && centerX < imageWidth * 0.7) {
        if (centerY < imageHeight * 0.2 && title.isEmpty) {
          title = block.text.trim();
        } else if (centerY < imageHeight * 0.4 && subtitle.isEmpty) {
          subtitle = block.text.trim();
        } else {
          otherText += "${block.text.trim()}\n";
        }
      } else {
        otherText += "${block.text.trim()}\n";
      }
    }

    await textRecognizer.close();

    return {
      "title": title,
      "subtitle": subtitle,
      "otherText": otherText.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: '07489E'.toColor(),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.save,
              color: Colors.white,
            ),
          ),
        ],
        title: TextFormField(
          textCapitalization: TextCapitalization.sentences,
          textAlign: TextAlign.center,
          controller: _titleController,
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
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Detected Text:",
                style: GoogleFonts.poppins().copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                style: StyleText(),
                controller: _textController,
                maxLines: null,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(left: 15, right: 15),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Image Preview:",
                style: GoogleFonts.poppins().copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ImageFull(imagePath: widget.imagePath),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(widget.imagePath)),
                ),
              ),
              // _croppedImagePath.isNotEmpty &&
              //         File(_croppedImagePath).existsSync()
              //     ? Stack(
              //         children: [
              //           GestureDetector(
              //             onTap: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) =>
              //                       ImageFull(imagePath: _croppedImagePath),
              //                 ),
              //               );
              //             },
              //             child: ClipRRect(
              //               borderRadius: BorderRadius.circular(12),
              //               child: Image.file(File(widget.imagePath)),
              //             ),
              //           ),
              //           Positioned(
              //             top: 8,
              //             right: 8,
              //             child: FloatingActionButton(
              //               mini: true,
              //               onPressed: _cropImage,
              //               child: Icon(Icons.crop),
              //             ),
              //           ),
              //         ],
              //       )
              //     : Text(
              //         "Image not available.",
              //         style: StyleText(color: Colors.grey),
              //       ),
            ],
          ),
        ),
      ),
    );
  }
}
