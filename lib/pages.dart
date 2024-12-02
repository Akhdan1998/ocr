import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:dio/dio.dart';
import 'package:docx_template/docx_template.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supercharged/supercharged.dart';
import 'package:barcode_widget/barcode_widget.dart' as barcode_widget;
import 'package:uuid/uuid.dart';

import 'main.dart';

part 'widgets/teks.dart';
part 'widgets/toast.dart';
part 'widgets/image.dart';
part 'widgets/button.dart';
// part 'finish_ocr.dart';
part 'pages/beranda.dart';
part 'pages/file_saya.dart';
part 'pages/detail_ocr.dart';
part 'pages/tindakan.dart';
part 'pages/pengaturan.dart';
part 'pages/ocr.dart';
part 'pages/qrcode.dart';
