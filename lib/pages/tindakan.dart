part of '../pages.dart';

class Tindakan extends StatefulWidget {
  final GlobalKey<PopupMenuButtonState> popupMenuKey;

  Tindakan({required this.popupMenuKey, Key? key}) : super(key: key);

  @override
  State<Tindakan> createState() => _TindakanState();
}

class _TindakanState extends State<Tindakan> {
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;
  bool isSlidable = false;

  Future<File> preprocessImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        final grayscaleImage = img.grayscale(originalImage);
        final enhancedImage = img.contrast(grayscaleImage, contrast: 150);
        final preprocessedImage = File(imageFile.path)
          ..writeAsBytesSync(img.encodeJpg(enhancedImage));
        return preprocessedImage;
      }
    } catch (e) {
      print("Error saat memproses gambar: $e");
    }

    return imageFile;
  }

  Future<void> _getImage(ImageSource source) async {
    context.loaderOverlay.show();

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
        print("Pemilihan gambar dibatalkan.");
        context.loaderOverlay.hide();
        setState(() {
          isProcessing = false;
        });
        return;
      }

      File imageFile = File(pickedFile.path);

      imageFile = await preprocessImage(imageFile);

      final textRecognizer = GoogleMlKit.vision.textRecognizer();

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final List<String> textBlocks =
      recognizedText.blocks.map((block) => block.text.trim()).toList();

      final title = textBlocks.isNotEmpty ? textBlocks.first : '';
      final subtitle = textBlocks.length > 1 ? textBlocks[1] : '';
      final otherText =
      textBlocks.length > 2 ? textBlocks.sublist(2).join('\n') : '';
      final formattedText = "$title\n$subtitle\n\n$otherText".trim();

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanTranslateScreen(
              imagePath: imageFile.path,
              ocrText: formattedText,
            ),
          ),
        );
      }
    } catch (e, stacktrace) {
      print("Terjadi kesalahan saat memproses gambar: $e");
      print("Terjadi kesalahan saat memproses gambar: $stacktrace");
    } finally {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: SizedBox(),
        backgroundColor: '07489E'.toColor(),
        title: Text(
          'Action',
          style: StyleText(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan',
              style: StyleText(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            _ActionCard(
              title: 'Document',
              subtitle: 'Scan Documents',
              imagePath: 'assets/pindai.png',
              imageScale: 30,
              onTap: () {
                widget.popupMenuKey.currentState?.showButtonMenu();
              },
            ),
            SizedBox(height: 10),
            _ActionCard(
              title: 'QR Code',
              subtitle: 'Read QR code',
              imagePath: 'assets/barcode.png',
              imageScale: 60,
              onTap: () async {
                final scannedCode = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => QRCodeScannerScreen()),
                );

                if (scannedCode != null) {
                  print('QR Code: $scannedCode');
                } else {
                  showToast(
                    context: context,
                    text: 'No QR code detected.',
                    color: Colors.redAccent,
                    icon: Icons.error,
                  );
                  print('No QR code detected.');
                }
              },
            ),
            SizedBox(height: 10),
            // Slidable(
            //   startActionPane: ActionPane(motion: ScrollMotion(), children: [
            //     SlidableAction(
            //       borderRadius: BorderRadius.circular(10),
            //       onPressed: (context) => _getImage(ImageSource.gallery),
            //       backgroundColor: '07489E'.toColor().withOpacity(0.2),
            //       foregroundColor: '07489E'.toColor(),
            //       icon: Icons.photo_library,
            //       label: 'Gallery',
            //       // spacing: 4,
            //     ),
            //     SlidableAction(
            //       borderRadius: BorderRadius.circular(10),
            //       onPressed: (context) => _getImage(ImageSource.camera),
            //       backgroundColor: '07489E'.toColor().withOpacity(0.2),
            //       foregroundColor: '07489E'.toColor(),
            //       icon: Icons.camera_alt,
            //       label: 'Camera',
            //       // spacing: 4,
            //     ),
            //   ]),
            //   child: _ActionCard(
            //     title: 'Document Translate',
            //     subtitle: 'Scan Documents Translate',
            //     imagePath: 'assets/pindai.png',
            //     imageScale: 30,
            //     onTap: () {},
            //   ),
            // ),
            Column(
              children: [
                _ActionCard(
                  title: 'Document Translate',
                  subtitle: 'Scan Documents Translate',
                  imagePath: 'assets/pindai.png',
                  imageScale: 30,
                  onTap: () {
                    setState(() {
                      isSlidable = !isSlidable;
                    });
                  },
                ),
                SizedBox(height: 10),
                (isSlidable == true)
                    ? Container(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _getImage(ImageSource.gallery);
                              },
                              child: Container(
                                padding: EdgeInsets.only(top: 5, bottom: 5),
                                width: 185,
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: '07489E'.toColor().withOpacity(0.2),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      color: '07489E'.toColor(),
                                    ),
                                    Text(
                                      'Gallery',
                                      style: StyleText(
                                        fontSize: 13,
                                        color: '07489E'.toColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                _getImage(ImageSource.camera);
                              },
                              child: Container(
                                padding: EdgeInsets.only(top: 5, bottom: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: '07489E'.toColor().withOpacity(0.2),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: '07489E'.toColor(),
                                    ),
                                    Text(
                                      'Camera',
                                      style: StyleText(
                                        fontSize: 13,
                                        color: '07489E'.toColor(),
                                      ),
                                    ),
                                  ],
                                ),
                                width: 185,
                                height: 54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final double imageScale;
  final VoidCallback onTap;

  _ActionCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.imageScale = 1.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = '07489E'.toColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  scale: imageScale,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: StyleText(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: StyleText(color: color, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
