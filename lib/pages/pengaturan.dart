part of '../pages.dart';

class Pengaturan extends StatefulWidget {
  const Pengaturan({super.key});

  @override
  State<Pengaturan> createState() => _PengaturanState();
}

class _PengaturanState extends State<Pengaturan> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logout(BuildContext context) async {
    try {
      String? uid = _auth.currentUser?.uid;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('uid');

      await _auth.signOut();

      print("Berhasil keluar dari akun anonim dengan UID: $uid");

      if (Platform.isAndroid) {
        Future.delayed(Duration(milliseconds: 500), () {
          SystemNavigator.pop();
        });
      } else if (Platform.isIOS) {
        Future.delayed(Duration(milliseconds: 500), () {
          exit(0);
        });
      }
    } catch (e) {
      print("Gagal keluar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Container(),
        backgroundColor: '07489E'.toColor(),
        title: Text(
          'Setting',
          style: StyleText(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          children: [
            Container(
              padding:
                  EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: '07489E'.toColor().withOpacity(0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trash Folder',
                        style: StyleText(
                          color: '07489E'.toColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Documents that have been deleted.',
                        style: StyleText(
                          color: '07489E'.toColor(),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: '07489E'.toColor(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                logout(context);
              },
              child: Container(
                padding:
                    EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: '07489E'.toColor().withOpacity(0.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Logout',
                          style: StyleText(
                            color: '07489E'.toColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Exit this application.',
                          style: StyleText(
                            color: '07489E'.toColor(),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.logout,
                      color: '07489E'.toColor(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
