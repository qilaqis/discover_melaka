import 'package:flutter/material.dart';

enum Attending {
  yes,
  no,
  maybe; // Replaced 'unknown' with 'maybe'

  String get displayName {
    switch (this) {
      case Attending.yes:
        return 'Yes';
      case Attending.no:
        return 'No';
      case Attending.maybe:
        return 'Maybe';
    }
  }

  Color get color {
    switch (this) {
      case Attending.yes:
        return Colors.green;
      case Attending.no:
        return Colors.red;
      case Attending.maybe:
        return Colors.orange;
    }
  }
}