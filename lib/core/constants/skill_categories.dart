/// Skill categories and skills matching Next.js frontend
/// Used in experience, education, and project forms
class SkillCategories {
  static const Map<String, List<String>> skillsByCategory = {
    'Frontend': [
      'React',
      'Vue.js',
      'Angular',
      'Next.js',
      'TypeScript',
      'JavaScript',
      'HTML',
      'CSS',
      'Tailwind CSS',
      'SASS',
      'Bootstrap',
      'Material-UI',
      'Redux',
      'Webpack',
      'Vite',
    ],
    'Backend': [
      'Node.js',
      'Express',
      'NestJS',
      'Python',
      'Django',
      'FastAPI',
      'Java',
      'Spring Boot',
      'PHP',
      'Laravel',
      'Ruby',
      'Rails',
      'Go',
      'Rust',
      '.NET',
      'C#',
    ],
    'DevOps': [
      'Docker',
      'Kubernetes',
      'AWS',
      'Azure',
      'GCP',
      'CI/CD',
      'Jenkins',
      'GitHub Actions',
      'Terraform',
      'Ansible',
      'Linux',
      'Nginx',
      'Apache',
    ],
    'Mobile': [
      'Flutter',
      'Dart',
      'React Native',
      'Swift',
      'Kotlin',
      'iOS',
      'Android',
      'Xamarin',
      'Ionic',
    ],
    'Database': [
      'PostgreSQL',
      'MySQL',
      'MongoDB',
      'Redis',
      'Firebase',
      'Prisma',
      'TypeORM',
      'Sequelize',
      'SQLite',
      'Oracle',
      'Cassandra',
      'Elasticsearch',
    ],
    'Data Science': [
      'Python',
      'R',
      'TensorFlow',
      'PyTorch',
      'Pandas',
      'NumPy',
      'Scikit-learn',
      'Keras',
      'Machine Learning',
      'Deep Learning',
      'Data Analysis',
      'Jupyter',
    ],
    'Tools': [
      'Git',
      'GitHub',
      'GitLab',
      'Bitbucket',
      'Jira',
      'Confluence',
      'Slack',
      'Figma',
      'Adobe XD',
      'Postman',
      'VS Code',
    ],
    'Other': [
      'Agile',
      'Scrum',
      'REST API',
      'GraphQL',
      'Testing',
      'Jest',
      'Cypress',
      'Selenium',
      'UI/UX',
      'Microservices',
      'WebSockets',
      'OAuth',
      'JWT',
    ],
  };

  /// Get all categories
  static List<String> get categories => skillsByCategory.keys.toList();

  /// Get skills for a specific category
  static List<String> getSkillsForCategory(String category) {
    return skillsByCategory[category] ?? [];
  }

  /// Search skills across all categories
  static List<Map<String, String>> searchSkills(String query) {
    final results = <Map<String, String>>[];
    if (query.isEmpty) return results;

    final lowerQuery = query.toLowerCase();
    for (final category in skillsByCategory.entries) {
      for (final skill in category.value) {
        if (skill.toLowerCase().contains(lowerQuery)) {
          results.add({
            'name': skill,
            'category': category.key,
          });
        }
      }
    }
    return results;
  }

  /// Get all skills as a flat list
  static List<Map<String, String>> getAllSkills() {
    final results = <Map<String, String>>[];
    for (final category in skillsByCategory.entries) {
      for (final skill in category.value) {
        results.add({
          'name': skill,
          'category': category.key,
        });
      }
    }
    return results;
  }
}
