part of '../pages.dart';

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  late CameraController _cameraController;
  late BarcodeScanner _barcodeScanner;
  String? _barcodeResult;
  final qrKey = GlobalKey();
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _barcodeScanner = BarcodeScanner();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController =
            CameraController(cameras.first, ResolutionPreset.high);
        await _cameraController.initialize();
        setState(() => isCameraInitialized = true);
      } else {
        showToast(
          context: context,
          text: 'No camera available',
          color: Colors.redAccent,
          icon: Icons.error,
        );
      }
    } catch (e) {
      print('Failed to initialize camera');
      showToast(
        context: context,
        text: e.toString(),
        color: Colors.redAccent,
        icon: Icons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: '07489E'.toColor(),
        title: Text(
          'Scan QR Code',
          style: StyleText(color: Colors.white, fontSize: 15),
        ),
      ),
      body: isCameraInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: 8 / 15.1,
                child: CameraPreview(_cameraController),
              ),
            )
          : Center(child: CircularProgressIndicator(color: '07489E'.toColor(),),),
      floatingActionButton: FloatingActionButton(
        backgroundColor: '07489E'.toColor(),
        onPressed: _scanBarcode,
        child: Icon(
          Icons.camera,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final image = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final result = barcodes.first.rawValue!;
        _showBarcodeDialog(context, result);
      } else {
        showToast(
          context: context,
          text: 'No barcode detected',
          color: Colors.redAccent,
          icon: Icons.error,
        );
      }
    } catch (e) {
      print('Error saat memindai barcode: $e');
    }
  }

  void _showBarcodeDialog(BuildContext context, String result) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dialog",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Barcode Results',
                style: StyleText(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              barcode_widget.BarcodeWidget(
                key: qrKey,
                data: result,
                barcode: barcode_widget.Barcode.qrCode(),
                width: 200,
                height: 80,
              ),
              SizedBox(height: 10),
              Text(
                result,
                style: StyleText(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: style,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Close',
                      style: StyleText(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      _saveQRCodeToDevice(result);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      width: 90,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: '07489E'.toColor(),
                        ),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Save',
                        style: StyleText(
                          color: '07489E'.toColor(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      transitionBuilder: (_, anim1, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeInOut),
        child: child,
      ),
    );
  }

  Future<void> _saveQRCodeToDevice(String data) async {
    try {
      final renderObject =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject == null) throw Exception('Render boundary not found');

      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/qrcode.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData!.buffer.asUint8List());

      showToast(
        context: context,
        text: 'QR Code saved',
        color: Colors.green,
        icon: Icons.check,
      );
    } catch (e) {
      showToast(
        context: context,
        text: e.toString(),
        color: Colors.green,
        icon: Icons.check,
      );
      print('Error saving QR Code');
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _barcodeScanner.close();
    super.dispose();
  }
}
