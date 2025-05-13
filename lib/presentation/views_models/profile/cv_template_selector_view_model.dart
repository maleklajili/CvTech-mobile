// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/enums/cv_template.dart';
import 'package:cv_tech/presentation/views_models/base/base_view_model.dart';
import 'package:cv_tech/presentation/views_models/profile/interfaces/interfaces.dart';

class CvTemplateSelectorViewModel extends BaseViewModel
    implements ICvTemplate, ICvTemplateGenrator {
  CvTemplateSelectorViewModel(super.context);
  @override
  CvTemplate? cvTemplateSelected;

  @override
  bool isComplete = false;

  @override
  bool isGenerating = false;

  @override
  void selectTemplate(CvTemplate slected) {
    isComplete = false;
    isGenerating = false;
    cvTemplateSelected = slected;
    update();
  }

  @override
  Color getColor() {
    switch (cvTemplateSelected) {
      case CvTemplate.modern:
        return Colors.orange;
      case CvTemplate.french:
        return Colors.blue;
      case CvTemplate.canadian:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void generateCV() {
    isGenerating = true;
    update();
    Future.delayed(const Duration(seconds: 2), () {
      isGenerating = false;
      isComplete = true;
      update();
    });
  }
}
