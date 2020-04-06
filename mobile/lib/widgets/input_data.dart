import 'package:flutter/material.dart';
import 'package:mobile/widgets/input_controller.dart';
import 'package:quiver/strings.dart';

/// A simple structure for storing build information for a form's input fields.
class InputData {
  final String id;

  /// Returns user-visible label text. This is required for displaying this
  /// input in the list of available inputs in an [EditableFormPage].
  final String Function(BuildContext) label;

  /// Whether the input can be removed from the associated form. Defaults to
  /// `true`.
  final bool removable;

  InputController controller;

  InputData({
    @required this.id,
    @required this.controller,
    @required this.label,
    this.removable = true,
  }) : assert(isNotEmpty(id)),
       assert(label != null),
       assert(controller != null);
}