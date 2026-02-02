class ApiEndpoints {
  // Base URL - à configurer dans env.dart
  static const String auth = '/auth';
  
  // Auth endpoints
  static const String login = '$auth/login';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refreshToken';
  static const String sendOtp = '$auth/send-otp'; // + /:email
  static const String verifyOtp = '$auth/verify-otp'; // + /:otp
  static const String forgetPassword = '$auth/forget-password'; // + /:email
  static const String validateResetToken = '$auth/validate-reset-token'; // + /:token
  static const String changePassword = '$auth/change-password'; // + /:token
  
  // User endpoints
  static const String users = '/user';
  static const String userById = '$users/by-id/'; // + :id
  static const String currentUser = '$users/current-user';
  static const String updateProfile = '$users/update-profile';
  
  // Education endpoints
  static const String education = '/education';
  static const String educationGetAll = '$education/getAll';
  static const String educationById = '$education/'; // + :id
  static const String educationCreate = '$education/add-education';
  static const String educationUpdate = '$education/update-education/'; // + :id
  static const String educationDelete = '$education/delete/'; // + :id
  
  // Experience endpoints
  static const String experience = '/experience';
  static const String experienceGetAll = '$experience/getAll';
  static const String experienceById = '$experience/'; // + :id
  static const String experienceCreate = '$experience/add-experience';
  static const String experienceUpdate = '$experience/update-experience/'; // + :id
  static const String experienceDelete = '$experience/delete-experience/'; // + :id
  
  // Skill endpoints
  static const String skill = '/skill';
  static const String skillGetAll = '$skill/getAll';
  static const String skillById = '$skill/'; // + :id
  static const String skillCreate = '$skill/add-skill';
  static const String skillUpdate = '$skill/update/'; // + :id
  static const String skillDelete = '$skill/delete/'; // + :id
  
  // Project endpoints
  static const String project = '/projects';
  static const String projectGetAll = '$project/getAll';
  static const String projectById = '$project/'; // + :id
  static const String projectCreate = '$project/add-project';
  static const String projectUpdate = '$project/update-project/'; // + :id
  static const String projectDelete = '$project/delete/'; // + :id
  
  // Company endpoints
  static const String company = '/companies';
  static const String companyGetAll = '$company/getAll';
  static const String companyById = '$company/'; // + :id
  static const String companyCreate = '$company/add-company';
  static const String companyUpdate = '$company/update-company/'; // + :id
  static const String companyDelete = '$company/delete/'; // + :id
  static const String companyByUser = '$company/user/'; // + :userId
  
  // Job endpoints
  static const String job = '/jobs';
  static const String jobGetAll = '$job/getAll';
  static const String jobById = '$job/'; // + :id
  static const String jobCreate = '$job/add-job';
  static const String jobUpdate = '$job/update-job/'; // + :id
  static const String jobDelete = '$job/delete/'; // + :id
  static const String jobByCompany = '$job/company/'; // + :companyId
  static const String jobMyJobs = '$job/my-jobs';
  static const String jobToggleStatus = '$job/toggle-status/'; // + :id
  static const String jobFeature = '$job/feature/'; // + :id
  
  // Transaction endpoints
  static const String transaction = '/transactions';
  static const String transactionGetAll = '$transaction';
  static const String transactionBalance = '$transaction/balance';
  static const String transactionByType = '$transaction/'; // + :type
  
  // Language endpoints
  static const String language = '/languages';
  static const String languageGetAll = '$language/getAll';
  static const String languageById = '$language/get-language/'; // + :id
  static const String languageCreate = '$language/add-language';
  static const String languageUpdate = '$language/update-language/'; // + :id
  static const String languageDelete = '$language/delete-language/'; // + :id
  
  // Technical Skill endpoints
  static const String technicalSkill = '/technical-skills';
  static const String technicalSkillGetAll = '$technicalSkill/getAll';
  static const String technicalSkillById = '$technicalSkill/get-technical-skill/'; // + :id
  static const String technicalSkillCreate = '$technicalSkill/add-technical-skill';
  static const String technicalSkillUpdate = '$technicalSkill/update-technical-skill/'; // + :id
  static const String technicalSkillDelete = '$technicalSkill/delete-technical-skill/'; // + :id
  static const String technicalSkillGrouped = '$technicalSkill/grouped-by-category';
  
  // Personal Skill endpoints
  static const String personalSkill = '/personal-skills';
  static const String personalSkillGetAll = '$personalSkill/getAll';
  static const String personalSkillById = '$personalSkill/get-personal-skill/'; // + :id
  static const String personalSkillCreate = '$personalSkill/add-personal-skill';
  static const String personalSkillUpdate = '$personalSkill/update-personal-skill/'; // + :id
  static const String personalSkillDelete = '$personalSkill/delete-personal-skill/'; // + :id
  
  // Post endpoints
  static const String post = '/post';
  static const String postGetAll = '$post/getAll';
  static const String postById = '$post/'; // + :id
  static const String postCreate = '$post/add';
  static const String postUpdate = '$post/update/'; // + :id
  static const String postDelete = '$post/delete/'; // + :id
  
  // Profile endpoint
  static const String profile = '/profile';
  static const String profileById = '$profile/'; // + :userId
}
