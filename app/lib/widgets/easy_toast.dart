import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

import 'package:fluttertoast/fluttertoast.dart';

void showEasyToast(BuildContext context, String message) {
  Fluttertoast.cancel(); // Cancel any existing toast
  
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 2,
    backgroundColor: AppColors.ink,
    textColor: AppColors.paper,
    fontSize: 12.5,
  );
}
