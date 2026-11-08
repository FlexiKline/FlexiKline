import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/repository_registry.dart';

void main() {
  registerRepositories();
  runApp(const DemoApp());
}
