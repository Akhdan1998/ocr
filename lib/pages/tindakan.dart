part of '../pages.dart';

class Tindakan extends StatelessWidget {
  final GlobalKey<PopupMenuButtonState> popupMenuKey;

  Tindakan({required this.popupMenuKey, Key? key}) : super(key: key);

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
                popupMenuKey.currentState?.showButtonMenu();
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
                      style: StyleText(color: color),
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
