part of '../pages.dart';

class FileSaya extends StatefulWidget {
  FileSaya({super.key});

  @override
  State<FileSaya> createState() => _FileSayaState();
}

class _FileSayaState extends State<FileSaya> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final Map<String, TextEditingController> _controllers = {};

  Stream<DocumentSnapshot<Map<String, dynamic>>> _ocrResultStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    final uid = user.uid;

    return FirebaseFirestore.instance
        .collection('ocr_results')
        .doc(uid)
        .snapshots();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: '07489E'.toColor(),
        title: Column(
          children: [
            Text(
              'My File',
              style: StyleText(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 5),
            _searchBar(context),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ocrResultStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: '07489E'.toColor()),
            );
          }
          if (snapshot.hasError) {
            return Container();
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "No data available",
                style: StyleText(color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.data();
          if (data == null || !data.containsKey('files')) {
            return Container();
          }

          final List files = data['files'];

          files.sort((a, b) {
            final timestampA = a['timestamp'] ?? '';
            final timestampB = b['timestamp'] ?? '';
            if (timestampA is String && timestampB is String) {
              return DateTime.parse(timestampB)
                  .compareTo(DateTime.parse(timestampA));
            }
            return 0;
          });

          final List filteredFiles = files.where((file) {
            final fileTitle = file['title']?.toString().toLowerCase() ?? '';
            return fileTitle.contains(_searchQuery.toLowerCase());
          }).toList();

          final List exactMatches = filteredFiles.where((file) {
            final fileTitle = file['title']?.toString().toLowerCase() ?? '';
            return fileTitle == _searchQuery.toLowerCase();
          }).toList();

          final List partialMatches = filteredFiles.where((file) {
            final fileTitle = file['title']?.toString().toLowerCase() ?? '';
            return fileTitle != _searchQuery.toLowerCase();
          }).toList();

          final List orderedFiles = [...exactMatches, ...partialMatches];

          if (orderedFiles.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isNotEmpty ? "No files found" : "",
                style: StyleText(color: Colors.grey),
              ),
            );
          }

          return Container(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.start,
              children: orderedFiles.map<Widget>(_buildFileWidget).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileWidget(dynamic file) {
    final id = file['id'];
    final ocrText = file['ocrText'] ?? '-';
    final pdfPath = file['pdfPath'] ?? '';
    final wordPath = file['wordPath'] ?? '';
    final title = file['title'] ?? '-';
    // final sizeMB = file['fileSizeMB'] != null
    //     ? "${file['fileSizeMB'].toStringAsFixed(2)} MB"
    //     : '-';
    final sizeKB = file['fileSizeKB'] != null
        ? "${double.tryParse(file['fileSizeKB'].toString())?.toStringAsFixed(2) ?? '0.00'} KB"
        : '-';
    final timestamp = file['timestamp'] as String?;
    final fileId = timestamp ?? UniqueKey().toString();

    _controllers.putIfAbsent(fileId, () => TextEditingController(text: title));

    return Container(
      width: 84,
      height: 109,
      // color: Colors.red,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showFileOptions(
              context,
              ocrText,
              pdfPath,
              wordPath,
              title,
            ),
            onLongPress: () => _showFitureOptions(
              context,
              ocrText,
              pdfPath,
              wordPath,
              title,
              id,
              // sizeMB,
              sizeKB,
            ),
            child: Container(
              padding: EdgeInsets.all(10),
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: '07489E'.toColor(),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.start,
                children: [
                  if (ocrText.isNotEmpty)
                    Icon(Icons.text_fields, color: Colors.white),
                  if (pdfPath.isNotEmpty)
                    Icon(Icons.picture_as_pdf, color: Colors.white),
                  if (wordPath.isNotEmpty)
                    Icon(Icons.article, color: Colors.white),
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: StyleText(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showFitureOptions(
    BuildContext context,
    String ocrText,
    String pdfPath,
    String wordPath,
    String title,
    String fileId,
    String size,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: StyleText(fontWeight: FontWeight.w600),
              ),
              Text(
                size,
                style: StyleText(fontSize: 13),
              ),
              _buildOption(
                Icons.share,
                'Share',
                () async {
                  try {
                    List<XFile> filesToShare = [];

                    if (pdfPath.isNotEmpty) filesToShare.add(XFile(pdfPath));
                    if (wordPath.isNotEmpty) filesToShare.add(XFile(wordPath));

                    if (filesToShare.isNotEmpty) {
                      await Share.shareXFiles(
                        filesToShare,
                        text: title,
                      );
                    } else if (ocrText.isNotEmpty) {
                      await Share.share("$ocrText\n$title");
                    } else {
                      showToast(
                        context: context,
                        text: "No content to share",
                        color: Colors.orange,
                        icon: Icons.warning,
                      );
                    }
                  } catch (e) {
                    print('Failed to share: $e');
                    showToast(
                      context: context,
                      text: e.toString(),
                      color: Colors.red,
                      icon: Icons.error,
                    );
                  }
                },
              ),
              _buildOption(
                Icons.delete,
                'Delete',
                () async {
                  Navigator.pop(context);
                  await _deleteFile(fileId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteFile(String fileId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      final uid = user.uid;

      final docRef =
          FirebaseFirestore.instance.collection('ocr_results').doc(uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final data = snapshot.data();
          final files = List.from(data?['files'] ?? []);

          files.removeWhere((file) => file['id'] == fileId);

          transaction.update(docRef, {'files': files});
        }
      });

      showToast(
        context: context,
        text: "File successfully deleted",
        color: Colors.green,
        icon: Icons.check,
      );
    } catch (e) {
      print("Failed to delete file: $e");
      showToast(
        context: context,
        text: e.toString(),
        color: Colors.red,
        icon: Icons.error,
      );
    }
  }

  void _showFileOptions(
    BuildContext context,
    String ocrText,
    String pdfPath,
    String wordPath,
    String title,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ocrText.isNotEmpty)
                _buildOption(Icons.text_fields, 'Optical Character Recognition',
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailOcr(
                        file: ocrText,
                        title: title,
                      ),
                    ),
                  );
                }),
              if (pdfPath.isNotEmpty)
                _buildOption(
                    Icons.picture_as_pdf, 'PDF', () => OpenFile.open(pdfPath)),
              if (wordPath.isNotEmpty)
                _buildOption(
                    Icons.article, 'Word', () => OpenFile.open(wordPath)),
            ],
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: child);
      },
    );
  }

  Widget _buildOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: '07489E'.toColor()),
      title: Text(text, style: StyleText(fontSize: 13)),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Container(
      height: 45,
      child: TextFormField(
        autofocus: false,
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _isSearching = true;
          });

          Future.delayed(Duration(milliseconds: 300), () {
            setState(() {
              _isSearching = false;
            });
          });
        },
        cursorColor: '07489E'.toColor(),
        style: StyleText(color: '07489E'.toColor(), fontSize: 13),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(top: 10, left: 10),
          hintText: 'Search files by name',
          hintStyle: StyleText(color: Colors.grey, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.search, color: '07489E'.toColor()),
          suffixIcon: IconButton(
            onPressed: () => _showSortOptions(context),
            icon: Icon(Icons.more_vert, color: '07489E'.toColor()),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'icon': Icons.access_time_outlined,
        'text': 'Latest',
        'onTap': () => _sortFiles('Latest')
      },
      {
        'icon': Icons.text_fields,
        'text': 'By Name',
        'onTap': () => _sortFiles('By Name')
      },
      {
        'icon': Icons.date_range,
        'text': 'By Creation Date',
        'onTap': () => _sortFiles('By Creation Date')
      },
      {
        'icon': Icons.photo_size_select_small,
        'text': 'By Size',
        'onTap': () => _sortFiles('By Size')
      },
      {
        'icon': Icons.dashboard_customize_outlined,
        'text': 'Custom',
        'onTap': () => _sortFiles('Custom')
      },
    ];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (context, index) =>
              Divider(height: 1, endIndent: 20, indent: 20),
          itemCount: options.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(options[index]['icon'], color: '07489E'.toColor()),
              title: Text(options[index]['text'], style: StyleText()),
              onTap: options[index]['onTap'],
            );
          },
        );
      },
    );
  }

  void _sortFiles(String sortType) {
    print('Sorting by $sortType');
    Navigator.pop(context);
  }
}
