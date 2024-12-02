// part of '../pages.dart';
//
// class OCRHomePage extends StatefulWidget {
//   @override
//   _OCRHomePageState createState() => _OCRHomePageState();
// }
//
// class _OCRHomePageState extends State<OCRHomePage> {
//   final ImagePicker _picker = ImagePicker();
//   File? _image;
//   final TextEditingController _ocrTextController = TextEditingController();
//   int _selectedIndex = 0;
//
//   Future<void> _getImage(ImageSource source) async {
//     final pickedFile = await _picker.pickImage(source: source);
//
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//       _performOCR(_image!);
//     }
//   }
//
//   Future<void> _performOCR(File image) async {
//     try {
//       final imageBytes = await image.readAsBytes();
//       final decodedImage = img.decodeImage(imageBytes);
//
//       if (decodedImage == null) {
//         showToast(
//           context: context,
//           text: 'Invalid image.',
//           color: Colors.redAccent,
//           icon: Icons.error,
//         );
//         return;
//       }
//
//       final imageWidth = decodedImage.width.toDouble();
//
//       final inputImage = InputImage.fromFile(image);
//       final textRecognizer = GoogleMlKit.vision.textRecognizer();
//       final recognizedText = await textRecognizer.processImage(inputImage);
//
//       String title = '', subtitle = '', otherText = '';
//
//       for (var block in recognizedText.blocks) {
//         final boundingBox = block.boundingBox;
//         final centerX = boundingBox != null
//             ? (boundingBox.left + boundingBox.right) / 2
//             : 0.0;
//
//         if (centerX > imageWidth * 0.4 && centerX < imageWidth * 0.6) {
//           if (title.isEmpty) {
//             title = block.text.trim();
//           } else if (subtitle.isEmpty) {
//             subtitle = block.text.trim();
//           } else {
//             otherText += "${block.text.trim()}\n";
//           }
//         } else {
//           otherText += "${block.text.trim()}\n";
//         }
//       }
//
//       final formattedText = "$title\n$subtitle\n\n$otherText".trim();
//
//       setState(() {
//         _ocrTextController.text = formattedText;
//       });
//
//       await textRecognizer.close();
//     } catch (e) {
//       showToast(
//         context: context,
//         text: 'An error occurred while processing the image.',
//         color: Colors.redAccent,
//         icon: Icons.error,
//       );
//       debugPrint('Error in _performOCR: $e');
//     }
//   }
//
//   // Future<void> _performOCR(File image) async {
//   //   final inputImage = InputImage.fromFile(image);
//   //   final textRecognizer = GoogleMlKit.vision.textRecognizer();
//   //   final RecognizedText recognizedText =
//   //   await textRecognizer.processImage(inputImage);
//   //
//   //   String extractedText =
//   //   recognizedText.blocks.map((block) => block.text).join("\n\n");
//   //
//   //   setState(() {
//   //     _ocrTextController.text = extractedText;
//   //   });
//   //
//   //   await textRecognizer.close();
//   // }
//
//   Future<void> _saveFile(String extension, Future<void> Function(String) saveFunction) async {
//     final content = _ocrTextController.text.trim();
//     if (content.isEmpty) {
//       showToast(
//         context: context,
//         text: 'Empty text, cannot be saved.',
//         color: Colors.green,
//         icon: Icons.check,
//       );
//       return;
//     }
//
//     final directory = await getApplicationDocumentsDirectory();
//     final filePath = '${directory.path}/hasil_ocr.$extension';
//     await saveFunction(filePath);
//     await OpenFile.open(filePath);
//   }
//
//   Future<void> _saveAsTxt(String filePath) async {
//     final content = _ocrTextController.text.trim();
//     await File(filePath).writeAsString(content);
//     showToast(
//       context: context,
//       text: filePath,
//       color: Colors.redAccent,
//       icon: Icons.error,
//     );
//   }
//
//   Future<void> _saveAsPdf(String filePath) async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) => pw.Text(_ocrTextController.text),
//       ),
//     );
//     await File(filePath).writeAsBytes(await pdf.save());
//   }
//
//   Future<void> _saveAsDocx(String filePath) async {
//     final docxTemplate = await rootBundle.load('assets/word.docx');
//     final docx =
//     await DocxTemplate.fromBytes(docxTemplate.buffer.asUint8List());
//     Content content = Content();
//     content.add(TextContent("ocr_text", _ocrTextController.text));
//     final docxBytes = await docx.generate(content);
//
//     if (docxBytes != null) {
//       await File(filePath).writeAsBytes(docxBytes);
//     } else {
//       showToast(
//         context: context,
//         text: 'Failed to save .docx file',
//         color: Colors.redAccent,
//         icon: Icons.error,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               if (_image != null) Image.file(_image!),
//               SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () => _getImage(ImageSource.camera),
//                     child: Text('Take Picture'),
//                   ),
//                   SizedBox(width: 20),
//                   ElevatedButton(
//                     onPressed: () => _getImage(ImageSource.gallery),
//                     child: Text('Select Gallery'),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               Text('Hasil OCR :',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 20),
//                 child: TextField(
//                   controller: _ocrTextController,
//                   maxLines: null,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() => _selectedIndex = index);
//           switch (index) {
//             case 0:
//               _saveFile('txt', _saveAsTxt);
//               break;
//             case 1:
//               _saveFile('pdf', _saveAsPdf);
//               break;
//             case 2:
//               _saveFile('docx', _saveAsDocx);
//               break;
//             default:
//               break;
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'TXT'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.picture_as_pdf), label: 'PDF'),
//           BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Word'),
//         ],
//       ),
//     );
//   }
// }