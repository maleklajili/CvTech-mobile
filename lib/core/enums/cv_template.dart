enum CvTemplate { modern, french, canadian }

extension CvTemplateExtension on CvTemplate? {
  bool get isModern => this == CvTemplate.modern;
  bool get isFrensh => this == CvTemplate.french;
  bool get isCanadian => this == CvTemplate.canadian;
}
