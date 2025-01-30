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

      // if (context.mounted) {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => ScanTranslateScreen(
      //         imagePath: imageFile.path,
      //         ocrText: formattedText,
      //       ),
      //     ),
      //   );
      // }
      _showLanguageSelectionDialog(context, imageFile.path, formattedText);
    } catch (e, stacktrace) {
      print("Terjadi kesalahan saat memproses gambar: $e");
      print("Terjadi kesalahan saat memproses gambar: $stacktrace");
    } finally {
      context.loaderOverlay.hide();
    }
  }

  // Future<void> _showLanguageSelectionDialog(
  //     BuildContext context, String imagePath, String ocrText) async {
  //   final translator = GoogleTranslator();
  //   showBottomSheet(
  //       elevation: 0,
  //       context: context,
  //       builder: (BuildContext context) {
  //         return Container(
  //           width: MediaQuery.of(context).size.width,
  //           padding: EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.grey.withOpacity(0.5),
  //                 spreadRadius: 2,
  //                 blurRadius: 3,
  //                 offset: Offset(0, 0),
  //               ),
  //             ],
  //             color: Colors.white,
  //             borderRadius: BorderRadius.only(
  //               topRight: Radius.circular(30),
  //               topLeft: Radius.circular(30),
  //             ),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextButton(
  //                 onPressed: () async {
  //                   context.loaderOverlay.show();
  //                   await _translateAndPrint(
  //                           translator, ocrText, 'en', imagePath)
  //                       .whenComplete(() {
  //                     Navigator.pop(context);
  //                   });
  //                 },
  //                 child: Text("English", style: StyleText(),),
  //               ),
  //               Divider(height: 1),
  //               TextButton(
  //                 onPressed: () async {
  //                   context.loaderOverlay.show();
  //                   await _translateAndPrint(
  //                           translator, ocrText, 'ko', imagePath)
  //                       .whenComplete(() {
  //                     Navigator.pop(context);
  //                   });
  //                 },
  //                 child: Text(
  //                   "Korean",
  //                   style: StyleText(),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       });
  // }
  //
  // Future<void> _translateAndPrint(
  //     GoogleTranslator translator, String text, String targetLanguage, String imagePath) async {
  //   try {
  //     final translation = await translator.translate(text, to: targetLanguage);
  //     print('Translated Text ($targetLanguage): ${translation.text}');
  //     Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => ScanTranslateScreen(
  //               imagePath: imagePath,
  //               ocrText: translation.text,
  //             ),
  //           ),
  //         );
  //   } catch (e) {
  //     print('Error during translation: $e');
  //   } finally {
  //     context.loaderOverlay.hide();
  //   }
  // }

  Future<void> _showLanguageSelectionDialog(
      BuildContext context, String imagePath, String ocrText) async {
    final translator = GoogleTranslator();

    Future<void> _handleTranslation(String targetLanguage) async {
      try {
        context.loaderOverlay.show();
        final translation =
            await translator.translate(ocrText, to: targetLanguage);
        print('Translated Text ($targetLanguage): ${translation.text}');
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OcrResultScreen(
              imagePath: imagePath,
              ocrText: translation.text,
            ),
          ),
        );
      } catch (e) {
        print('Error during translation: $e');
      } finally {
        context.loaderOverlay.hide();
      }
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageButton(
                  context, "English", () => _handleTranslation('en')),
              Divider(),
              _buildLanguageButton(
                  context, "Korean", () => _handleTranslation('ko')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(
      BuildContext context, String language, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(language, style: StyleText(fontSize: 16)),
    );
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
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Options',
              style: StyleText(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            _ActionCard(
              title: 'Document',
              subtitle: 'Digitize your physical documents',
              icon: Icons.description,
              onTap: () {
                widget.popupMenuKey.currentState?.showButtonMenu();
              },
            ),
            SizedBox(height: 10),
            _ActionCard(
              title: 'QR Code Scanner',
              subtitle: 'Scan and read QR codes',
              icon: Icons.qr_code_scanner,
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
            Column(
              children: [
                _ActionCard(
                  title: 'Document Translation',
                  subtitle: 'Translate scanned documents',
                  icon: Icons.translate,
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
                                width: 185,
                                height: 54,
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
  final IconData icon;
  final VoidCallback onTap;

  _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
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
                Icon(icon, size: 40, color: '07489E'.toColor()),
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
