import 'package:flutter/widgets.dart';
import 'translations/fr.dart';
import 'translations/en.dart';
import 'translations/ar.dart';
import 'translations/es.dart';
import 'translations/de.dart';

/// Lightweight app-wide localization without code generation.
/// Access via `AppLocalizations.of(context)`.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
    Locale('es'),
    Locale('de'),
  ];

  static const _translations = <String, Map<String, String>>{
    'fr': fr,
    'en': en,
    'ar': ar,
    'es': es,
    'de': de,
  };

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['fr']?[key] ??
        key;
  }

  // ── Convenience getters ──────────────────────────────
  // General
  String get appName => translate('app_name');
  String get settings => translate('settings');
  String get home => translate('home');
  String get profile => translate('profile');
  String get search => translate('search');
  String get notifications => translate('notifications');
  String get messages => translate('messages');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get confirm => translate('confirm');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get retry => translate('retry');
  String get noData => translate('no_data');
  String get ok => translate('ok');
  String get add => translate('add');
  String get create => translate('create');
  String get publish => translate('publish');
  String get seeMore => translate('see_more');
  String get seeLess => translate('see_less');
  String get noResults => translate('no_results');
  String get anErrorOccurred => translate('an_error_occurred');
  String get inProgress => translate('in_progress');
  String get description => translate('description');
  String get requiredField => translate('required_field');
  String get welcome => translate('welcome');

  // Auth
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get logout => translate('logout');
  String get firstName => translate('first_name');
  String get lastName => translate('last_name');
  String get confirmPassword => translate('confirm_password');
  String get alreadyHaveAccount => translate('already_have_account');
  String get dontHaveAccount => translate('dont_have_account');
  String get loginSuccess => translate('login_success');
  String get registerSuccess => translate('register_success');
  String get createAccount => translate('create_account');
  String get createMyAccount => translate('create_my_account');
  String get atLeast6Chars => translate('at_least_6_chars');
  String get atLeastUppercase => translate('at_least_uppercase');
  String get atLeastLowercase => translate('at_least_lowercase');
  String get atLeastDigit => translate('at_least_digit');
  String get privacyPolicy => translate('privacy_policy');
  String get resetPassword => translate('reset_password');
  String get enterEmailReset => translate('enter_email_reset');
  String get backToLogin => translate('back_to_login');
  String get verification => translate('verification');
  String get otpVerification => translate('otp_verification');
  String get accountCreatedSuccess => translate('account_created_success');
  String get verifyCreateAccount => translate('verify_create_account');
  String get verificationCode => translate('verification_code');
  String get verifyCode => translate('verify_code');

  // Settings
  String get lightMode => translate('light_mode');
  String get darkMode => translate('dark_mode');
  String get systemMode => translate('system_mode');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get feedbackUiGlobal => translate('feedback_ui_global');
  String get alertsThemeInfo => translate('alerts_theme_info');

  // Feed
  String get feed => translate('feed');
  String get createPost => translate('create_post');
  String get writePost => translate('write_post');
  String get share => translate('share');
  String get like => translate('like');
  String get comment => translate('comment');
  String get comments => translate('comments');
  String get writeComment => translate('write_comment');
  String get noPostsYet => translate('no_posts_yet');
  String get publication => translate('publication');
  String get reply => translate('reply');
  String get hideReplies => translate('hide_replies');
  String get addToPost => translate('add_to_post');
  String get photo => translate('photo');
  String get sendToFriend => translate('send_to_friend');
  String get featureComingSoon => translate('feature_coming_soon');
  String get myPosts => translate('my_posts');
  String get noPublications => translate('no_publications');

  // Profile
  String get editProfile => translate('edit_profile');
  String get followers => translate('followers');
  String get following => translate('following');
  String get posts => translate('posts');
  String get about => translate('about');
  String get experience => translate('experience');
  String get education => translate('education');
  String get skills => translate('skills');
  String get myCV => translate('my_cv');
  String get saved => translate('saved');
  String get noSkillsAdded => translate('no_skills_added');
  String get downloadCv => translate('download_cv');
  String get experienceDeleted => translate('experience_deleted');
  String get educationDeleted => translate('education_deleted');
  String get skillDeleted => translate('skill_deleted');
  String get projectDeleted => translate('project_deleted');
  String get profileUpdated => translate('profile_updated');
  String get updateFailed => translate('update_failed');
  String get follow => translate('follow');
  String get unfollow => translate('unfollow');
  String get generateCv => translate('generate_cv');
  String get withAi => translate('with_ai');
  String get privacy => translate('privacy');
  String get availableNewOpportunities => translate('available_new_opportunities');
  String get showAvailabilityRecruiters => translate('show_availability_recruiters');
  String get phone => translate('phone');
  String get city => translate('city');
  String get address => translate('address');
  String get yourFullName => translate('your_full_name');
  String get camera => translate('camera');
  String get gallery => translate('gallery');
  String get change => translate('change');
  String get projects => translate('projects');

  // CV
  String get downloadPdf => translate('download_pdf');
  String get cvTemplate => translate('cv_template');
  String get primaryColor => translate('primary_color');
  String get font => translate('font');
  String get cvLanguage => translate('cv_language');
  String get pdfGenerating => translate('pdf_generating');
  String get pdfSuccess => translate('pdf_success');
  String get customizeCv => translate('customize_cv');
  String get noCvGenerated => translate('no_cv_generated');
  String get myGeneratedCvs => translate('my_generated_cvs');
  String get cvDeleted => translate('cv_deleted');
  String get defaultDesign => translate('default_design');
  String get downloadStandard => translate('download_standard');
  String get createCv => translate('create_cv');
  String get preview => translate('preview');
  String get importProfile => translate('import_profile');
  String get profileImported => translate('profile_imported');
  String get cvUpdated => translate('cv_updated');
  String get cvCreated => translate('cv_created');
  String get updateCv => translate('update_cv');
  String get summary => translate('summary');
  String get sectionToGenerate => translate('section_to_generate');
  String get generating => translate('generating');
  String get generateMyCv => translate('generate_my_cv');
  String get cvPreview => translate('cv_preview');
  String get customizeTheme => translate('customize_theme');
  String get cvTheme => translate('cv_theme');
  String get presetThemes => translate('preset_themes');
  String get customColor => translate('custom_color');

  // Connections
  String get connections => translate('connections');
  String get connect => translate('connect');
  String get pending => translate('pending');
  String get accept => translate('accept');
  String get reject => translate('reject');
  String get noConnections => translate('no_connections');
  String get myNetwork => translate('my_network');
  String get suggestions => translate('suggestions');
  String get noFollower => translate('no_follower');

  // Jobs
  String get jobs => translate('jobs');
  String get applyNow => translate('apply_now');
  String get jobOffers => translate('job_offers');
  String get matchingJobs => translate('matching_jobs');
  String get noJobsFound => translate('no_jobs_found');

  // Companies
  String get companies => translate('companies');
  String get companyProfile => translate('company_profile');

  // Communities
  String get communities => translate('communities');
  String get joinCommunity => translate('join_community');
  String get createCommunity => translate('create_community');
  String get members => translate('members');

  // Groups
  String get groups => translate('groups');
  String get createGroup => translate('create_group');

  // Explore
  String get explore => translate('explore');
  String get trending => translate('trending');

  // Post Detail
  String get noCommentsYet => translate('no_comments_yet');
  String get beFirstToComment => translate('be_first_to_comment');
  String replyTo(String name) => translate('reply_to').replaceAll('{name}', name);
  String get userDefault => translate('user_default');
  String get addCommentOptional => translate('add_comment_optional');
  String get followed => translate('followed');
  String get report => translate('report');
  String get validate => translate('validate');
  String get companyNotFound => translate('company_not_found');
  String get deleteCompanyPage => translate('delete_company_page');
  String confirmDeletion(String name) => translate('confirm_deletion').replaceAll('{name}', name);
  String get companyDeleted => translate('company_deleted');
  String get deletionFailed => translate('deletion_failed');
  String get invalidCompany => translate('invalid_company');
  String get deleteOffer => translate('delete_offer');
  String get offerDeleted => translate('offer_deleted');
  String get deleteCompany => translate('delete_company');
  String get editMessageText => translate('edit_message_text');
  String get hideForMe => translate('hide_for_me');
  String get deleteMessagePermanently => translate('delete_message_permanently');
  String get deleteMessage => translate('delete_message');
  String get actionIrreversible => translate('action_irreversible');
  String get messageDeleted => translate('message_deleted');
  String get deletionError => translate('deletion_error');
  String get removeFromFavorites => translate('remove_from_favorites');
  String get highlight => translate('highlight');

  // Forms - Experience
  String get selectionError => translate('selection_error');
  String get pleaseSelectEndDateOrCurrentPosition => translate('please_select_end_date_or_current_position');
  String get experienceAddedSuccess => translate('experience_added_success');
  String get experienceModifiedSuccess => translate('experience_modified_success');
  String get errorOccurred => translate('error_occurred');
  String get addExperience => translate('add_experience');
  String get editExperience => translate('edit_experience');
  String get jobTitle => translate('job_title');
  String get jobTitleHint => translate('job_title_hint');
  String get pleaseEnterJobTitle => translate('please_enter_job_title');
  String get companyLabel => translate('company_label');
  String get companyHint => translate('company_hint');
  String get pleaseEnterCompanyName => translate('please_enter_company_name');
  String get locationLabel => translate('location_label');
  String get locationHint => translate('location_hint');
  String get pleaseEnterLocation => translate('please_enter_location');
  String get startDate => translate('start_date');
  String get endDate => translate('end_date');
  String get present => translate('present');
  String get notDefined => translate('not_defined');
  String get currentlyWorkingHere => translate('currently_working_here');
  String get descriptionLabel => translate('description_label');
  String get describeResponsibilities => translate('describe_responsibilities');
  String get usedSkills => translate('used_skills');
  String get categoryLabel => translate('category_label');
  String get skillLabel => translate('skill_label');
  String get noSkillAdded => translate('no_skill_added');
  String get certificatesAttestations => translate('certificates_attestations');
  String get newFile => translate('new_file');
  String get alreadyUploaded => translate('already_uploaded');
  String get noCertificateAdded => translate('no_certificate_added');
  String get keyAchievements => translate('key_achievements');
  String get addAchievementHint => translate('add_achievement_hint');
  String get noAchievementAdded => translate('no_achievement_added');

  // Forms - Education
  String get pleaseSelectEndDateOrCurrentTraining => translate('please_select_end_date_or_current_training');
  String get educationAddedSuccess => translate('education_added_success');
  String get educationModifiedSuccess => translate('education_modified_success');
  String get addEducation => translate('add_education');
  String get editEducation => translate('edit_education');
  String get educationType => translate('education_type');
  String get diplomaLabel => translate('diploma_label');
  String get certificationLabel => translate('certification_label');
  String get courseTraining => translate('course_training');
  String get diplomaCertification => translate('diploma_certification');
  String get diplomaHint => translate('diploma_hint');
  String get pleaseEnterDiplomaName => translate('please_enter_diploma_name');
  String get schoolInstitution => translate('school_institution');
  String get schoolHint => translate('school_hint');
  String get pleaseEnterSchoolName => translate('please_enter_school_name');
  String get gradeOptional => translate('grade_optional');
  String get gradeHint => translate('grade_hint');
  String get webLinkOptional => translate('web_link_optional');
  String get webLinkHint => translate('web_link_hint');
  String get trainingInProgress => translate('training_in_progress');
  String get describeTraining => translate('describe_training');
  String get acquiredSkills => translate('acquired_skills');
  String get certificatesDiplomas => translate('certificates_diplomas');

  // Drawer
  String get newMessage => translate('new_message');
  String get notificationsAvailable => translate('notifications_available');
}

/// Delegate for [AppLocalizations].
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
