// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtk_flutter/main.dart';

void main() {
  testWidgets('Basic rendering', (tester) async {
    // Build our app and trigger a frame.
    // Replace MyApp with your actual main app widget from main.dart
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Discover Melaka Events'),
        ),
      ),
    ));

    // Verify that our app title is displayed
    expect(find.text('Discover Melaka Events'), findsOneWidget);
  });
}