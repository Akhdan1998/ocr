part of '../pages.dart';

class OcrResultScreen extends StatefulWidget {
  final String imagePath;
  final String ocrText;

  OcrResultScreen({
    required this.imagePath,
    required this.ocrText,
    Key? key,
  }) : super(key: key);

  @override
  _OcrResultScreenState createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController(text: 'Document');
  final Uuid uuid = Uuid();

  late String _croppedImagePath;

  @override
  void initState() {
    super.initState();
    _textController.text = TextEditingController(text: widget.ocrText).text;
    _croppedImagePath = widget.imagePath;

    if (_textController.text.isEmpty || _textController.text.trim().isEmpty) {
      showToast(
        context: context,
        text: "No text detected to export.",
        color: Colors.orange,
        icon: Icons.warning,
      );
      return null;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _shareContent(String text) async {
    if (_textController.text.isEmpty || _textController.text.trim().isEmpty) {
      showToast(
        context: context,
        text: "No text detected to export.",
        color: Colors.orange,
        icon: Icons.warning,
      );
      return null;
    }

    try {
      context.loaderOverlay.show();

      await Share.share(text);

      context.loaderOverlay.hide();
    } catch (e) {
      context.loaderOverlay.hide();

      print("Error saat berbagi: $e");
      showToast(
        context: context,
        text: e.toString(),
        color: Colors.redAccent,
        icon: Icons.error,
      );
    }
  }

  Future<void> _saveToFirestore({
    required String ocrText,
    required String pdfPath,
    required String wordPath,
    // required double fileSizeMB,
    required String fileSize,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      final uid = user.uid;

      final uniqueId = uuid.v4();
      final timestamp = DateTime.now();
      final currentTitle = _titleController.text.trim();

      if (currentTitle.isEmpty) {
        showToast(
          context: context,
          text: "Title cannot be empty.",
          color: Colors.orange,
          icon: Icons.warning,
        );
        return;
      }

      final dataToAdd = {
        'id': uniqueId,
        'ocrText': ocrText,
        'pdfPath': pdfPath,
        'wordPath': wordPath,
        // 'fileSizeMB': fileSizeMB,
        'fileSizeKB': fileSize,
        'timestamp': timestamp.toIso8601String(),
        'title': _titleController.text,
      };

      await FirebaseFirestore.instance.collection('ocr_results').doc(uid).set({
        'files': FieldValue.arrayUnion([dataToAdd]),
      }, SetOptions(merge: true));

      print("Data berhasil disimpan ke Firestore sebagai list.");

      setState(() {
        _titleController.text = 'Document';
      });
      context.loaderOverlay.hide();
    } catch (e) {
      context.loaderOverlay.hide();
      print("Error menyimpan ke Firestore: $e");
      showToast(
        context: context,
        text: "Error saving document",
        color: Colors.red,
        icon: Icons.error,
      );
    }
  }

  Future<String?> _saveAndOpenFile(String text, String fileType) async {
    if (_textController.text.isEmpty || _textController.text.trim().isEmpty) {
      showToast(
        context: context,
        text: "No text detected to export.",
        color: Colors.orange,
        icon: Icons.warning,
      );
      return null;
    }

    if (_titleController.text.trim().isEmpty) {
      showToast(
        context: context,
        text: "Title cannot be empty.",
        color: Colors.orange,
        icon: Icons.warning,
      );
      return null;
    }

    try {
      context.loaderOverlay.show();

      final output = await getApplicationDocumentsDirectory();
      final uniqueName =
          "${_titleController.text}_${DateTime.now().millisecondsSinceEpoch}.$fileType";
      final filePath = "${output.path}/$uniqueName";

      if (fileType == "pdf") {
        await _generatePdfFile(text, filePath);
      } else if (fileType == "docx") {
        await _generateDocxFile(text, filePath);
      } else {
        throw Exception("Unsupported file type: $fileType");
      }

      // final fileSizeBytes = File(filePath).lengthSync();
      // final fileSizeMB = fileSizeBytes / (1024 * 1024);

      final file = File(filePath);
      final fileSizeInBytes = file.lengthSync();
      final fileSizeInKB = (fileSizeInBytes / 1024).toStringAsFixed(2);

      await _saveToFirestore(
        ocrText: text,
        pdfPath: fileType == "pdf" ? filePath : "",
        wordPath: fileType == "docx" ? filePath : "",
        // fileSizeMB: fileSizeMB,
        fileSize: fileSizeInKB,
      );

      await OpenFile.open(filePath);
      context.loaderOverlay.hide();
      return filePath;
    } catch (e) {
      context.loaderOverlay.hide();
      print("Error: $e");
      showToast(
        context: context,
        text: e.toString(),
        color: Colors.red,
        icon: Icons.error,
      );
      return null;
    }
  }

  Future<void> _generatePdfFile(String text, String filePath) async {
    final pdf = pw.Document();
    final textLines = text.split("\n");
    const linesPerPage = 40;

    for (int i = 0; i < textLines.length; i += linesPerPage) {
      final pageText = textLines.skip(i).take(linesPerPage).join("\n");
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Text(
            maxLines: null,
            pageText,
            textAlign: pw.TextAlign.justify,
          ),
        ),
      );
    }

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
  }

  Future<void> _generateDocxFile(String text, String filePath) async {
    try {
      final docx = await rootBundle.load("assets/word.docx");
      print("Template loaded, size: ${docx.lengthInBytes} bytes");

      final template = await DocxTemplate.fromBytes(docx.buffer.asUint8List());
      print("Template parsed successfully");

      final content = Content();
      content.add(TextContent('body', text));
      print("Content added successfully");

      final generatedFile = await template.generate(content);
      if (generatedFile == null) {
        print("Generated file is null. Check the template or content.");
        throw Exception("Failed to generate DOCX content");
      }

      final file = File(filePath);
      await file.writeAsBytes(generatedFile);
      print("DOCX file generated and saved at $filePath");
    } catch (e) {
      print("Error in _generateDocxFile: $e");
      rethrow;
    }
  }

  Future<void> _cropImage() async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: _croppedImagePath,
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
    return GlobalLoaderOverlay(
      duration: Durations.medium4,
      reverseDuration: Durations.medium4,
      overlayColor: Colors.transparent,
      overlayWidgetBuilder: (_) {
        return Center(
          child: SpinKitWaveSpinner(
            waveColor: '07489E'.toColor(),
            color: '07489E'.toColor(),
            size: 100,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: BackButton(color: Colors.white),
          backgroundColor: '07489E'.toColor(),
          actions: [
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              offset: Offset(-15, 45),
              color: Colors.white,
              onSelected: (value) async {
                if (value == "PDF") {
                  _saveAndOpenFile(_textController.text, "pdf");
                } else if (value == "WORD") {
                  _saveAndOpenFile(_textController.text, "docx");
                } else if (value == "SHARE_TEXT") {
                  await _shareContent(_textController.text);
                }
              },
              itemBuilder: (context) => [
                _buildPopupMenuItem(
                    Icons.picture_as_pdf, "Export to PDF", "PDF"),
                _buildPopupMenuItem(Icons.article, "Export to Word", "WORD"),
                _buildPopupMenuItem(Icons.share, "Share", "SHARE_TEXT"),
              ],
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
        body: Container(
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
              Expanded(
                flex: 3,
                child: TextField(
                  style: StyleText(),
                  controller: _textController,
                  maxLines: null,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 15, right: 15),
                    border: OutlineInputBorder(),
                  ),
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
              _croppedImagePath.isNotEmpty &&
                      File(_croppedImagePath).existsSync()
                  ? Expanded(
                      flex: 2,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ImageFull(imagePath: _croppedImagePath),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_croppedImagePath)),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FloatingActionButton(
                              mini: true,
                              onPressed: _cropImage,
                              child: Icon(Icons.crop),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      "Image not available.",
                      style: StyleText(color: Colors.grey),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: '07489E'.toColor(),
          ),
          SizedBox(width: 10),
          Text(
            text,
            style: StyleText(),
          ),
        ],
      ),
    );
  }
}