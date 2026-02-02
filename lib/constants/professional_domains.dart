class ProfessionalDomain {
  final String value;
  final String label;

  const ProfessionalDomain({
    required this.value,
    required this.label,
  });
}

// Domaines précédents (pour reconversion)
const List<ProfessionalDomain> previousDomains = [
  // Secteur Informatique & Technologie
  ProfessionalDomain(value: "it-software-dev", label: "Informatique - Développement logiciel"),
  ProfessionalDomain(value: "it-infrastructure", label: "Informatique - Infrastructure & Réseaux"),
  ProfessionalDomain(value: "it-security", label: "Informatique - Sécurité"),
  ProfessionalDomain(value: "it-data", label: "Informatique - Data & Analytics"),
  ProfessionalDomain(value: "it-support", label: "Informatique - Support technique"),
  ProfessionalDomain(value: "it-project", label: "Informatique - Gestion de projet IT"),
  ProfessionalDomain(value: "telecom", label: "Télécommunications"),
  ProfessionalDomain(value: "electronics", label: "Électronique & Microélectronique"),
  
  // Secteur Ingénierie & Industrie
  ProfessionalDomain(value: "engineering-mechanical", label: "Ingénierie - Mécanique"),
  ProfessionalDomain(value: "engineering-electrical", label: "Ingénierie - Électrique"),
  ProfessionalDomain(value: "engineering-civil", label: "Ingénierie - Civile & BTP"),
  ProfessionalDomain(value: "engineering-industrial", label: "Ingénierie - Industrielle"),
  
  // Secteur Business & Management
  ProfessionalDomain(value: "management-general", label: "Management général"),
  ProfessionalDomain(value: "management-operations", label: "Management des opérations"),
  ProfessionalDomain(value: "finance", label: "Finance & Comptabilité"),
  ProfessionalDomain(value: "marketing", label: "Marketing & Communication"),
  ProfessionalDomain(value: "sales", label: "Vente & Commerce"),
  ProfessionalDomain(value: "hr", label: "Ressources Humaines"),
  
  // Autres secteurs
  ProfessionalDomain(value: "healthcare", label: "Santé & Médical"),
  ProfessionalDomain(value: "education", label: "Éducation & Formation"),
  ProfessionalDomain(value: "legal", label: "Juridique & Droit"),
  ProfessionalDomain(value: "creative", label: "Créatif & Artistique"),
  ProfessionalDomain(value: "hospitality", label: "Hôtellerie & Restauration"),
  ProfessionalDomain(value: "transport", label: "Transport & Logistique"),
  ProfessionalDomain(value: "agriculture", label: "Agriculture & Agroalimentaire"),
  ProfessionalDomain(value: "other", label: "Autre"),
];

// Domaines de reconversion (domaines cibles)
const List<ProfessionalDomain> reconversionDomains = [
  // Focus sur l'IT et tech pour la reconversion
  ProfessionalDomain(value: "it-software-dev", label: "Informatique - Développement logiciel"),
  ProfessionalDomain(value: "it-web-dev", label: "Informatique - Développement web"),
  ProfessionalDomain(value: "it-mobile-dev", label: "Informatique - Développement mobile"),
  ProfessionalDomain(value: "it-data", label: "Informatique - Data Science & Analytics"),
  ProfessionalDomain(value: "it-security", label: "Informatique - Cybersécurité"),
  ProfessionalDomain(value: "it-devops", label: "Informatique - DevOps & Cloud"),
  ProfessionalDomain(value: "it-ai", label: "Informatique - Intelligence Artificielle"),
  ProfessionalDomain(value: "it-project", label: "Informatique - Gestion de projet IT"),
  ProfessionalDomain(value: "it-testing", label: "Informatique - Tests & QA"),
  ProfessionalDomain(value: "it-ux-ui", label: "Informatique - UX/UI Design"),
  
  // Digital & Marketing
  ProfessionalDomain(value: "digital-marketing", label: "Marketing Digital"),
  ProfessionalDomain(value: "ecommerce", label: "E-commerce"),
  ProfessionalDomain(value: "social-media", label: "Réseaux Sociaux & Community Management"),
  
  // Business & Management
  ProfessionalDomain(value: "product-management", label: "Product Management"),
  ProfessionalDomain(value: "business-analysis", label: "Analyse Business"),
  ProfessionalDomain(value: "consulting", label: "Conseil"),
];