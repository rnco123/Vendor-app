import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void handleRoleRootBack(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  SystemNavigator.pop();
}
