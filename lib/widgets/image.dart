part of '../pages.dart';

class ImageFull extends StatefulWidget {
  final String imagePath;

  const ImageFull({required this.imagePath, Key? key}) : super(key: key);

  @override
  State<ImageFull> createState() => _ImageFullState();
}

class _ImageFullState extends State<ImageFull> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Hero(
          tag: 'fullImage',
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
