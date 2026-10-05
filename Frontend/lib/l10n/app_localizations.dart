import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @app_name.
  ///
  /// In fr, this message translates to:
  /// **'SmartClass'**
  String get app_name;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In fr, this message translates to:
  /// **'Trier'**
  String get sort;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previous;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get skip;

  /// No description provided for @continue_action.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continue_action;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @no_data.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get no_data;

  /// No description provided for @empty_state.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément'**
  String get empty_state;

  /// No description provided for @try_again.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get try_again;

  /// No description provided for @something_went_wrong.
  ///
  /// In fr, this message translates to:
  /// **'Quelque chose s\'est mal passé'**
  String get something_went_wrong;

  /// No description provided for @connection_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion'**
  String get connection_error;

  /// No description provided for @permission_denied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée'**
  String get permission_denied;

  /// No description provided for @not_found.
  ///
  /// In fr, this message translates to:
  /// **'Non trouvé'**
  String get not_found;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get register;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @confirm_password.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirm_password;

  /// No description provided for @forgot_password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgot_password;

  /// No description provided for @reset_password.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get reset_password;

  /// No description provided for @remember_me.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get remember_me;

  /// No description provided for @login_with_google.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Google'**
  String get login_with_google;

  /// No description provided for @login_with_apple.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Apple'**
  String get login_with_apple;

  /// No description provided for @or_continue_with.
  ///
  /// In fr, this message translates to:
  /// **'Ou continuer avec'**
  String get or_continue_with;

  /// No description provided for @dont_have_account.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get dont_have_account;

  /// No description provided for @already_have_account.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get already_have_account;

  /// No description provided for @sign_up.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get sign_up;

  /// No description provided for @sign_in.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get sign_in;

  /// No description provided for @welcome_back.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour'**
  String get welcome_back;

  /// No description provided for @create_account.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get create_account;

  /// No description provided for @enter_email.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email'**
  String get enter_email;

  /// No description provided for @enter_password.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe'**
  String get enter_password;

  /// No description provided for @invalid_email.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalid_email;

  /// No description provided for @password_too_short.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 8 caractères'**
  String get password_too_short;

  /// No description provided for @passwords_dont_match.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwords_dont_match;

  /// No description provided for @login_failed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion'**
  String get login_failed;

  /// No description provided for @registration_failed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'inscription'**
  String get registration_failed;

  /// No description provided for @email_already_exists.
  ///
  /// In fr, this message translates to:
  /// **'Cet email est déjà utilisé'**
  String get email_already_exists;

  /// No description provided for @invalid_credentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants invalides'**
  String get invalid_credentials;

  /// No description provided for @welcome_title.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur SmartClass'**
  String get welcome_title;

  /// No description provided for @welcome_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à votre espace d\'apprentissage intelligent'**
  String get welcome_subtitle;

  /// No description provided for @email_label.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get email_label;

  /// No description provided for @email_hint.
  ///
  /// In fr, this message translates to:
  /// **'nom@exemple.edu'**
  String get email_hint;

  /// No description provided for @password_hint.
  ///
  /// In fr, this message translates to:
  /// **'••••••••'**
  String get password_hint;

  /// No description provided for @login_button.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login_button;

  /// No description provided for @signup_button.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signup_button;

  /// No description provided for @full_name_label.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get full_name_label;

  /// No description provided for @full_name_hint.
  ///
  /// In fr, this message translates to:
  /// **'ex. Thomas Laurent'**
  String get full_name_hint;

  /// No description provided for @required_badge.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required_badge;

  /// No description provided for @academic_format_hint.
  ///
  /// In fr, this message translates to:
  /// **'Format académique recommandé'**
  String get academic_format_hint;

  /// No description provided for @password_rule.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 car., 1 chiffre'**
  String get password_rule;

  /// No description provided for @accept_terms_prefix.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les'**
  String get accept_terms_prefix;

  /// No description provided for @and.
  ///
  /// In fr, this message translates to:
  /// **'et la'**
  String get and;

  /// No description provided for @or_signup_with.
  ///
  /// In fr, this message translates to:
  /// **'ou s\'inscrire avec'**
  String get or_signup_with;

  /// No description provided for @login_with_microsoft.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Microsoft'**
  String get login_with_microsoft;

  /// No description provided for @signup_with_microsoft.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire avec Microsoft'**
  String get signup_with_microsoft;

  /// No description provided for @brand_badge_edtech.
  ///
  /// In fr, this message translates to:
  /// **'EdTech'**
  String get brand_badge_edtech;

  /// No description provided for @brand_badge_ai.
  ///
  /// In fr, this message translates to:
  /// **'AI Assisted'**
  String get brand_badge_ai;

  /// No description provided for @step_2_profile.
  ///
  /// In fr, this message translates to:
  /// **'Étape 2 · Profil'**
  String get step_2_profile;

  /// No description provided for @step_3_final.
  ///
  /// In fr, this message translates to:
  /// **'Étape 3 · Finalisation'**
  String get step_3_final;

  /// No description provided for @who_are_you.
  ///
  /// In fr, this message translates to:
  /// **'Qui êtes-vous ?'**
  String get who_are_you;

  /// No description provided for @role_intro.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre profil pour personnaliser vos espaces d\'apprentissage et vos outils IA.'**
  String get role_intro;

  /// No description provided for @recommended.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé'**
  String get recommended;

  /// No description provided for @role_student_desc.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à vos cours interactifs, devoirs assistés par IA, quiz et suivez votre progression en temps réel.'**
  String get role_student_desc;

  /// No description provided for @role_teacher_desc.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos promotions, concevez des modules dynamiques et générez des évaluations automatisées.'**
  String get role_teacher_desc;

  /// No description provided for @role_admin_desc.
  ///
  /// In fr, this message translates to:
  /// **'Supervisez l\'ensemble de votre établissement, orchestrez les accès et pilotez les métriques globales.'**
  String get role_admin_desc;

  /// No description provided for @tag_homework.
  ///
  /// In fr, this message translates to:
  /// **'Devoirs'**
  String get tag_homework;

  /// No description provided for @tag_ai_tutor.
  ///
  /// In fr, this message translates to:
  /// **'Tuteur IA'**
  String get tag_ai_tutor;

  /// No description provided for @tag_corrections.
  ///
  /// In fr, this message translates to:
  /// **'Corrigés'**
  String get tag_corrections;

  /// No description provided for @tag_classes.
  ///
  /// In fr, this message translates to:
  /// **'Classes'**
  String get tag_classes;

  /// No description provided for @tag_dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get tag_dashboard;

  /// No description provided for @tag_security.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get tag_security;

  /// No description provided for @trust_rgpd.
  ///
  /// In fr, this message translates to:
  /// **'Configuration sécurisée conforme aux standards académiques et protection RGPD renforcée.'**
  String get trust_rgpd;

  /// No description provided for @change_role_later.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez changer de rôle ultérieurement dans les paramètres de votre compte.'**
  String get change_role_later;

  /// No description provided for @profile_setup_title.
  ///
  /// In fr, this message translates to:
  /// **'Configurez votre profil'**
  String get profile_setup_title;

  /// No description provided for @profile_setup_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisez vos informations académiques pour adapter les recommandations de vos cours et tuteurs IA.'**
  String get profile_setup_subtitle;

  /// No description provided for @avatar_optional.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo de profil (Optionnel)'**
  String get avatar_optional;

  /// No description provided for @institution_label.
  ///
  /// In fr, this message translates to:
  /// **'Établissement / Université'**
  String get institution_label;

  /// No description provided for @level_label.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'études / Spécialité'**
  String get level_label;

  /// No description provided for @interests_label.
  ///
  /// In fr, this message translates to:
  /// **'Centres d\'intérêt'**
  String get interests_label;

  /// No description provided for @interests_hint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez au moins 3 matières pour nourrir votre Tuteur IA'**
  String get interests_hint;

  /// No description provided for @selected_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} sélectionnés'**
  String selected_count(Object count);

  /// No description provided for @other_interest.
  ///
  /// In fr, this message translates to:
  /// **'Autre intérêt'**
  String get other_interest;

  /// No description provided for @validate_profile.
  ///
  /// In fr, this message translates to:
  /// **'Valider mon profil'**
  String get validate_profile;

  /// No description provided for @profile_edit_later.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez modifier ces informations à tout moment dans vos Réglages.'**
  String get profile_edit_later;

  /// No description provided for @forgot_title.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgot_title;

  /// No description provided for @forgot_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre adresse email académique pour recevoir un code d\'authentification à 4 chiffres.'**
  String get forgot_subtitle;

  /// No description provided for @security_recovery.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité & Récupération'**
  String get security_recovery;

  /// No description provided for @institutional_email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail institutionnelle'**
  String get institutional_email;

  /// No description provided for @verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiée'**
  String get verified;

  /// No description provided for @pending_badge.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pending_badge;

  /// No description provided for @resend_email.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'e-mail'**
  String get resend_email;

  /// No description provided for @otp_title.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification'**
  String get otp_title;

  /// No description provided for @otp_hint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code temporaire envoyé à'**
  String get otp_hint;

  /// No description provided for @expires_in.
  ///
  /// In fr, this message translates to:
  /// **'Expire dans :'**
  String get expires_in;

  /// No description provided for @resend_code.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resend_code;

  /// No description provided for @verify_code.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le code'**
  String get verify_code;

  /// No description provided for @security_guaranteed_title.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité académique garantie'**
  String get security_guaranteed_title;

  /// No description provided for @security_guaranteed_desc.
  ///
  /// In fr, this message translates to:
  /// **'Vos identifiants et clés de chiffrement sont protégés selon le protocole universitaire RGPD & SSO.'**
  String get security_guaranteed_desc;

  /// No description provided for @back_to_login.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get back_to_login;

  /// No description provided for @role_teacher.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant'**
  String get role_teacher;

  /// No description provided for @role_student.
  ///
  /// In fr, this message translates to:
  /// **'Étudiant'**
  String get role_student;

  /// No description provided for @role_admin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get role_admin;

  /// No description provided for @select_role.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre rôle'**
  String get select_role;

  /// No description provided for @teacher_description.
  ///
  /// In fr, this message translates to:
  /// **'Créer des cours, gérer des classes, évaluer les étudiants'**
  String get teacher_description;

  /// No description provided for @student_description.
  ///
  /// In fr, this message translates to:
  /// **'Accéder aux cours, participer aux examens, collaborer'**
  String get student_description;

  /// No description provided for @admin_description.
  ///
  /// In fr, this message translates to:
  /// **'Gérer la plateforme, superviser les utilisateurs'**
  String get admin_description;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @courses.
  ///
  /// In fr, this message translates to:
  /// **'Cours'**
  String get courses;

  /// No description provided for @groups.
  ///
  /// In fr, this message translates to:
  /// **'Groupes'**
  String get groups;

  /// No description provided for @exams.
  ///
  /// In fr, this message translates to:
  /// **'Examens'**
  String get exams;

  /// No description provided for @videoconference.
  ///
  /// In fr, this message translates to:
  /// **'Visioconférence'**
  String get videoconference;

  /// No description provided for @collaboration.
  ///
  /// In fr, this message translates to:
  /// **'Collaboration'**
  String get collaboration;

  /// No description provided for @ai_assistant.
  ///
  /// In fr, this message translates to:
  /// **'Assistant IA'**
  String get ai_assistant;

  /// No description provided for @community.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get community;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @calendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendar;

  /// No description provided for @messages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @nav_my_courses.
  ///
  /// In fr, this message translates to:
  /// **'Mes Cours'**
  String get nav_my_courses;

  /// No description provided for @my_courses.
  ///
  /// In fr, this message translates to:
  /// **'Mes cours'**
  String get my_courses;

  /// No description provided for @create_course.
  ///
  /// In fr, this message translates to:
  /// **'Créer un cours'**
  String get create_course;

  /// No description provided for @edit_course.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le cours'**
  String get edit_course;

  /// No description provided for @course_title.
  ///
  /// In fr, this message translates to:
  /// **'Titre du cours'**
  String get course_title;

  /// No description provided for @course_description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get course_description;

  /// No description provided for @course_content.
  ///
  /// In fr, this message translates to:
  /// **'Contenu du cours'**
  String get course_content;

  /// No description provided for @import_pdf.
  ///
  /// In fr, this message translates to:
  /// **'Importer un PDF'**
  String get import_pdf;

  /// No description provided for @generate_with_ai.
  ///
  /// In fr, this message translates to:
  /// **'Générer avec l\'IA'**
  String get generate_with_ai;

  /// No description provided for @publish_course.
  ///
  /// In fr, this message translates to:
  /// **'Publier le cours'**
  String get publish_course;

  /// No description provided for @draft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get draft;

  /// No description provided for @published.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get published;

  /// No description provided for @archived.
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get archived;

  /// No description provided for @course_created.
  ///
  /// In fr, this message translates to:
  /// **'Cours créé avec succès'**
  String get course_created;

  /// No description provided for @course_updated.
  ///
  /// In fr, this message translates to:
  /// **'Cours mis à jour'**
  String get course_updated;

  /// No description provided for @course_deleted.
  ///
  /// In fr, this message translates to:
  /// **'Cours supprimé'**
  String get course_deleted;

  /// No description provided for @delete_course_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ce cours ?'**
  String get delete_course_confirm;

  /// No description provided for @course_details.
  ///
  /// In fr, this message translates to:
  /// **'Détails du cours'**
  String get course_details;

  /// No description provided for @course_progress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get course_progress;

  /// No description provided for @lessons.
  ///
  /// In fr, this message translates to:
  /// **'Leçons'**
  String get lessons;

  /// No description provided for @resources.
  ///
  /// In fr, this message translates to:
  /// **'Ressources'**
  String get resources;

  /// No description provided for @no_courses.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cours disponible'**
  String get no_courses;

  /// No description provided for @join_course.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre un cours'**
  String get join_course;

  /// No description provided for @leave_course.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le cours'**
  String get leave_course;

  /// No description provided for @my_groups.
  ///
  /// In fr, this message translates to:
  /// **'Mes groupes'**
  String get my_groups;

  /// No description provided for @create_group.
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe'**
  String get create_group;

  /// No description provided for @group_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get group_name;

  /// No description provided for @group_code.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get group_code;

  /// No description provided for @join_group.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre un groupe'**
  String get join_group;

  /// No description provided for @leave_group.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le groupe'**
  String get leave_group;

  /// No description provided for @group_members.
  ///
  /// In fr, this message translates to:
  /// **'Membres du groupe'**
  String get group_members;

  /// No description provided for @invite_students.
  ///
  /// In fr, this message translates to:
  /// **'Inviter des étudiants'**
  String get invite_students;

  /// No description provided for @remove_student.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'étudiant'**
  String get remove_student;

  /// No description provided for @group_created.
  ///
  /// In fr, this message translates to:
  /// **'Groupe créé'**
  String get group_created;

  /// No description provided for @group_updated.
  ///
  /// In fr, this message translates to:
  /// **'Groupe mis à jour'**
  String get group_updated;

  /// No description provided for @invalid_group_code.
  ///
  /// In fr, this message translates to:
  /// **'Code de groupe invalide'**
  String get invalid_group_code;

  /// No description provided for @join_group_success.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez rejoint le groupe'**
  String get join_group_success;

  /// No description provided for @no_groups.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe'**
  String get no_groups;

  /// No description provided for @manage_groups.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les groupes'**
  String get manage_groups;

  /// No description provided for @teacher.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant'**
  String get teacher;

  /// No description provided for @students.
  ///
  /// In fr, this message translates to:
  /// **'Étudiants'**
  String get students;

  /// No description provided for @pending_invitations.
  ///
  /// In fr, this message translates to:
  /// **'Invitations en attente'**
  String get pending_invitations;

  /// No description provided for @accept_invitation.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get accept_invitation;

  /// No description provided for @decline_invitation.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get decline_invitation;

  /// No description provided for @my_exams.
  ///
  /// In fr, this message translates to:
  /// **'Mes examens'**
  String get my_exams;

  /// No description provided for @create_exam.
  ///
  /// In fr, this message translates to:
  /// **'Créer un examen'**
  String get create_exam;

  /// No description provided for @exam_title.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'examen'**
  String get exam_title;

  /// No description provided for @exam_duration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get exam_duration;

  /// No description provided for @exam_date.
  ///
  /// In fr, this message translates to:
  /// **'Date de l\'examen'**
  String get exam_date;

  /// No description provided for @select_chapters.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner les chapitres'**
  String get select_chapters;

  /// No description provided for @generate_exam.
  ///
  /// In fr, this message translates to:
  /// **'Générer l\'examen'**
  String get generate_exam;

  /// No description provided for @start_exam.
  ///
  /// In fr, this message translates to:
  /// **'Commencer l\'examen'**
  String get start_exam;

  /// No description provided for @submit_exam.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre l\'examen'**
  String get submit_exam;

  /// No description provided for @exam_results.
  ///
  /// In fr, this message translates to:
  /// **'Résultats de l\'examen'**
  String get exam_results;

  /// No description provided for @exam_completed.
  ///
  /// In fr, this message translates to:
  /// **'Examen terminé'**
  String get exam_completed;

  /// No description provided for @exam_in_progress.
  ///
  /// In fr, this message translates to:
  /// **'Examen en cours'**
  String get exam_in_progress;

  /// No description provided for @exam_not_started.
  ///
  /// In fr, this message translates to:
  /// **'Examen non commencé'**
  String get exam_not_started;

  /// No description provided for @time_remaining.
  ///
  /// In fr, this message translates to:
  /// **'Temps restant'**
  String get time_remaining;

  /// No description provided for @anti_fraude_active.
  ///
  /// In fr, this message translates to:
  /// **'Mode anti-fraude activé'**
  String get anti_fraude_active;

  /// No description provided for @fullscreen_required.
  ///
  /// In fr, this message translates to:
  /// **'Plein écran requis'**
  String get fullscreen_required;

  /// No description provided for @focus_lock_active.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage du focus actif'**
  String get focus_lock_active;

  /// No description provided for @copy_paste_blocked.
  ///
  /// In fr, this message translates to:
  /// **'Copier-coller bloqué'**
  String get copy_paste_blocked;

  /// No description provided for @exam_submitted.
  ///
  /// In fr, this message translates to:
  /// **'Examen soumis avec succès'**
  String get exam_submitted;

  /// No description provided for @score.
  ///
  /// In fr, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @passed.
  ///
  /// In fr, this message translates to:
  /// **'Réussi'**
  String get passed;

  /// No description provided for @failed.
  ///
  /// In fr, this message translates to:
  /// **'Échoué'**
  String get failed;

  /// No description provided for @review_answers.
  ///
  /// In fr, this message translates to:
  /// **'Revoir les réponses'**
  String get review_answers;

  /// No description provided for @correct_answer.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse'**
  String get correct_answer;

  /// No description provided for @incorrect_answer.
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise réponse'**
  String get incorrect_answer;

  /// No description provided for @no_exams.
  ///
  /// In fr, this message translates to:
  /// **'Aucun examen disponible'**
  String get no_exams;

  /// No description provided for @simulation_exam.
  ///
  /// In fr, this message translates to:
  /// **'Simulation d\'examen'**
  String get simulation_exam;

  /// No description provided for @official_exam.
  ///
  /// In fr, this message translates to:
  /// **'Examen officiel'**
  String get official_exam;

  /// No description provided for @practice_mode.
  ///
  /// In fr, this message translates to:
  /// **'Mode entraînement'**
  String get practice_mode;

  /// No description provided for @live_sessions.
  ///
  /// In fr, this message translates to:
  /// **'Sessions en direct'**
  String get live_sessions;

  /// No description provided for @scheduled_sessions.
  ///
  /// In fr, this message translates to:
  /// **'Sessions programmées'**
  String get scheduled_sessions;

  /// No description provided for @past_sessions.
  ///
  /// In fr, this message translates to:
  /// **'Sessions passées'**
  String get past_sessions;

  /// No description provided for @start_session.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer la session'**
  String get start_session;

  /// No description provided for @join_session.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre la session'**
  String get join_session;

  /// No description provided for @session_title.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la session'**
  String get session_title;

  /// No description provided for @session_description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get session_description;

  /// No description provided for @session_date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get session_date;

  /// No description provided for @session_duration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get session_duration;

  /// No description provided for @recording.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement'**
  String get recording;

  /// No description provided for @recording_started.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement démarré'**
  String get recording_started;

  /// No description provided for @recording_stopped.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement arrêté'**
  String get recording_stopped;

  /// No description provided for @replay_available.
  ///
  /// In fr, this message translates to:
  /// **'Replay disponible'**
  String get replay_available;

  /// No description provided for @summary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get summary;

  /// No description provided for @transcription.
  ///
  /// In fr, this message translates to:
  /// **'Transcription'**
  String get transcription;

  /// No description provided for @participants.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @host.
  ///
  /// In fr, this message translates to:
  /// **'Hôte'**
  String get host;

  /// No description provided for @no_sessions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune session'**
  String get no_sessions;

  /// No description provided for @session_ended.
  ///
  /// In fr, this message translates to:
  /// **'Session terminée'**
  String get session_ended;

  /// No description provided for @waiting_for_host.
  ///
  /// In fr, this message translates to:
  /// **'En attente de l\'hôte'**
  String get waiting_for_host;

  /// No description provided for @microphone.
  ///
  /// In fr, this message translates to:
  /// **'Microphone'**
  String get microphone;

  /// No description provided for @camera.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get camera;

  /// No description provided for @screen_share.
  ///
  /// In fr, this message translates to:
  /// **'Partage d\'écran'**
  String get screen_share;

  /// No description provided for @chat.
  ///
  /// In fr, this message translates to:
  /// **'Discussion'**
  String get chat;

  /// No description provided for @raise_hand.
  ///
  /// In fr, this message translates to:
  /// **'Lever la main'**
  String get raise_hand;

  /// No description provided for @shared_resources.
  ///
  /// In fr, this message translates to:
  /// **'Ressources partagées'**
  String get shared_resources;

  /// No description provided for @share_resource.
  ///
  /// In fr, this message translates to:
  /// **'Partager une ressource'**
  String get share_resource;

  /// No description provided for @my_shares.
  ///
  /// In fr, this message translates to:
  /// **'Mes partages'**
  String get my_shares;

  /// No description provided for @resource_title.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la ressource'**
  String get resource_title;

  /// No description provided for @resource_type.
  ///
  /// In fr, this message translates to:
  /// **'Type de ressource'**
  String get resource_type;

  /// No description provided for @resource_file.
  ///
  /// In fr, this message translates to:
  /// **'Fichier'**
  String get resource_file;

  /// No description provided for @resource_link.
  ///
  /// In fr, this message translates to:
  /// **'Lien'**
  String get resource_link;

  /// No description provided for @study_sessions.
  ///
  /// In fr, this message translates to:
  /// **'Sessions d\'étude'**
  String get study_sessions;

  /// No description provided for @create_study_session.
  ///
  /// In fr, this message translates to:
  /// **'Créer une session d\'étude'**
  String get create_study_session;

  /// No description provided for @session_topic.
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get session_topic;

  /// No description provided for @session_date_time.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get session_date_time;

  /// No description provided for @comments.
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get comments;

  /// No description provided for @add_comment.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire'**
  String get add_comment;

  /// No description provided for @no_resources.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ressource partagée'**
  String get no_resources;

  /// No description provided for @no_study_sessions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune session d\'étude'**
  String get no_study_sessions;

  /// No description provided for @join_study_session.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre la session'**
  String get join_study_session;

  /// No description provided for @resource_shared.
  ///
  /// In fr, this message translates to:
  /// **'Ressource partagée'**
  String get resource_shared;

  /// No description provided for @session_created.
  ///
  /// In fr, this message translates to:
  /// **'Session créée'**
  String get session_created;

  /// No description provided for @ask_ai.
  ///
  /// In fr, this message translates to:
  /// **'Poser une question à l\'IA'**
  String get ask_ai;

  /// No description provided for @ai_tutor.
  ///
  /// In fr, this message translates to:
  /// **'Tuteur IA'**
  String get ai_tutor;

  /// No description provided for @ai_generating.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA génère...'**
  String get ai_generating;

  /// No description provided for @ai_response.
  ///
  /// In fr, this message translates to:
  /// **'Réponse de l\'IA'**
  String get ai_response;

  /// No description provided for @generate_test.
  ///
  /// In fr, this message translates to:
  /// **'Générer un test'**
  String get generate_test;

  /// No description provided for @generate_course.
  ///
  /// In fr, this message translates to:
  /// **'Générer un cours'**
  String get generate_course;

  /// No description provided for @reformulate.
  ///
  /// In fr, this message translates to:
  /// **'Reformuler'**
  String get reformulate;

  /// No description provided for @summarize.
  ///
  /// In fr, this message translates to:
  /// **'Résumer'**
  String get summarize;

  /// No description provided for @explain.
  ///
  /// In fr, this message translates to:
  /// **'Expliquer'**
  String get explain;

  /// No description provided for @give_examples.
  ///
  /// In fr, this message translates to:
  /// **'Donner des exemples'**
  String get give_examples;

  /// No description provided for @step_by_step.
  ///
  /// In fr, this message translates to:
  /// **'Pas à pas'**
  String get step_by_step;

  /// No description provided for @ai_context.
  ///
  /// In fr, this message translates to:
  /// **'Contexte : ce cours uniquement'**
  String get ai_context;

  /// No description provided for @private_conversation.
  ///
  /// In fr, this message translates to:
  /// **'Conversation privée'**
  String get private_conversation;

  /// No description provided for @no_ai_history.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation'**
  String get no_ai_history;

  /// No description provided for @clear_history.
  ///
  /// In fr, this message translates to:
  /// **'Effacer l\'historique'**
  String get clear_history;

  /// No description provided for @ai_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de l\'IA, réessayez plus tard'**
  String get ai_error;

  /// No description provided for @student_greeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String student_greeting(String name);

  /// No description provided for @student_greeting_default.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour Salma'**
  String get student_greeting_default;

  /// No description provided for @student_degree_info.
  ///
  /// In fr, this message translates to:
  /// **'Licence 3 Informatique · Semestre 1'**
  String get student_degree_info;

  /// No description provided for @active_streak.
  ///
  /// In fr, this message translates to:
  /// **'Série active'**
  String get active_streak;

  /// No description provided for @streak_consecutive_days.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours consécutifs'**
  String streak_consecutive_days(Object count);

  /// No description provided for @weekly_goal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif hebdo'**
  String get weekly_goal;

  /// No description provided for @goal_reached.
  ///
  /// In fr, this message translates to:
  /// **'{pct}% atteint'**
  String goal_reached(Object pct);

  /// No description provided for @live_imminent.
  ///
  /// In fr, this message translates to:
  /// **'LIVE IMMINENT'**
  String get live_imminent;

  /// No description provided for @in_minutes.
  ///
  /// In fr, this message translates to:
  /// **'Dans {min} min'**
  String in_minutes(Object min);

  /// No description provided for @join_live.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre le Live'**
  String get join_live;

  /// No description provided for @studio_ia_title.
  ///
  /// In fr, this message translates to:
  /// **'Studio IA · Révisions & Quiz'**
  String get studio_ia_title;

  /// No description provided for @studio_ia_desc.
  ///
  /// In fr, this message translates to:
  /// **'Génère un résumé de cours instantané ou crée un quiz d\'entraînement sur-mesure.'**
  String get studio_ia_desc;

  /// No description provided for @course_summary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de cours'**
  String get course_summary;

  /// No description provided for @course_summary_desc.
  ///
  /// In fr, this message translates to:
  /// **'Fiches & synthèse intelligente'**
  String get course_summary_desc;

  /// No description provided for @generate_action.
  ///
  /// In fr, this message translates to:
  /// **'Générer ✨'**
  String get generate_action;

  /// No description provided for @practice_quiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz d\'entraînement'**
  String get practice_quiz;

  /// No description provided for @practice_quiz_desc.
  ///
  /// In fr, this message translates to:
  /// **'Questions sur-mesure & QCM'**
  String get practice_quiz_desc;

  /// No description provided for @create_action.
  ///
  /// In fr, this message translates to:
  /// **'Créer ⚡'**
  String get create_action;

  /// No description provided for @enrolled_count.
  ///
  /// In fr, this message translates to:
  /// **'({count} inscrits)'**
  String enrolled_count(Object count);

  /// No description provided for @student_course_progress.
  ///
  /// In fr, this message translates to:
  /// **'Progression du cours'**
  String get student_course_progress;

  /// No description provided for @up_to_date.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get up_to_date;

  /// No description provided for @in_progress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get in_progress;

  /// No description provided for @upcoming_homework.
  ///
  /// In fr, this message translates to:
  /// **'Prochains Devoirs'**
  String get upcoming_homework;

  /// No description provided for @pending_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} en attente'**
  String pending_count(Object count);

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @questions_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} questions'**
  String questions_count(Object count);

  /// No description provided for @est_time.
  ///
  /// In fr, this message translates to:
  /// **'~{min} min'**
  String est_time(Object min);

  /// No description provided for @today_time.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui, {time}'**
  String today_time(String time);

  /// No description provided for @tomorrow_time.
  ///
  /// In fr, this message translates to:
  /// **'Demain, {time}'**
  String tomorrow_time(String time);

  /// No description provided for @starts_action.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get starts_action;

  /// No description provided for @deposit_action.
  ///
  /// In fr, this message translates to:
  /// **'Déposer'**
  String get deposit_action;

  /// No description provided for @cc_grade_weight.
  ///
  /// In fr, this message translates to:
  /// **'Comptant pour {pct}% de la note CC'**
  String cc_grade_weight(Object pct);

  /// No description provided for @auto_ai_validation.
  ///
  /// In fr, this message translates to:
  /// **'Validation automatique par l\'IA activée'**
  String get auto_ai_validation;

  /// No description provided for @git_or_file_desc.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt Git ou fichier .py'**
  String get git_or_file_desc;

  /// No description provided for @online_scheduled.
  ///
  /// In fr, this message translates to:
  /// **'Prévu en ligne'**
  String get online_scheduled;

  /// No description provided for @view_all.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get view_all;

  /// No description provided for @last_lesson.
  ///
  /// In fr, this message translates to:
  /// **'Dernière leçon'**
  String get last_lesson;

  /// No description provided for @next_step.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine étape'**
  String get next_step;

  /// No description provided for @greeting_hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,'**
  String get greeting_hello;

  /// No description provided for @teacher_badge.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant'**
  String get teacher_badge;

  /// No description provided for @next_live.
  ///
  /// In fr, this message translates to:
  /// **'Prochain direct · {time}'**
  String next_live(String time);

  /// No description provided for @stat_students.
  ///
  /// In fr, this message translates to:
  /// **'Étudiants'**
  String get stat_students;

  /// No description provided for @stat_active_courses.
  ///
  /// In fr, this message translates to:
  /// **'Cours Actifs'**
  String get stat_active_courses;

  /// No description provided for @stat_to_grade.
  ///
  /// In fr, this message translates to:
  /// **'À corriger'**
  String get stat_to_grade;

  /// No description provided for @stat_this_week.
  ///
  /// In fr, this message translates to:
  /// **'+8 sem.'**
  String get stat_this_week;

  /// No description provided for @stat_semester_2.
  ///
  /// In fr, this message translates to:
  /// **'Semestre 2'**
  String get stat_semester_2;

  /// No description provided for @stat_urgent.
  ///
  /// In fr, this message translates to:
  /// **'Urgent'**
  String get stat_urgent;

  /// No description provided for @ai_banner_kicker.
  ///
  /// In fr, this message translates to:
  /// **'Assistant Pédagogique IA'**
  String get ai_banner_kicker;

  /// No description provided for @ai_banner_title.
  ///
  /// In fr, this message translates to:
  /// **'Créer un cours avec l\'IA'**
  String get ai_banner_title;

  /// No description provided for @ai_banner_desc.
  ///
  /// In fr, this message translates to:
  /// **'Générez un plan de cours interactif, des quiz et exercices en quelques secondes.'**
  String get ai_banner_desc;

  /// No description provided for @generate_now.
  ///
  /// In fr, this message translates to:
  /// **'Générer maintenant'**
  String get generate_now;

  /// No description provided for @my_classes.
  ///
  /// In fr, this message translates to:
  /// **'Mes Classes'**
  String get my_classes;

  /// No description provided for @view_all_count.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout ({count})'**
  String view_all_count(Object count);

  /// No description provided for @completion_rate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de complétion'**
  String get completion_rate;

  /// No description provided for @access_class.
  ///
  /// In fr, this message translates to:
  /// **'Accéder à la classe'**
  String get access_class;

  /// No description provided for @homework_count.
  ///
  /// In fr, this message translates to:
  /// **'Devoirs ({count})'**
  String homework_count(Object count);

  /// No description provided for @course_editor.
  ///
  /// In fr, this message translates to:
  /// **'Course Editor'**
  String get course_editor;

  /// No description provided for @ai_engine_banner.
  ///
  /// In fr, this message translates to:
  /// **'Moteur Pédagogique IA v3.2'**
  String get ai_engine_banner;

  /// No description provided for @ai_create_title.
  ///
  /// In fr, this message translates to:
  /// **'Créer un cours assisté par IA'**
  String get ai_create_title;

  /// No description provided for @ai_create_desc.
  ///
  /// In fr, this message translates to:
  /// **'Fournissez vos supports de cours ou décrivez vos objectifs. L\'IA structure le plan, les leçons, les quiz et les exercices interactifs.'**
  String get ai_create_desc;

  /// No description provided for @smart_designer.
  ///
  /// In fr, this message translates to:
  /// **'Concepteur intelligent'**
  String get smart_designer;

  /// No description provided for @smart_designer_desc.
  ///
  /// In fr, this message translates to:
  /// **'Structurez vos unités d\'enseignement conformément aux normes LMD et référentiels européens.'**
  String get smart_designer_desc;

  /// No description provided for @drop_pdf_title.
  ///
  /// In fr, this message translates to:
  /// **'Glisser un PDF/Document source ici'**
  String get drop_pdf_title;

  /// No description provided for @drop_pdf_formats.
  ///
  /// In fr, this message translates to:
  /// **'Formats acceptés : PDF, Word (.docx), PPTX ou Markdown (max 50 Mo)'**
  String get drop_pdf_formats;

  /// No description provided for @browse_files.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir les fichiers'**
  String get browse_files;

  /// No description provided for @or_divider.
  ///
  /// In fr, this message translates to:
  /// **'OU'**
  String get or_divider;

  /// No description provided for @topic_label.
  ///
  /// In fr, this message translates to:
  /// **'Sujet ou consignes spécifiques'**
  String get topic_label;

  /// No description provided for @topic_hint.
  ///
  /// In fr, this message translates to:
  /// **'Ou décrivez le sujet du cours... Ex: \'Introduction aux bases de données relationnelles et requêtes SQL avancées pour Licence 3 Informatique avec 4 chapitres et exercices corrigés\''**
  String get topic_hint;

  /// No description provided for @module_suggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions de modules'**
  String get module_suggestions;

  /// No description provided for @chip_detailed_plan.
  ///
  /// In fr, this message translates to:
  /// **'Plan détaillé'**
  String get chip_detailed_plan;

  /// No description provided for @chip_quiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz interactif inclus'**
  String get chip_quiz;

  /// No description provided for @chip_exercises.
  ///
  /// In fr, this message translates to:
  /// **'Exercices pratiques'**
  String get chip_exercises;

  /// No description provided for @chip_cases.
  ///
  /// In fr, this message translates to:
  /// **'Études de cas'**
  String get chip_cases;

  /// No description provided for @subject_label.
  ///
  /// In fr, this message translates to:
  /// **'Matière académique'**
  String get subject_label;

  /// No description provided for @academic_level_label.
  ///
  /// In fr, this message translates to:
  /// **'Niveau académique'**
  String get academic_level_label;

  /// No description provided for @ai_params.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres d\'alignement IA'**
  String get ai_params;

  /// No description provided for @opt_quiz_title.
  ///
  /// In fr, this message translates to:
  /// **'Générer un quiz d\'évaluation automatique'**
  String get opt_quiz_title;

  /// No description provided for @opt_quiz_desc.
  ///
  /// In fr, this message translates to:
  /// **'Intègre 10 QCM d\'assimilation avec barème et corrigés commentés'**
  String get opt_quiz_desc;

  /// No description provided for @opt_tone_title.
  ///
  /// In fr, this message translates to:
  /// **'Adapter le ton pédagogique universitaire'**
  String get opt_tone_title;

  /// No description provided for @opt_tone_desc.
  ///
  /// In fr, this message translates to:
  /// **'Vocabulaire soutenu, rigueur méthodologique et contextualisations'**
  String get opt_tone_desc;

  /// No description provided for @generate_course_full.
  ///
  /// In fr, this message translates to:
  /// **'Générer le cours complet'**
  String get generate_course_full;

  /// No description provided for @generating_course.
  ///
  /// In fr, this message translates to:
  /// **'Structuration IA en cours...'**
  String get generating_course;

  /// No description provided for @course_generated.
  ///
  /// In fr, this message translates to:
  /// **'Cours généré avec succès !'**
  String get course_generated;

  /// No description provided for @estimate_rgpd.
  ///
  /// In fr, this message translates to:
  /// **'Estimation : ~20 secondes • Modèle certifié RGPD Pédagogie Sup'**
  String get estimate_rgpd;

  /// No description provided for @my_profile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get my_profile;

  /// No description provided for @edit_profile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get edit_profile;

  /// No description provided for @first_name.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get last_name;

  /// No description provided for @date_of_birth.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get date_of_birth;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @bio.
  ///
  /// In fr, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @avatar.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get avatar;

  /// No description provided for @change_avatar.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get change_avatar;

  /// No description provided for @profile_updated.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour'**
  String get profile_updated;

  /// No description provided for @account_settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du compte'**
  String get account_settings;

  /// No description provided for @change_password.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get change_password;

  /// No description provided for @current_password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get current_password;

  /// No description provided for @new_password.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get new_password;

  /// No description provided for @password_changed.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get password_changed;

  /// No description provided for @delete_account.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get delete_account;

  /// No description provided for @delete_account_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Êtes-vous sûr ?'**
  String get delete_account_confirm;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @font_size.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte'**
  String get font_size;

  /// No description provided for @font_family.
  ///
  /// In fr, this message translates to:
  /// **'Police'**
  String get font_family;

  /// No description provided for @theme_mode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de thème'**
  String get theme_mode;

  /// No description provided for @light_mode.
  ///
  /// In fr, this message translates to:
  /// **'Mode clair'**
  String get light_mode;

  /// No description provided for @dark_mode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get dark_mode;

  /// No description provided for @system_mode.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get system_mode;

  /// No description provided for @notifications_settings.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications_settings;

  /// No description provided for @push_notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get push_notifications;

  /// No description provided for @email_notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications email'**
  String get email_notifications;

  /// No description provided for @data_privacy.
  ///
  /// In fr, this message translates to:
  /// **'Données et confidentialité'**
  String get data_privacy;

  /// No description provided for @export_data.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get export_data;

  /// No description provided for @clear_cache.
  ///
  /// In fr, this message translates to:
  /// **'Vider le cache'**
  String get clear_cache;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @terms_of_service.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get terms_of_service;

  /// No description provided for @privacy_policy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacy_policy;

  /// No description provided for @open_source_licenses.
  ///
  /// In fr, this message translates to:
  /// **'Licences open source'**
  String get open_source_licenses;

  /// No description provided for @send_feedback.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un retour'**
  String get send_feedback;

  /// No description provided for @rate_app.
  ///
  /// In fr, this message translates to:
  /// **'Noter l\'application'**
  String get rate_app;

  /// No description provided for @small.
  ///
  /// In fr, this message translates to:
  /// **'Petit'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In fr, this message translates to:
  /// **'Grand'**
  String get large;

  /// No description provided for @extra_large.
  ///
  /// In fr, this message translates to:
  /// **'Très grand'**
  String get extra_large;

  /// No description provided for @font_size_changed.
  ///
  /// In fr, this message translates to:
  /// **'Taille de police modifiée'**
  String get font_size_changed;

  /// No description provided for @language_changed.
  ///
  /// In fr, this message translates to:
  /// **'Langue modifiée'**
  String get language_changed;

  /// No description provided for @theme_changed.
  ///
  /// In fr, this message translates to:
  /// **'Thème modifié'**
  String get theme_changed;

  /// No description provided for @settings_saved.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres enregistrés'**
  String get settings_saved;

  /// No description provided for @no_internet.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet'**
  String get no_internet;

  /// No description provided for @check_connection.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion'**
  String get check_connection;

  /// No description provided for @server_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du serveur'**
  String get server_error;

  /// No description provided for @unauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Non autorisé'**
  String get unauthorized;

  /// No description provided for @session_expired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée'**
  String get session_expired;

  /// No description provided for @please_login_again.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous reconnecter'**
  String get please_login_again;

  /// No description provided for @feature_coming_soon.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité à venir'**
  String get feature_coming_soon;

  /// No description provided for @under_development.
  ///
  /// In fr, this message translates to:
  /// **'En développement'**
  String get under_development;

  /// No description provided for @required_field.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get required_field;

  /// No description provided for @invalid_format.
  ///
  /// In fr, this message translates to:
  /// **'Format invalide'**
  String get invalid_format;

  /// No description provided for @min_length.
  ///
  /// In fr, this message translates to:
  /// **'Minimum {count} caractères'**
  String min_length(Object count);

  /// No description provided for @max_length.
  ///
  /// In fr, this message translates to:
  /// **'Maximum {count} caractères'**
  String max_length(Object count);

  /// No description provided for @invalid_number.
  ///
  /// In fr, this message translates to:
  /// **'Nombre invalide'**
  String get invalid_number;

  /// No description provided for @invalid_date.
  ///
  /// In fr, this message translates to:
  /// **'Date invalide'**
  String get invalid_date;

  /// No description provided for @future_date_required.
  ///
  /// In fr, this message translates to:
  /// **'La date doit être dans le futur'**
  String get future_date_required;

  /// No description provided for @past_date_required.
  ///
  /// In fr, this message translates to:
  /// **'La date doit être dans le passé'**
  String get past_date_required;

  /// No description provided for @ai_revision_title.
  ///
  /// In fr, this message translates to:
  /// **'Générer Mes Révisions'**
  String get ai_revision_title;

  /// No description provided for @ai_revision_header.
  ///
  /// In fr, this message translates to:
  /// **'Assistant de Révision IA'**
  String get ai_revision_header;

  /// No description provided for @ai_model_l3_badge.
  ///
  /// In fr, this message translates to:
  /// **'Modèle L3 Optimisé ✨'**
  String get ai_model_l3_badge;

  /// No description provided for @ai_revision_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Transformez instantanément vos supports universitaires en synthèses dynamiques et cartes mémorielles.'**
  String get ai_revision_subtitle;

  /// No description provided for @ai_source_step_title.
  ///
  /// In fr, this message translates to:
  /// **'Source du cours'**
  String get ai_source_step_title;

  /// No description provided for @ai_ent_presynced.
  ///
  /// In fr, this message translates to:
  /// **'Pré-synchronisé ENT'**
  String get ai_ent_presynced;

  /// No description provided for @ai_select_module.
  ///
  /// In fr, this message translates to:
  /// **'SÉLECTIONNER UN MODULE'**
  String get ai_select_module;

  /// No description provided for @ai_select_module_modal_title.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner votre module'**
  String get ai_select_module_modal_title;

  /// No description provided for @ai_import_doc_title.
  ///
  /// In fr, this message translates to:
  /// **'Importer un PDF / Doc personnel'**
  String get ai_import_doc_title;

  /// No description provided for @ai_import_doc_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Glissez votre cours ou TD (PDF, DOCX, TXT max 25 Mo)'**
  String get ai_import_doc_subtitle;

  /// No description provided for @ai_import_doc_ready.
  ///
  /// In fr, this message translates to:
  /// **'Document prêt pour la synthèse sémantique'**
  String get ai_import_doc_ready;

  /// No description provided for @ai_import_doc_success.
  ///
  /// In fr, this message translates to:
  /// **'Document universitaire importé avec succès !'**
  String get ai_import_doc_success;

  /// No description provided for @ai_format_step_title.
  ///
  /// In fr, this message translates to:
  /// **'Format souhaité'**
  String get ai_format_step_title;

  /// No description provided for @ai_active_selection.
  ///
  /// In fr, this message translates to:
  /// **'Sélection active'**
  String get ai_active_selection;

  /// No description provided for @ai_format_step_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la structure d\'assimilation cognitive la plus adaptée à vos révisions.'**
  String get ai_format_step_subtitle;

  /// No description provided for @ai_format_express.
  ///
  /// In fr, this message translates to:
  /// **'Résumé express'**
  String get ai_format_express;

  /// No description provided for @ai_format_express_badge.
  ///
  /// In fr, this message translates to:
  /// **'⏱️ Lecture 3 min'**
  String get ai_format_express_badge;

  /// No description provided for @ai_format_express_desc.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse dense avec points-clés et théorèmes majeurs.'**
  String get ai_format_express_desc;

  /// No description provided for @ai_format_flashcards.
  ///
  /// In fr, this message translates to:
  /// **'Fiches mémo (Flashcards)'**
  String get ai_format_flashcards;

  /// No description provided for @ai_format_flashcards_badge.
  ///
  /// In fr, this message translates to:
  /// **'🗂️ 15 cartes'**
  String get ai_format_flashcards_badge;

  /// No description provided for @ai_format_flashcards_desc.
  ///
  /// In fr, this message translates to:
  /// **'Répétition espacée idéale pour mémoriser les formules.'**
  String get ai_format_flashcards_desc;

  /// No description provided for @ai_format_mindmap.
  ///
  /// In fr, this message translates to:
  /// **'Carte mentale'**
  String get ai_format_mindmap;

  /// No description provided for @ai_format_mindmap_badge.
  ///
  /// In fr, this message translates to:
  /// **'🧠 Arborescence'**
  String get ai_format_mindmap_badge;

  /// No description provided for @ai_format_mindmap_desc.
  ///
  /// In fr, this message translates to:
  /// **'Vision panoramique et interdépendances logiques.'**
  String get ai_format_mindmap_desc;

  /// No description provided for @ai_granularity_step_title.
  ///
  /// In fr, this message translates to:
  /// **'Niveau de détail'**
  String get ai_granularity_step_title;

  /// No description provided for @ai_granularity_concise.
  ///
  /// In fr, this message translates to:
  /// **'Concis'**
  String get ai_granularity_concise;

  /// No description provided for @ai_granularity_balanced.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré'**
  String get ai_granularity_balanced;

  /// No description provided for @ai_granularity_detailed.
  ///
  /// In fr, this message translates to:
  /// **'Détaillé'**
  String get ai_granularity_detailed;

  /// No description provided for @ai_granularity_desc_concise.
  ///
  /// In fr, this message translates to:
  /// **'Focus ultra-rapide : définitions directes, axiomes vitaux et aide-mémoire condensé pour les 10 dernières minutes avant l\'examen.'**
  String get ai_granularity_desc_concise;

  /// No description provided for @ai_granularity_desc_balanced.
  ///
  /// In fr, this message translates to:
  /// **'Inclusions automatiques : théorèmes majeurs, extraits de code syntaxiques et calculs de complexité asymptotique O(n).'**
  String get ai_granularity_desc_balanced;

  /// No description provided for @ai_granularity_desc_detailed.
  ///
  /// In fr, this message translates to:
  /// **'Exhaustivité académique : démonstrations complètes pas à pas, variantes d\'exercices d\'annales et cas limites d\'implémentation.'**
  String get ai_granularity_desc_detailed;

  /// No description provided for @ai_generate_summary_btn.
  ///
  /// In fr, this message translates to:
  /// **'Générer le résumé via IA ✨'**
  String get ai_generate_summary_btn;

  /// No description provided for @ai_generating_analysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse sémantique en cours...'**
  String get ai_generating_analysis;

  /// No description provided for @ai_generate_subtext.
  ///
  /// In fr, this message translates to:
  /// **'Génération moyenne en 15 secondes • 100% aligné sur le programme'**
  String get ai_generate_subtext;

  /// No description provided for @ai_recent_summaries_title.
  ///
  /// In fr, this message translates to:
  /// **'Mes derniers résumés'**
  String get ai_recent_summaries_title;

  /// No description provided for @ai_see_all_count.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout ({count})'**
  String ai_see_all_count(Object count);

  /// No description provided for @ai_share_link_copied.
  ///
  /// In fr, this message translates to:
  /// **'Lien de partage copié dans le presse-papiers !'**
  String get ai_share_link_copied;

  /// No description provided for @ai_summary_modal_title.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse générée via IA ✨'**
  String get ai_summary_modal_title;

  /// No description provided for @ai_export_pdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter PDF'**
  String get ai_export_pdf;

  /// No description provided for @ai_practice_action.
  ///
  /// In fr, this message translates to:
  /// **'S\'entraîner'**
  String get ai_practice_action;

  /// No description provided for @ai_quiz_title.
  ///
  /// In fr, this message translates to:
  /// **'S\'Entraîner Avec L\'IA'**
  String get ai_quiz_title;

  /// No description provided for @ai_quiz_generator_badge.
  ///
  /// In fr, this message translates to:
  /// **'Générateur de Quiz IA'**
  String get ai_quiz_generator_badge;

  /// No description provided for @ai_quiz_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Générez un test sur mesure pour évaluer et consolider vos connaissances académiques.'**
  String get ai_quiz_subtitle;

  /// No description provided for @ai_change.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get ai_change;

  /// No description provided for @ai_select_course_title.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la matière à entraîner'**
  String get ai_select_course_title;

  /// No description provided for @ai_chapters_selection.
  ///
  /// In fr, this message translates to:
  /// **'Sélection des chapitres'**
  String get ai_chapters_selection;

  /// No description provided for @ai_chapters_selected_count.
  ///
  /// In fr, this message translates to:
  /// **'({count} sélectionnés)'**
  String ai_chapters_selected_count(Object count);

  /// No description provided for @select_all.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get select_all;

  /// No description provided for @deselect_all.
  ///
  /// In fr, this message translates to:
  /// **'Tout désélectionner'**
  String get deselect_all;

  /// No description provided for @ai_all_module.
  ///
  /// In fr, this message translates to:
  /// **'Tout le module'**
  String get ai_all_module;

  /// No description provided for @ai_difficulty_level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau de difficulté'**
  String get ai_difficulty_level;

  /// No description provided for @ai_adapted_exams.
  ///
  /// In fr, this message translates to:
  /// **'Adapté aux partiels S1'**
  String get ai_adapted_exams;

  /// No description provided for @ai_diff_beginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get ai_diff_beginner;

  /// No description provided for @ai_diff_beginner_sub.
  ///
  /// In fr, this message translates to:
  /// **'Notions socles'**
  String get ai_diff_beginner_sub;

  /// No description provided for @ai_diff_intermediate.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get ai_diff_intermediate;

  /// No description provided for @ai_diff_intermediate_sub.
  ///
  /// In fr, this message translates to:
  /// **'Pièges & cas type'**
  String get ai_diff_intermediate_sub;

  /// No description provided for @ai_diff_expert.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get ai_diff_expert;

  /// No description provided for @ai_diff_expert_sub.
  ///
  /// In fr, this message translates to:
  /// **'Démonstrations'**
  String get ai_diff_expert_sub;

  /// No description provided for @ai_question_count_title.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de questions'**
  String get ai_question_count_title;

  /// No description provided for @ai_question_count_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisez la profondeur'**
  String get ai_question_count_subtitle;

  /// No description provided for @ai_questions_badge.
  ///
  /// In fr, this message translates to:
  /// **'{count} questions'**
  String ai_questions_badge(Object count);

  /// No description provided for @ai_5_express.
  ///
  /// In fr, this message translates to:
  /// **'5 (Express)'**
  String get ai_5_express;

  /// No description provided for @ai_15_standard.
  ///
  /// In fr, this message translates to:
  /// **'15 (Standard)'**
  String get ai_15_standard;

  /// No description provided for @ai_30_intensive.
  ///
  /// In fr, this message translates to:
  /// **'30 (Intensif)'**
  String get ai_30_intensive;

  /// No description provided for @ai_duration_estimate.
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée : ~{min} minutes • ~1.2 min par question'**
  String ai_duration_estimate(Object min);

  /// No description provided for @ai_evaluation_modalities.
  ///
  /// In fr, this message translates to:
  /// **'Modalités d\'évaluation'**
  String get ai_evaluation_modalities;

  /// No description provided for @ai_detailed_explanations.
  ///
  /// In fr, this message translates to:
  /// **'Explications détaillées'**
  String get ai_detailed_explanations;

  /// No description provided for @ai_detailed_exp_sub.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA analyse vos erreurs et affiche la méthodologie immédiatement après chaque réponse.'**
  String get ai_detailed_exp_sub;

  /// No description provided for @ai_restitution_format.
  ///
  /// In fr, this message translates to:
  /// **'Format de restitution'**
  String get ai_restitution_format;

  /// No description provided for @ai_timed_mode.
  ///
  /// In fr, this message translates to:
  /// **'Mode Chronométré'**
  String get ai_timed_mode;

  /// No description provided for @ai_mcq_tf.
  ///
  /// In fr, this message translates to:
  /// **'QCM & Vrai/Faux'**
  String get ai_mcq_tf;

  /// No description provided for @ai_reassurance_badge.
  ///
  /// In fr, this message translates to:
  /// **'Propulsé par le modèle SmartClass L3 • Formulé à partir des annales et objectifs du syllabus officiel 2024.'**
  String get ai_reassurance_badge;

  /// No description provided for @ai_start_quiz_btn.
  ///
  /// In fr, this message translates to:
  /// **'Créer et Démarrer le Quiz'**
  String get ai_start_quiz_btn;

  /// No description provided for @ai_generating_quiz.
  ///
  /// In fr, this message translates to:
  /// **'Génération du quiz académique...'**
  String get ai_generating_quiz;

  /// No description provided for @ai_quiz_subtext.
  ///
  /// In fr, this message translates to:
  /// **'Progression synchronisée • Historique disponible dans votre profil'**
  String get ai_quiz_subtext;

  /// No description provided for @ai_question_counter.
  ///
  /// In fr, this message translates to:
  /// **'Question {current} / {total}'**
  String ai_question_counter(String current, String total);

  /// No description provided for @ai_next_question.
  ///
  /// In fr, this message translates to:
  /// **'Question suivante'**
  String get ai_next_question;

  /// No description provided for @ai_quit_test.
  ///
  /// In fr, this message translates to:
  /// **'Quitter l\'épreuve'**
  String get ai_quit_test;

  /// No description provided for @ai_explanation_prefix.
  ///
  /// In fr, this message translates to:
  /// **'Explication IA : '**
  String get ai_explanation_prefix;

  /// No description provided for @or.
  ///
  /// In fr, this message translates to:
  /// **'Ou'**
  String get or;

  /// No description provided for @open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get open;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @upcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get completed;

  /// No description provided for @level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'études'**
  String get level;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @drafts.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons'**
  String get drafts;

  /// No description provided for @splash_tagline.
  ///
  /// In fr, this message translates to:
  /// **'Écosystème Éducatif Augmenté par l\'IA'**
  String get splash_tagline;

  /// No description provided for @splash_loading_1.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation de l\'espace académique...'**
  String get splash_loading_1;

  /// No description provided for @splash_loading_2.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation du moteur IA...'**
  String get splash_loading_2;

  /// No description provided for @splash_loading_3.
  ///
  /// In fr, this message translates to:
  /// **'Prêt pour l\'excellence académique'**
  String get splash_loading_3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
