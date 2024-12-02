part of '../pages.dart';

void showToast({
  required BuildContext context,
  required String text,
  IconData icon = Icons.info,
  required Color color,
}) {
  DelightToastBar(
    animationDuration: const Duration(seconds: 2),
    snackbarDuration: const Duration(seconds: 5),
    autoDismiss: true,
    position: DelightSnackbarPosition.top,
    builder: (context) {
      return ToastCard(
        leading: Icon(
          icon,
          size: 28,
          color: color,
        ),
        title: Text(
          text,
          style: StyleText(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      );
    },
  ).show(context);
}
