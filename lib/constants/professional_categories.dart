class ProfessionalCategory {
  final String value;
  final String label;

  const ProfessionalCategory({
    required this.value,
    required this.label,
  });
}

const List<ProfessionalCategory> professionalCategories = [
  // Niveaux d'expérience
  ProfessionalCategory(value: "junior", label: "Junior"),
  ProfessionalCategory(value: "intermediate", label: "Intermédiaire"),
  ProfessionalCategory(value: "senior", label: "Senior"),
  ProfessionalCategory(value: "expert", label: "Expert"),

  // Rôles de management
  ProfessionalCategory(value: "team-lead", label: "Chef d'équipe"),
  ProfessionalCategory(value: "manager", label: "Manager"),
  ProfessionalCategory(value: "director", label: "Directeur"),
  ProfessionalCategory(value: "vp", label: "Vice-Président"),
  ProfessionalCategory(value: "c-level", label: "C-Level (CTO, CIO, etc.)"),

  // Statuts professionnels
  ProfessionalCategory(value: "freelance", label: "Freelance / Indépendant"),
  ProfessionalCategory(value: "contractor", label: "Prestataire"),
  ProfessionalCategory(value: "consultant", label: "Consultant"),
  ProfessionalCategory(value: "employee", label: "Salarié"),
  ProfessionalCategory(value: "civil-servant", label: "Fonctionnaire"),

  // Situations spécifiques
  ProfessionalCategory(value: "entrepreneur", label: "Entrepreneur"),
  ProfessionalCategory(value: "founder", label: "Fondateur / Co-fondateur"),
  ProfessionalCategory(value: "student", label: "Étudiant"),
  ProfessionalCategory(value: "intern", label: "Stagiaire"),
  ProfessionalCategory(value: "apprentice", label: "Apprenti / Alternant"),
  ProfessionalCategory(value: "recent-graduate", label: "Jeune diplômé"),

  // Spécialités techniques
  ProfessionalCategory(value: "fullstack-dev", label: "Développeur Full-Stack"),
  ProfessionalCategory(value: "frontend-dev", label: "Développeur Front-End"),
  ProfessionalCategory(value: "backend-dev", label: "Développeur Back-End"),
  ProfessionalCategory(value: "mobile-dev", label: "Développeur Mobile"),
  ProfessionalCategory(value: "data-scientist", label: "Data Scientist"),
  ProfessionalCategory(value: "devops-engineer", label: "Ingénieur DevOps"),
  ProfessionalCategory(value: "security-analyst", label: "Analyste Sécurité"),
  ProfessionalCategory(value: "product-owner", label: "Product Owner"),
  ProfessionalCategory(value: "scrum-master", label: "Scrum Master"),
  ProfessionalCategory(value: "qa-engineer", label: "Ingénieur QA"),
];