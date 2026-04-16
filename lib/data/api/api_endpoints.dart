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
  static const String educationByUser = '$education/user/'; // + :userId
  
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
  static const String skillAddMany = '$skill/add-many-skill';
  static const String skillUpdateMany = '$skill/update-many-skill';
  static const String skillUpdate = '$skill/update/'; // + :id
  static const String skillDelete = '$skill/delete/'; // + :id
  
  // Project endpoints
  static const String project = '/projects';
  static const String projectGetAll = '$project/getAll';
  static const String projectById = '$project/'; // + :id
  static const String projectCreate = '$project/add-project';
  static const String projectUpdate = '$project/update-project/'; // + :id
  static const String projectDelete = '$project/delete/'; // + :id
  static const String projectByUser = '$project/user/'; // + :userId
  
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
  static const String jobByUser = '$job/user/'; // + :userId
  static const String jobMyJobs = '$job/my-jobs';
  static const String jobToggleStatus = '$job/toggle-status/'; // + :id
  static const String jobFeature = '$job/feature/'; // + :id
  static const String jobMatches = '$job/matches'; // AI-powered matches for current user

  // Job application endpoints
  static const String jobApplications = '/job-applications';
  static const String jobApplication = '$jobApplications/'; // + :applicationId
  
  // Transaction endpoints
  static const String transaction = '/transactions';
  static const String transactionGetAll = '$transaction';
  static const String transactionBalance = '$transaction/balance';
  static const String transactionByType = '$transaction/'; // + :type
  
  // Payment endpoints
  static const String payment = '/payment';
  static const String paymentInitiate = '$payment/initiate';
  static const String paymentPlan = '$payment/plan';
  static const String paymentBankInfo = '$payment/bank-info';
  static const String paymentStatus = '$payment/status/'; // + :paymentId
  static const String paymentHistory = '$payment/history';
  
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
  static const String post = '/posts';
  static const String postFeed = '$post/feed';
  static const String postById = '$post/'; // + :id (GET, PUT, DELETE)
  static const String postCreate = '$post/create';
  static const String postTrending = '$post/trending';
  static const String postVote = '$post/'; // + :id/vote (POST)
  static const String postComments = '$post/'; // + :id/comments (GET, POST)
  static const String postSave = '$post/'; // + :id/save (POST, DELETE)
  static const String postCommunity = '$post/community/'; // + :communityId
  static const String postByUser = '$post/user/'; // + :userId (GET user posts)
  
  // Profile endpoint
  static const String profile = '/profile';
  static const String profileById = '$profile/'; // + :userId
  static const String profileCvScore = '$profile/cv-score';
  
  // Community endpoints
  static const String community = '/community';
  static const String communityGetAll = '$community/getAll';
  static const String communityPopular = '$community/popular';
  static const String communityById = '$community/id/'; // + :id
  static const String communityByName = '$community/'; // + :name
  static const String communitySearch = '$community/search';
  static const String communityMembers = '$community/'; // + :id/members
  static const String communityCheckMembership = '$community/'; // + :id/check-membership
  static const String communityMyCommunities = '$community/user/my-communities';
  static const String communityCreate = '$community/create';
  static const String communityJoin = '$community/'; // + :id/join
  static const String communityLeave = '$community/'; // + :id/leave
  
  // Message endpoints
  static const String message = '/messages';
  static const String messageConversation = '$message/conversation/'; // + :userId
  static const String messageSend = '$message/';
  static const String messageMedia = '$message/media/'; // + :receiverId
  static const String messageChats = '$message/chats';
  static const String messageSearch = '$message/search';
  static const String messageDelete = '$message/'; // + :messageId
  
  // Comment endpoints
  static const String comment = '/comments';
  static const String commentCreate = '$comment/'; // POST
  static const String commentPost = '$comment/post/'; // + :postId (GET all comments)
  static const String commentReplies = '$comment/'; // + :commentId/replies (GET replies)
  static const String commentUpdate = '$comment/'; // + :commentId (PUT)
  static const String commentDelete = '$comment/'; // + :commentId (DELETE)
  
  // Reaction endpoints
  static const String reaction = '/reactions';
  static const String reactionToggle = '$reaction/'; // + :postId/toggle (POST)
  static const String reactionDelete = '$reaction/'; // + :postId (DELETE)
  static const String reactionCounts = '$reaction/'; // + :postId/counts (GET)
  static const String reactionData = '$reaction/'; // + :postId/data (GET)
  static const String reactionUsers = '$reaction/'; // + :postId/users/:type (GET)
  // Comment reactions
  static const String reactionCommentToggle = '$reaction/comments/'; // + :commentId/toggle (POST)
  static const String reactionCommentDelete = '$reaction/comments/'; // + :commentId (DELETE)
  static const String reactionCommentData = '$reaction/comments/'; // + :commentId/data (GET)
  
  // Share endpoints
  static const String shareCreate = '$post/'; // + :id/share (POST)
  static const String sharePost = '$post/'; // + :id/shares (GET all shares)
  static const String shareUser = '$post/shared'; // GET user's shares
  static const String shareDelete = '$post/'; // + :id/unshare (DELETE) - not yet implemented
  
  // Network / Follow endpoints (follow-based connection system)
  static const String follow = '$users/follow/'; // + :userId (POST)
  static const String unfollow = '$users/unfollow/'; // + :userId (DELETE)
  static const String followers = '$users/followers'; // GET (current user) or + /:userId
  static const String following = '$users/following'; // GET (current user) or + /:userId
  static const String followStatus = '$users/follow-status/'; // + :userId (GET)
  static const String friends = '$users/friends'; // GET mutual friends
  static const String friendsSuggestions = '$users/friends/suggestions'; // GET ?page&limit&search
  static const String friendsSearch = '$users/friends/search'; // GET ?q=
  static const String userSearch = '$users/search'; // GET ?q= (global user search)
  static const String userStats = '$users/stats'; // GET current user stats
  static const String mutualFriends = '$users/mutual-friends/'; // + :userId (GET)
  
  // Friend Group endpoints
  static const String friendGroups = '/friend-groups';
  static const String friendGroupCreate = '$friendGroups/create'; // POST
  static const String friendGroupGetAll = '$friendGroups'; // GET
  static const String friendGroupById = '$friendGroups/'; // + :groupId (GET, PUT, DELETE)
  static const String friendGroupAddMembers = '$friendGroups/'; // + :groupId/add-members (POST)
  static const String friendGroupRemoveMembers = '$friendGroups/'; // + :groupId/remove-members (DELETE)
  static const String friendGroupSearch = '$friendGroups/search/'; // + :query (GET)

  // AI CV endpoints
  static const String aiCv = '/ai-cv';
  static const String aiCvGenerate = '$aiCv/generate';
  static const String aiCvReformulate = '$aiCv/reformulate/'; // + :id
  static const String aiCvMyCvs = '$aiCv/my-cvs';
  static const String aiCvDelete = '$aiCv/delete/'; // + :id
  static const String aiCvDownloadPdf = '$aiCv/download-pdf/'; // + :id
  static const String aiCvInfo = '$aiCv/cv-info';

  // Manual CV endpoints
  static const String manualCv = '/manual-cv';
  static const String manualCvCreate = '$manualCv/create';
  static const String manualCvMyCvs = '$manualCv/my-cvs';
  static const String manualCvGet = '$manualCv/get/'; // + :id
  static const String manualCvUpdate = '$manualCv/update/'; // + :id
  static const String manualCvDelete = '$manualCv/delete/'; // + :id
  static const String manualCvDownloadPdf = '$manualCv/download-pdf/'; // + :id
  static const String manualCvImportProfile = '$manualCv/import-profile';
  static const String manualCvScore = '$manualCv/score/'; // + :id

  // Admin endpoints
  static const String admin = '/admin';
  static const String adminStats = '$admin/stats';
  static const String adminActivity = '$admin/activity';
  static const String adminCoinsStats = '$admin/coins-stats';
  static const String adminCoinsTransactions = '$admin/coins-transactions';
  static const String adminTopStats = '$admin/top-stats';

  // Report endpoints
  static const String reports = '/reports';
  static const String reportCreate = '$reports/create';
  static const String reportStats = '$reports/stats';
  static const String reportById = '$reports/'; // + :id
  static const String reportUpdateStatus = '$reports/'; // + :id/status
  static const String reportDelete = '$reports/'; // + :id

  // Admin Payment endpoints
  static const String paymentPending = '$payment/pending';
  static const String paymentApprove = '$payment/'; // + :paymentId/approve
  static const String paymentReject = '$payment/'; // + :paymentId/reject

  // Admin Job endpoints
  static const String jobAdminAll = '$job/admin/all';

  // Admin Transaction endpoints
  static const String transactionAll = '$transaction/all';

  // Moderation endpoints
  static const String moderation = '/moderation';
  static const String moderationFlaggedPosts = '$moderation/flagged-posts';
  static const String moderationFlaggedUsers = '$moderation/flagged-users';
  static const String moderationBannedUsers = '$moderation/banned-users';
  static const String moderationStats = '$moderation/stats';
  static const String moderationPostApprove = '$moderation/post/'; // + :id/approve
  static const String moderationPostReject = '$moderation/post/'; // + :id/reject
  static const String moderationUserBan = '$moderation/user/'; // + :id/ban
  static const String moderationUserUnban = '$moderation/user/'; // + :id/unban
  static const String moderationCheckText = '$moderation/check-text';

  // Company admin endpoints
  static const String adminCompanyGetAll = '$company/getAll';
  static const String companyStats = '$company/stats';

  // Chatbot AI endpoints
  static const String chatbot = '/chatbot';
  static const String chatbotMessage = '$chatbot/message';
  static const String chatbotStatus = '$chatbot/status';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '$notifications/unread';
  static const String notificationsUnreadList = '$notifications/unread/list';
  static const String notificationById = '$notifications/'; // + :id
  static const String notificationsByType = '$notifications/type/'; // + :type
  static const String notificationMarkRead = '$notifications/'; // + :id/read (PUT)
  static const String notificationMarkAllRead = '$notifications/read/all';
}
