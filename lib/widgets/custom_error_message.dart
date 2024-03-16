import 'package:flutter/material.dart';

bool spamCheck = false;
spamFunction() async {
  await Future.delayed(
    const Duration(seconds: 2),
  );
  spamCheck = false;
}

void customErrorMessage(
  BuildContext context,
  String? errorText,
  String? buttonText,
  Function()? buttonFon,
  bool spamCheckOn,
) {
  if (spamCheckOn) {
    if (spamCheck == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1950),
          elevation: 10,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          action: SnackBarAction(
            onPressed: () {
              buttonFon?.call();
            },
            label: buttonText ?? 'error',
          ),
          content: Container(
            padding: const EdgeInsets.all(10),
            height: 40,
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(
                errorText ?? 'error',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
    } else {
      return;
    }
    spamCheck = true;
    spamFunction();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1950),
        elevation: 10,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        action: SnackBarAction(
          onPressed: () {
            buttonFon?.call();
          },
          label: buttonText ?? 'error',
        ),
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.all(10),
          height: 40,
          width: double.infinity,
          child: FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              errorText ?? 'error',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
