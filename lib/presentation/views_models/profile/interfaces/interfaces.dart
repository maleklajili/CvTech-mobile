// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/enums/cv_template.dart';

abstract interface class ICvTemplate {
  CvTemplate? cvTemplateSelected;
  void selectTemplate(CvTemplate cvselected);
  Color getColor();
}

abstract interface class ICvTemplateGenrator {
  bool isGenerating = false;
  bool isComplete = false;
  void generateCV();
}
