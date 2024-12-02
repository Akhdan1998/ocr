import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:ocr/firebase_options.dart';
import 'package:ocr/pages.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supercharged/supercharged.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: SplashScreen(),
        // child: OCRHomePage(),
        // child: OCRPage(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUid = prefs.getString('uid');

    if (savedUid != null) {
      print("Pengguna sudah login dengan UID: $savedUid");
      _navigateToHomePage();
    } else {
      _loginAnonymously();
    }
  }

  Future<void> _loginAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      String? uid = userCredential.user?.uid;

      if (uid != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', uid);

        print("Berhasil login anonim dengan UID: $uid");
      }

      _navigateToHomePage();
    } catch (e) {
      print("Gagal login anonim: $e");
    }
  }

  void _navigateToHomePage() {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/scan.png',
            scale: 7,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late PageController controller;
  final ImagePicker _picker = ImagePicker();
  bool isPopupOpen = false;
  final GlobalKey<PopupMenuButtonState> popupMenuKey =
      GlobalKey<PopupMenuButtonState>();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    context.loaderOverlay.hide();
    super.dispose();
  }

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

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
    controller.animateToPage(
      _selectedIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
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
            builder: (context) => OcrResultScreen(
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
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: PageView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: controller,
                    children: [
                      Beranda(),
                      FileSaya(),
                      Tindakan(popupMenuKey: popupMenuKey),
                      Pengaturan(),
                    ],
                  ),
                ),
                BottomNavigationBar(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  currentIndex: _selectedIndex,
                  selectedItemColor: '07489E'.toColor(),
                  onTap: _navigateBottomBar,
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(
                      label: 'Home',
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                    ),
                    BottomNavigationBarItem(
                      label: 'My file',
                      icon: Icon(Icons.folder_outlined),
                      activeIcon: Icon(Icons.folder),
                    ),
                    BottomNavigationBarItem(
                      label: 'Action',
                      icon: Icon(Icons.pages_outlined),
                      activeIcon: Icon(Icons.pages),
                    ),
                    BottomNavigationBarItem(
                      label: 'Settings',
                      icon: Icon(Icons.settings_outlined),
                      activeIcon: Icon(Icons.settings),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 30,
              bottom: 27,
              child: PopupMenuButton(
                key: popupMenuKey,
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: '07489E'.toColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPopupOpen ? Icons.close : Icons.add,
                    key: ValueKey<bool>(isPopupOpen),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                offset: Offset(115, -120),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'gallery',
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: '07489E'.toColor(),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Gallery',
                            style: StyleText(),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.photo_library, color: Colors.transparent),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'camera',
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: '07489E'.toColor(),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Camera',
                            style: StyleText(),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.camera_alt, color: Colors.transparent),
                        ],
                      ),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'gallery') {
                    _getImage(ImageSource.gallery);
                  } else if (value == 'camera') {
                    _getImage(ImageSource.camera);
                  }
                },
                onCanceled: () {
                  setState(() {
                    isPopupOpen = false;
                  });
                },
                onOpened: () {
                  setState(() {
                    isPopupOpen = !isPopupOpen;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}