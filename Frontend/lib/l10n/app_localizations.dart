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

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

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

  /// No description provided for @splash_badge.
  ///
  /// In fr, this message translates to:
  /// **'SmartClass 4.0 • IA Pédagogique'**
  String get splash_badge;

  /// No description provided for @splash_footer.
  ///
  /// In fr, this message translates to:
  /// **'SmartClass Platform • v1.0 • Protocole TLS 1.3 • Conforme RGPD & CNIL'**
  String get splash_footer;

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
  /// **'Les nouveaux mots de passe ne correspondent pas.'**
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

  /// No description provided for @no_class_title.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe rejointe'**
  String get no_class_title;

  /// No description provided for @no_class_message.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'êtes inscrit à aucune classe. Contactez l\'administration de votre établissement pour rejoindre votre classe.'**
  String get no_class_message;

  /// No description provided for @no_assignments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun devoir pour le moment'**
  String get no_assignments;

  /// No description provided for @notifications_empty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour le moment'**
  String get notifications_empty;

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

  /// No description provided for @admin_greeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String admin_greeting(Object name);

  /// No description provided for @admin_supervision.
  ///
  /// In fr, this message translates to:
  /// **'Supervision Générale'**
  String get admin_supervision;

  /// No description provided for @admin_stat_students.
  ///
  /// In fr, this message translates to:
  /// **'Étudiants'**
  String get admin_stat_students;

  /// No description provided for @admin_stat_students_badge.
  ///
  /// In fr, this message translates to:
  /// **'+{count} ce mois'**
  String admin_stat_students_badge(Object count);

  /// No description provided for @admin_stat_teachers.
  ///
  /// In fr, this message translates to:
  /// **'Enseignants'**
  String get admin_stat_teachers;

  /// No description provided for @admin_stat_teachers_badge.
  ///
  /// In fr, this message translates to:
  /// **'{pct}% actifs'**
  String admin_stat_teachers_badge(Object pct);

  /// No description provided for @admin_stat_classes.
  ///
  /// In fr, this message translates to:
  /// **'Classes'**
  String get admin_stat_classes;

  /// No description provided for @admin_stat_classes_badge.
  ///
  /// In fr, this message translates to:
  /// **'{count} cursus'**
  String admin_stat_classes_badge(Object count);

  /// No description provided for @admin_stat_frauds.
  ///
  /// In fr, this message translates to:
  /// **'Alertes de Fraude'**
  String get admin_stat_frauds;

  /// No description provided for @admin_stat_frauds_badge.
  ///
  /// In fr, this message translates to:
  /// **'Action Requise'**
  String get admin_stat_frauds_badge;

  /// No description provided for @admin_shortcuts_title.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcis de Gestion'**
  String get admin_shortcuts_title;

  /// No description provided for @admin_shortcuts_sub.
  ///
  /// In fr, this message translates to:
  /// **'Accès direct aux modules clés d\'administration'**
  String get admin_shortcuts_sub;

  /// No description provided for @admin_nav_classes.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Classes'**
  String get admin_nav_classes;

  /// No description provided for @admin_nav_classes_desc.
  ///
  /// In fr, this message translates to:
  /// **'Créer, modifier & affecter'**
  String get admin_nav_classes_desc;

  /// No description provided for @admin_nav_teachers.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Enseignants & Profs'**
  String get admin_nav_teachers;

  /// No description provided for @admin_nav_teachers_desc.
  ///
  /// In fr, this message translates to:
  /// **'Rôles & plannings académiques'**
  String get admin_nav_teachers_desc;

  /// No description provided for @admin_nav_students.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Étudiants'**
  String get admin_nav_students;

  /// No description provided for @admin_nav_students_desc.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions, dossiers & cohortes'**
  String get admin_nav_students_desc;

  /// No description provided for @admin_nav_planning.
  ///
  /// In fr, this message translates to:
  /// **'Planning & Emplois du Temps'**
  String get admin_nav_planning;

  /// No description provided for @admin_nav_planning_desc.
  ///
  /// In fr, this message translates to:
  /// **'Salles & visioconférences'**
  String get admin_nav_planning_desc;

  /// No description provided for @admin_alerts_title.
  ///
  /// In fr, this message translates to:
  /// **'Alertes & Incidents'**
  String get admin_alerts_title;

  /// No description provided for @admin_view_all.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout ({count})'**
  String admin_view_all(Object count);

  /// No description provided for @admin_review_incident.
  ///
  /// In fr, this message translates to:
  /// **'Consulter l\'incident'**
  String get admin_review_incident;

  /// No description provided for @admin_ignore.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get admin_ignore;

  /// No description provided for @admin_to_verify.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get admin_to_verify;

  /// No description provided for @admin_validated.
  ///
  /// In fr, this message translates to:
  /// **'Planning validé'**
  String get admin_validated;

  /// No description provided for @admin_tab_dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau'**
  String get admin_tab_dashboard;

  /// No description provided for @admin_tab_classes.
  ///
  /// In fr, this message translates to:
  /// **'Classes'**
  String get admin_tab_classes;

  /// No description provided for @admin_tab_planning.
  ///
  /// In fr, this message translates to:
  /// **'Planning'**
  String get admin_tab_planning;

  /// No description provided for @admin_tab_frauds.
  ///
  /// In fr, this message translates to:
  /// **'Fraudes'**
  String get admin_tab_frauds;

  /// No description provided for @admin_classes_title.
  ///
  /// In fr, this message translates to:
  /// **'Gestion Des Classes'**
  String get admin_classes_title;

  /// No description provided for @admin_classes_sub.
  ///
  /// In fr, this message translates to:
  /// **'Supervisez les promotions, cohortes d\'étudiants et équipes pédagogiques en temps réel.'**
  String get admin_classes_sub;

  /// No description provided for @admin_search_class_hint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une classe, cursus, code'**
  String get admin_search_class_hint;

  /// No description provided for @admin_filter_licence.
  ///
  /// In fr, this message translates to:
  /// **'Licence'**
  String get admin_filter_licence;

  /// No description provided for @admin_filter_master.
  ///
  /// In fr, this message translates to:
  /// **'Master'**
  String get admin_filter_master;

  /// No description provided for @admin_filter_doctorat.
  ///
  /// In fr, this message translates to:
  /// **'Doctorat'**
  String get admin_filter_doctorat;

  /// No description provided for @admin_stat_cohorts.
  ///
  /// In fr, this message translates to:
  /// **'Cohortes'**
  String get admin_stat_cohorts;

  /// No description provided for @admin_active_promos.
  ///
  /// In fr, this message translates to:
  /// **'Promotions actives'**
  String get admin_active_promos;

  /// No description provided for @admin_sort_by.
  ///
  /// In fr, this message translates to:
  /// **'Trier par cursus'**
  String get admin_sort_by;

  /// No description provided for @admin_active_badge.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get admin_active_badge;

  /// No description provided for @admin_students_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} Étudiants'**
  String admin_students_count(Object count);

  /// No description provided for @admin_teachers_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} Enseignants'**
  String admin_teachers_count(Object count);

  /// No description provided for @admin_courses_active.
  ///
  /// In fr, this message translates to:
  /// **'{count} Cours actifs'**
  String admin_courses_active(Object count);

  /// No description provided for @admin_presence.
  ///
  /// In fr, this message translates to:
  /// **'Présence {pct}%'**
  String admin_presence(Object pct);

  /// No description provided for @admin_exam_ongoing.
  ///
  /// In fr, this message translates to:
  /// **'Examen en cours'**
  String get admin_exam_ongoing;

  /// No description provided for @admin_new_class.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Classe'**
  String get admin_new_class;

  /// No description provided for @admin_sync_ent.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation automatique avec le serveur ENT académique • Dernière mise à jour {ago}'**
  String admin_sync_ent(Object ago);

  /// No description provided for @admin_sync_ago.
  ///
  /// In fr, this message translates to:
  /// **'il y a 5 min'**
  String get admin_sync_ago;

  /// No description provided for @admin_edit_class_file.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la fiche classe'**
  String get admin_edit_class_file;

  /// No description provided for @admin_view_timetable.
  ///
  /// In fr, this message translates to:
  /// **'Consulter l\'emploi du temps'**
  String get admin_view_timetable;

  /// No description provided for @admin_send_notice.
  ///
  /// In fr, this message translates to:
  /// **'Diffuser un avis académique'**
  String get admin_send_notice;

  /// No description provided for @admin_archive_cohort.
  ///
  /// In fr, this message translates to:
  /// **'Archiver la cohorte'**
  String get admin_archive_cohort;

  /// No description provided for @admin_space_admin.
  ///
  /// In fr, this message translates to:
  /// **'Espace Administration'**
  String get admin_space_admin;

  /// No description provided for @admin_create_desc.
  ///
  /// In fr, this message translates to:
  /// **'Configurez une nouvelle cohorte d\'étudiants, définissez son rattachement académique et préparez l\'affectation pédagogique.'**
  String get admin_create_desc;

  /// No description provided for @admin_registry_synced.
  ///
  /// In fr, this message translates to:
  /// **'Registre académique synchronisé'**
  String get admin_registry_synced;

  /// No description provided for @admin_step_1_2.
  ///
  /// In fr, this message translates to:
  /// **'Étape 1/2'**
  String get admin_step_1_2;

  /// No description provided for @admin_class_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la classe'**
  String get admin_class_name;

  /// No description provided for @admin_required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get admin_required;

  /// No description provided for @admin_class_name_hint.
  ///
  /// In fr, this message translates to:
  /// **'ex : Ingénierie Logicielle 1A, Mathématiques…'**
  String get admin_class_name_hint;

  /// No description provided for @admin_class_name_note.
  ///
  /// In fr, this message translates to:
  /// **'Le nom sera visible par les étudiants sur leur planning et relevé.'**
  String get admin_class_name_note;

  /// No description provided for @admin_study_level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'études'**
  String get admin_study_level;

  /// No description provided for @admin_quick_pick.
  ///
  /// In fr, this message translates to:
  /// **'Présélections rapides'**
  String get admin_quick_pick;

  /// No description provided for @admin_department.
  ///
  /// In fr, this message translates to:
  /// **'Département / Filière'**
  String get admin_department;

  /// No description provided for @admin_capacity.
  ///
  /// In fr, this message translates to:
  /// **'Capacité d\'accueil'**
  String get admin_capacity;

  /// No description provided for @admin_capacity_hint.
  ///
  /// In fr, this message translates to:
  /// **'Jauge maximale recommandée'**
  String get admin_capacity_hint;

  /// No description provided for @admin_places.
  ///
  /// In fr, this message translates to:
  /// **'{count} places'**
  String admin_places(Object count);

  /// No description provided for @admin_students_max.
  ///
  /// In fr, this message translates to:
  /// **'Étudiants max'**
  String get admin_students_max;

  /// No description provided for @admin_description_label.
  ///
  /// In fr, this message translates to:
  /// **'Description & Spécificités'**
  String get admin_description_label;

  /// No description provided for @admin_optional.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get admin_optional;

  /// No description provided for @admin_description_hint.
  ///
  /// In fr, this message translates to:
  /// **'Précisez les objectifs pédagogiques, prérequis ou spécificités de cette promotion (ex: cursus en alternance, parcours international)…'**
  String get admin_description_hint;

  /// No description provided for @admin_char_count.
  ///
  /// In fr, this message translates to:
  /// **'{used} / {max} caractères'**
  String admin_char_count(Object max, Object used);

  /// No description provided for @admin_auto_params.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres automatisés'**
  String get admin_auto_params;

  /// No description provided for @admin_forum_title.
  ///
  /// In fr, this message translates to:
  /// **'Espace Forum & Débat'**
  String get admin_forum_title;

  /// No description provided for @admin_forum_desc.
  ///
  /// In fr, this message translates to:
  /// **'Canal collaboratif modéré par les enseignants'**
  String get admin_forum_desc;

  /// No description provided for @admin_ent_sync_title.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation ENT'**
  String get admin_ent_sync_title;

  /// No description provided for @admin_ent_sync_desc.
  ///
  /// In fr, this message translates to:
  /// **'Liaison automatique avec l\'annuaire Apogée / LDAP'**
  String get admin_ent_sync_desc;

  /// No description provided for @admin_access_note.
  ///
  /// In fr, this message translates to:
  /// **'Les accès étudiants et invitations seront générés à la validation.'**
  String get admin_access_note;

  /// No description provided for @admin_create_group.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe'**
  String get admin_create_group;

  /// No description provided for @admin_save_draft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer comme brouillon'**
  String get admin_save_draft;

  /// No description provided for @admin_add_students.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter Des Étudiants'**
  String get admin_add_students;

  /// No description provided for @admin_class_label.
  ///
  /// In fr, this message translates to:
  /// **'Classe : {name}'**
  String admin_class_label(Object name);

  /// No description provided for @admin_import_csv.
  ///
  /// In fr, this message translates to:
  /// **'Importer via CSV'**
  String get admin_import_csv;

  /// No description provided for @admin_direct_assign.
  ///
  /// In fr, this message translates to:
  /// **'Affectation directe'**
  String get admin_direct_assign;

  /// No description provided for @admin_places_left.
  ///
  /// In fr, this message translates to:
  /// **'{count} places restantes'**
  String admin_places_left(Object count);

  /// No description provided for @admin_enrolled.
  ///
  /// In fr, this message translates to:
  /// **'{enrolled}/{capacity} inscrits'**
  String admin_enrolled(Object capacity, Object enrolled);

  /// No description provided for @admin_search_person_hint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom ou email…'**
  String get admin_search_person_hint;

  /// No description provided for @admin_all_count.
  ///
  /// In fr, this message translates to:
  /// **'Tous ({count})'**
  String admin_all_count(Object count);

  /// No description provided for @admin_unassigned.
  ///
  /// In fr, this message translates to:
  /// **'Non affectés ({count})'**
  String admin_unassigned(Object count);

  /// No description provided for @admin_avg_filter.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne > 14'**
  String get admin_avg_filter;

  /// No description provided for @admin_select_all.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get admin_select_all;

  /// No description provided for @admin_selected_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} étudiants sélectionnés'**
  String admin_selected_count(Object count);

  /// No description provided for @admin_selected_footer.
  ///
  /// In fr, this message translates to:
  /// **'{count} sélectionnés'**
  String admin_selected_footer(Object count);

  /// No description provided for @admin_assign_now.
  ///
  /// In fr, this message translates to:
  /// **'Affectation immédiate sur l\'ENT'**
  String get admin_assign_now;

  /// No description provided for @admin_instant_sync.
  ///
  /// In fr, this message translates to:
  /// **'Synchro instantanée'**
  String get admin_instant_sync;

  /// No description provided for @admin_assign_to_class.
  ///
  /// In fr, this message translates to:
  /// **'Affecter à la classe'**
  String get admin_assign_to_class;

  /// No description provided for @admin_cancel_op.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'opération'**
  String get admin_cancel_op;

  /// No description provided for @admin_assign_teachers.
  ///
  /// In fr, this message translates to:
  /// **'Affecter Des Enseignants'**
  String get admin_assign_teachers;

  /// No description provided for @admin_academic_year.
  ///
  /// In fr, this message translates to:
  /// **'Année académique 2024-2025'**
  String get admin_academic_year;

  /// No description provided for @admin_semester_dept.
  ///
  /// In fr, this message translates to:
  /// **'Semestre {sem} • Département {dept}'**
  String admin_semester_dept(Object dept, Object sem);

  /// No description provided for @admin_course_coverage.
  ///
  /// In fr, this message translates to:
  /// **'Couverture des cours'**
  String get admin_course_coverage;

  /// No description provided for @admin_assigned_ratio.
  ///
  /// In fr, this message translates to:
  /// **'{done} sur {total} affectées ({pct}%)'**
  String admin_assigned_ratio(Object done, Object pct, Object total);

  /// No description provided for @admin_subjects_required.
  ///
  /// In fr, this message translates to:
  /// **'{count} matières requises'**
  String admin_subjects_required(Object count);

  /// No description provided for @admin_open_posts.
  ///
  /// In fr, this message translates to:
  /// **'{count} postes vacants'**
  String admin_open_posts(Object count);

  /// No description provided for @admin_search_teacher_hint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un professeur, département…'**
  String get admin_search_teacher_hint;

  /// No description provided for @admin_available_teachers.
  ///
  /// In fr, this message translates to:
  /// **'Corps professoral disponible'**
  String get admin_available_teachers;

  /// No description provided for @admin_sort_affinity.
  ///
  /// In fr, this message translates to:
  /// **'Trié par affinité pédagogique'**
  String get admin_sort_affinity;

  /// No description provided for @admin_add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get admin_add;

  /// No description provided for @admin_assigned_hours.
  ///
  /// In fr, this message translates to:
  /// **'Affecté • {hours}'**
  String admin_assigned_hours(Object hours);

  /// No description provided for @admin_avail_hours.
  ///
  /// In fr, this message translates to:
  /// **'{hours} dispo / semaine'**
  String admin_avail_hours(Object hours);

  /// No description provided for @admin_subject_assigned.
  ///
  /// In fr, this message translates to:
  /// **'Matière assignée'**
  String get admin_subject_assigned;

  /// No description provided for @admin_not_assigned.
  ///
  /// In fr, this message translates to:
  /// **'Non assigné'**
  String get admin_not_assigned;

  /// No description provided for @admin_pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get admin_pending;

  /// No description provided for @admin_full_load.
  ///
  /// In fr, this message translates to:
  /// **'Charge complète (dérogation)'**
  String get admin_full_load;

  /// No description provided for @admin_dean_reserve.
  ///
  /// In fr, this message translates to:
  /// **'Sous réserve décanat'**
  String get admin_dean_reserve;

  /// No description provided for @admin_teachers_selected.
  ///
  /// In fr, this message translates to:
  /// **'{count} enseignant sélectionné'**
  String admin_teachers_selected(Object count);

  /// No description provided for @admin_dep_info.
  ///
  /// In fr, this message translates to:
  /// **'Dép. Info ({count})'**
  String admin_dep_info(Object count);

  /// No description provided for @admin_available_f.
  ///
  /// In fr, this message translates to:
  /// **'Disponibles ({count})'**
  String admin_available_f(Object count);

  /// No description provided for @admin_assigned_f.
  ///
  /// In fr, this message translates to:
  /// **'Déjà affectés ({count})'**
  String admin_assigned_f(Object count);

  /// No description provided for @admin_confirm_assign.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'affectation'**
  String get admin_confirm_assign;

  /// No description provided for @admin_cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get admin_cancel;

  /// No description provided for @admin_ent_sync_now.
  ///
  /// In fr, this message translates to:
  /// **'Synchro ENT immédiate'**
  String get admin_ent_sync_now;

  /// No description provided for @admin_timetable.
  ///
  /// In fr, this message translates to:
  /// **'Emplois Du Temps'**
  String get admin_timetable;

  /// No description provided for @admin_active_promo.
  ///
  /// In fr, this message translates to:
  /// **'Promotion Active'**
  String get admin_active_promo;

  /// No description provided for @admin_semester.
  ///
  /// In fr, this message translates to:
  /// **'Semestre {n}'**
  String admin_semester(Object n);

  /// No description provided for @admin_today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get admin_today;

  /// No description provided for @admin_hours_scheduled.
  ///
  /// In fr, this message translates to:
  /// **'{hours} programmées'**
  String admin_hours_scheduled(Object hours);

  /// No description provided for @admin_no_conflict.
  ///
  /// In fr, this message translates to:
  /// **'{count} conflit'**
  String admin_no_conflict(Object count);

  /// No description provided for @admin_rate.
  ///
  /// In fr, this message translates to:
  /// **'{pct} taux'**
  String admin_rate(Object pct);

  /// No description provided for @admin_day_planning.
  ///
  /// In fr, this message translates to:
  /// **'Planning de la journée'**
  String get admin_day_planning;

  /// No description provided for @admin_day_courses.
  ///
  /// In fr, this message translates to:
  /// **'{count} cours'**
  String admin_day_courses(Object count);

  /// No description provided for @admin_makeup.
  ///
  /// In fr, this message translates to:
  /// **'Rattr.'**
  String get admin_makeup;

  /// No description provided for @admin_free_slot.
  ///
  /// In fr, this message translates to:
  /// **'Créneau libre'**
  String get admin_free_slot;

  /// No description provided for @admin_free_desc.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cours programmé. Disponible pour une session de rattrapage, tutorat ou soutenance de projet.'**
  String get admin_free_desc;

  /// No description provided for @admin_new_slot.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau créneau'**
  String get admin_new_slot;

  /// No description provided for @admin_take_attendance.
  ///
  /// In fr, this message translates to:
  /// **'Faire l\'appel'**
  String get admin_take_attendance;

  /// No description provided for @admin_book.
  ///
  /// In fr, this message translates to:
  /// **'Réserver'**
  String get admin_book;

  /// No description provided for @admin_room_available.
  ///
  /// In fr, this message translates to:
  /// **'Salle {room} disponible'**
  String admin_room_available(Object room);

  /// No description provided for @admin_event_cm.
  ///
  /// In fr, this message translates to:
  /// **'CM • Cours Magistral'**
  String get admin_event_cm;

  /// No description provided for @admin_event_tp.
  ///
  /// In fr, this message translates to:
  /// **'TP • Travaux Pratiques'**
  String get admin_event_tp;

  /// No description provided for @admin_event_td.
  ///
  /// In fr, this message translates to:
  /// **'TD • Travaux Dirigés'**
  String get admin_event_td;

  /// No description provided for @admin_break_short.
  ///
  /// In fr, this message translates to:
  /// **'Pause récréative'**
  String get admin_break_short;

  /// No description provided for @admin_break_lunch.
  ///
  /// In fr, this message translates to:
  /// **'Pause Déjeuner & Permanence'**
  String get admin_break_lunch;

  /// No description provided for @admin_confirmed_open.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé • Appel non clôturé'**
  String get admin_confirmed_open;

  /// No description provided for @admin_session_validated.
  ///
  /// In fr, this message translates to:
  /// **'Séance validée & matériel réservé'**
  String get admin_session_validated;

  /// No description provided for @admin_group_full.
  ///
  /// In fr, this message translates to:
  /// **'Groupe complet'**
  String get admin_group_full;

  /// No description provided for @admin_hybrid_on.
  ///
  /// In fr, this message translates to:
  /// **'Mode hybride actif • Lien Zoom synchrone transmis'**
  String get admin_hybrid_on;

  /// No description provided for @admin_room_label.
  ///
  /// In fr, this message translates to:
  /// **'Salle {room}'**
  String admin_room_label(Object room);

  /// No description provided for @admin_fraud_title.
  ///
  /// In fr, this message translates to:
  /// **'Rapports De Fraude'**
  String get admin_fraud_title;

  /// No description provided for @admin_fraud_sub.
  ///
  /// In fr, this message translates to:
  /// **'Discipline & Surveillance Examens'**
  String get admin_fraud_sub;

  /// No description provided for @admin_antifraud_on.
  ///
  /// In fr, this message translates to:
  /// **'Système Anti-Fraude Actif'**
  String get admin_antifraud_on;

  /// No description provided for @admin_ai_watch.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance IA'**
  String get admin_ai_watch;

  /// No description provided for @admin_unresolved.
  ///
  /// In fr, this message translates to:
  /// **'Non traités'**
  String get admin_unresolved;

  /// No description provided for @admin_resolved_month.
  ///
  /// In fr, this message translates to:
  /// **'Résolus ce mois'**
  String get admin_resolved_month;

  /// No description provided for @admin_integrity.
  ///
  /// In fr, this message translates to:
  /// **'Intégrité'**
  String get admin_integrity;

  /// No description provided for @admin_unresolved_f.
  ///
  /// In fr, this message translates to:
  /// **'Non traités ({count})'**
  String admin_unresolved_f(Object count);

  /// No description provided for @admin_ongoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours ({count})'**
  String admin_ongoing(Object count);

  /// No description provided for @admin_resolved_f.
  ///
  /// In fr, this message translates to:
  /// **'Résolus ({count})'**
  String admin_resolved_f(Object count);

  /// No description provided for @admin_critical.
  ///
  /// In fr, this message translates to:
  /// **'Critique'**
  String get admin_critical;

  /// No description provided for @admin_medium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get admin_medium;

  /// No description provided for @admin_closed.
  ///
  /// In fr, this message translates to:
  /// **'Classé sans suite'**
  String get admin_closed;

  /// No description provided for @admin_status_untreated.
  ///
  /// In fr, this message translates to:
  /// **'Non traité'**
  String get admin_status_untreated;

  /// No description provided for @admin_status_ongoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get admin_status_ongoing;

  /// No description provided for @admin_view_video.
  ///
  /// In fr, this message translates to:
  /// **'Voir vidéo/log'**
  String get admin_view_video;

  /// No description provided for @admin_sanction.
  ///
  /// In fr, this message translates to:
  /// **'Sanctionner'**
  String get admin_sanction;

  /// No description provided for @admin_network_logs.
  ///
  /// In fr, this message translates to:
  /// **'Logs réseau'**
  String get admin_network_logs;

  /// No description provided for @admin_summon.
  ///
  /// In fr, this message translates to:
  /// **'Convoquer'**
  String get admin_summon;

  /// No description provided for @admin_audit_history.
  ///
  /// In fr, this message translates to:
  /// **'Historique d\'audit'**
  String get admin_audit_history;

  /// No description provided for @admin_export_audit.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le journal d\'audit (PDF/CSV)'**
  String get admin_export_audit;

  /// No description provided for @admin_compliance.
  ///
  /// In fr, this message translates to:
  /// **'Conforme à la charte d\'intégrité académique & règlements CNIL / RGPD'**
  String get admin_compliance;

  /// No description provided for @admin_reason.
  ///
  /// In fr, this message translates to:
  /// **'Motif :'**
  String get admin_reason;

  /// No description provided for @admin_resolution.
  ///
  /// In fr, this message translates to:
  /// **'Résolution :'**
  String get admin_resolution;

  /// No description provided for @collapse_sidebar.
  ///
  /// In fr, this message translates to:
  /// **'Réduire le menu'**
  String get collapse_sidebar;

  /// No description provided for @expand_sidebar.
  ///
  /// In fr, this message translates to:
  /// **'Agrandir le menu'**
  String get expand_sidebar;

  /// No description provided for @student_portal.
  ///
  /// In fr, this message translates to:
  /// **'Portail Étudiant'**
  String get student_portal;

  /// No description provided for @teacher_portal.
  ///
  /// In fr, this message translates to:
  /// **'Espace Enseignant'**
  String get teacher_portal;

  /// No description provided for @nav_dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get nav_dashboard;

  /// No description provided for @nav_ai_studio.
  ///
  /// In fr, this message translates to:
  /// **'Studio IA & Tuteur'**
  String get nav_ai_studio;

  /// No description provided for @nav_community.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get nav_community;

  /// No description provided for @nav_exams_assignments.
  ///
  /// In fr, this message translates to:
  /// **'Examens & Devoirs'**
  String get nav_exams_assignments;

  /// No description provided for @nav_videoconference.
  ///
  /// In fr, this message translates to:
  /// **'Visioconférence'**
  String get nav_videoconference;

  /// No description provided for @nav_my_profile.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres & Profil'**
  String get nav_my_profile;

  /// No description provided for @nav_my_classes.
  ///
  /// In fr, this message translates to:
  /// **'Mes Classes'**
  String get nav_my_classes;

  /// No description provided for @nav_courses_resources.
  ///
  /// In fr, this message translates to:
  /// **'Cours & Ressources'**
  String get nav_courses_resources;

  /// No description provided for @nav_ai_creator.
  ///
  /// In fr, this message translates to:
  /// **'Créateur IA'**
  String get nav_ai_creator;

  /// No description provided for @nav_live_meetings.
  ///
  /// In fr, this message translates to:
  /// **'Directs & Réunions'**
  String get nav_live_meetings;

  /// No description provided for @nav_exams_grades.
  ///
  /// In fr, this message translates to:
  /// **'Examens & Notes'**
  String get nav_exams_grades;

  /// No description provided for @institution_tag.
  ///
  /// In fr, this message translates to:
  /// **'Lycée Descartes • Casablanca'**
  String get institution_tag;

  /// No description provided for @account_settings_title.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du compte'**
  String get account_settings_title;

  /// No description provided for @active_student_badge.
  ///
  /// In fr, this message translates to:
  /// **'Étudiant Actif'**
  String get active_student_badge;

  /// No description provided for @account_settings_desc.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre identité académique, vos accès de sécurité et configurez vos flux de notifications pour votre portail étudiant.'**
  String get account_settings_desc;

  /// No description provided for @ent_sync_status.
  ///
  /// In fr, this message translates to:
  /// **'Statut Académique : Synchronisé ENT'**
  String get ent_sync_status;

  /// No description provided for @config_menu_title.
  ///
  /// In fr, this message translates to:
  /// **'MENU DE CONFIGURATION'**
  String get config_menu_title;

  /// No description provided for @menu_personal_info.
  ///
  /// In fr, this message translates to:
  /// **'Profil personnel'**
  String get menu_personal_info;

  /// No description provided for @menu_security_auth.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité & Authentification'**
  String get menu_security_auth;

  /// No description provided for @menu_notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications & Alertes'**
  String get menu_notifications;

  /// No description provided for @menu_appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence & Thème'**
  String get menu_appearance;

  /// No description provided for @menu_privacy_gdpr.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité & RGPD'**
  String get menu_privacy_gdpr;

  /// No description provided for @menu_sessions_devices.
  ///
  /// In fr, this message translates to:
  /// **'Sessions & Appareils'**
  String get menu_sessions_devices;

  /// No description provided for @cloud_storage_title.
  ///
  /// In fr, this message translates to:
  /// **'Stockage Devoirs Cloud'**
  String get cloud_storage_title;

  /// No description provided for @ent_cloud_synced.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé avec ENT Cloud'**
  String get ent_cloud_synced;

  /// No description provided for @official_id.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant officiel'**
  String get official_id;

  /// No description provided for @certified_academic_data.
  ///
  /// In fr, this message translates to:
  /// **'Données académiques certifiées par le secrétariat pédagogique.'**
  String get certified_academic_data;

  /// No description provided for @student_photo_title.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil étudiante'**
  String get student_photo_title;

  /// No description provided for @validated_badge.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get validated_badge;

  /// No description provided for @student_photo_desc.
  ///
  /// In fr, this message translates to:
  /// **'Format PNG ou JPG, max 5 Mo. Cette photo figure sur votre carte étudiante dématérialisée et vos attestations officielles.'**
  String get student_photo_desc;

  /// No description provided for @change_image.
  ///
  /// In fr, this message translates to:
  /// **'Changer l\'image'**
  String get change_image;

  /// No description provided for @delete_image.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete_image;

  /// No description provided for @academic_email_label.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email universitaire'**
  String get academic_email_label;

  /// No description provided for @verified_label.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get verified_label;

  /// No description provided for @student_number_label.
  ///
  /// In fr, this message translates to:
  /// **'Numéro d\'étudiant (CNE / MASSAR)'**
  String get student_number_label;

  /// No description provided for @university_label.
  ///
  /// In fr, this message translates to:
  /// **'Université / Établissement'**
  String get university_label;

  /// No description provided for @major_promotion_label.
  ///
  /// In fr, this message translates to:
  /// **'Promotion / Filière d\'excellence'**
  String get major_promotion_label;

  /// No description provided for @security_auth_desc.
  ///
  /// In fr, this message translates to:
  /// **'Paramétrez la protection de votre session et vos clés d\'accès.'**
  String get security_auth_desc;

  /// No description provided for @main_password_label.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe principal'**
  String get main_password_label;

  /// No description provided for @password_last_modified.
  ///
  /// In fr, this message translates to:
  /// **'Modifié il y a 3 mois'**
  String get password_last_modified;

  /// No description provided for @change_password_btn.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get change_password_btn;

  /// No description provided for @new_password_label.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get new_password_label;

  /// No description provided for @confirm_password_label.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get confirm_password_label;

  /// No description provided for @password_updated.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour avec succès !'**
  String get password_updated;

  /// No description provided for @two_factor_auth_label.
  ///
  /// In fr, this message translates to:
  /// **'Authentification à deux facteurs (2FA)'**
  String get two_factor_auth_label;

  /// No description provided for @active_badge.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active_badge;

  /// No description provided for @inactive_badge.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get inactive_badge;

  /// No description provided for @two_factor_desc.
  ///
  /// In fr, this message translates to:
  /// **'Application d\'authentification (Google Authenticator / iCloud Keychain) connectée.'**
  String get two_factor_desc;

  /// No description provided for @two_factor_modal_title.
  ///
  /// In fr, this message translates to:
  /// **'Configuration Authentificateur TOTP'**
  String get two_factor_modal_title;

  /// No description provided for @two_factor_modal_desc.
  ///
  /// In fr, this message translates to:
  /// **'Scannez ce QR Code avec Google Authenticator ou Microsoft Authenticator pour sécuriser votre compte étudiant.'**
  String get two_factor_modal_desc;

  /// No description provided for @two_factor_code_label.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification à 6 chiffres'**
  String get two_factor_code_label;

  /// No description provided for @two_factor_verify_btn.
  ///
  /// In fr, this message translates to:
  /// **'Valider et activer 2FA'**
  String get two_factor_verify_btn;

  /// No description provided for @passkeys_label.
  ///
  /// In fr, this message translates to:
  /// **'Clés de sécurité physiques & Passkeys'**
  String get passkeys_label;

  /// No description provided for @passkeys_desc.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous instantanément via Touch ID, Windows Hello ou clé FIDO2 / YubiKey.'**
  String get passkeys_desc;

  /// No description provided for @add_passkey_btn.
  ///
  /// In fr, this message translates to:
  /// **'+ Ajouter une passkey'**
  String get add_passkey_btn;

  /// No description provided for @security_audit_log_title.
  ///
  /// In fr, this message translates to:
  /// **'Journal d\'activité de sécurité récente'**
  String get security_audit_log_title;

  /// No description provided for @security_log_login_success.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie - Microsoft Edge (Windows 11)'**
  String get security_log_login_success;

  /// No description provided for @security_log_location.
  ///
  /// In fr, this message translates to:
  /// **'Rabat, Maroc • Adresse IP : 196.200.185.42'**
  String get security_log_location;

  /// No description provided for @security_log_time_now.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui à 10:14'**
  String get security_log_time_now;

  /// No description provided for @security_log_2fa_success.
  ///
  /// In fr, this message translates to:
  /// **'Validation 2FA TOTP réussie'**
  String get security_log_2fa_success;

  /// No description provided for @security_log_2fa_time.
  ///
  /// In fr, this message translates to:
  /// **'Hier à 16:45'**
  String get security_log_2fa_time;

  /// No description provided for @notifications_settings_desc.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisez la fréquence et les canaux de vos alertes académiques.'**
  String get notifications_settings_desc;

  /// No description provided for @notif_push_title.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push du navigateur'**
  String get notif_push_title;

  /// No description provided for @notif_push_desc.
  ///
  /// In fr, this message translates to:
  /// **'Rappels en direct des cours magistraux, modifications de salle et dates limites d\'examens.'**
  String get notif_push_desc;

  /// No description provided for @notif_email_title.
  ///
  /// In fr, this message translates to:
  /// **'Notifications par email universitaire'**
  String get notif_email_title;

  /// No description provided for @notif_email_desc.
  ///
  /// In fr, this message translates to:
  /// **'Synthèses hebdomadaires générées par l\'IA et alertes dès publication des résultats d\'épreuves.'**
  String get notif_email_desc;

  /// No description provided for @notif_sms_title.
  ///
  /// In fr, this message translates to:
  /// **'Alertes SMS d\'urgence académique'**
  String get notif_sms_title;

  /// No description provided for @notif_sms_desc.
  ///
  /// In fr, this message translates to:
  /// **'Transmises uniquement en cas de suspension de cours ou fermeture météorologique exceptionnelle.'**
  String get notif_sms_desc;

  /// No description provided for @notif_ai_mentor_title.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations de révision IA personnalisées'**
  String get notif_ai_mentor_title;

  /// No description provided for @notif_ai_mentor_desc.
  ///
  /// In fr, this message translates to:
  /// **'Algorithme d\'espacement de répétition basé sur vos résultats récents en algorithmique et IA.'**
  String get notif_ai_mentor_desc;

  /// No description provided for @notif_deadlines_title.
  ///
  /// In fr, this message translates to:
  /// **'Rappels des échéances de devoirs & examens'**
  String get notif_deadlines_title;

  /// No description provided for @notif_deadlines_desc.
  ///
  /// In fr, this message translates to:
  /// **'Alertes programmées 24 heures et 2 heures avant chaque remise obligatoire.'**
  String get notif_deadlines_desc;

  /// No description provided for @notif_quiet_hours_title.
  ///
  /// In fr, this message translates to:
  /// **'Heures de silence (Ne pas déranger)'**
  String get notif_quiet_hours_title;

  /// No description provided for @notif_quiet_hours_desc.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre toutes les alertes non urgentes entre 22h00 et 07h00.'**
  String get notif_quiet_hours_desc;

  /// No description provided for @appearance_desc.
  ///
  /// In fr, this message translates to:
  /// **'Ajustez l\'ambiance lumineuse et l\'ergonomie visuelle pour vos sessions d\'étude.'**
  String get appearance_desc;

  /// No description provided for @theme_light_title.
  ///
  /// In fr, this message translates to:
  /// **'Clair (Défaut)'**
  String get theme_light_title;

  /// No description provided for @theme_light_desc.
  ///
  /// In fr, this message translates to:
  /// **'Luminosité standard'**
  String get theme_light_desc;

  /// No description provided for @theme_dark_title.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get theme_dark_title;

  /// No description provided for @theme_dark_desc.
  ///
  /// In fr, this message translates to:
  /// **'Idéal pour le travail nocturne'**
  String get theme_dark_desc;

  /// No description provided for @theme_system_title.
  ///
  /// In fr, this message translates to:
  /// **'Système (Auto)'**
  String get theme_system_title;

  /// No description provided for @theme_system_desc.
  ///
  /// In fr, this message translates to:
  /// **'Selon l\'OS de l\'appareil'**
  String get theme_system_desc;

  /// No description provided for @language_title.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'interface'**
  String get language_title;

  /// No description provided for @language_desc.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la langue de travail pour votre espace d\'apprentissage.'**
  String get language_desc;

  /// No description provided for @lang_french.
  ///
  /// In fr, this message translates to:
  /// **'Français (FR)'**
  String get lang_french;

  /// No description provided for @lang_english.
  ///
  /// In fr, this message translates to:
  /// **'English (US)'**
  String get lang_english;

  /// No description provided for @font_comfort_title.
  ///
  /// In fr, this message translates to:
  /// **'Taille de police & Confort visuel'**
  String get font_comfort_title;

  /// No description provided for @font_comfort_desc.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster pour les lectures prolongées d\'articles scientifiques.'**
  String get font_comfort_desc;

  /// No description provided for @font_compact.
  ///
  /// In fr, this message translates to:
  /// **'Compact (-10%)'**
  String get font_compact;

  /// No description provided for @font_standard.
  ///
  /// In fr, this message translates to:
  /// **'Standard (100%)'**
  String get font_standard;

  /// No description provided for @font_large.
  ///
  /// In fr, this message translates to:
  /// **'Confort (+15%)'**
  String get font_large;

  /// No description provided for @high_contrast_title.
  ///
  /// In fr, this message translates to:
  /// **'Mode Contraste Élevé'**
  String get high_contrast_title;

  /// No description provided for @high_contrast_desc.
  ///
  /// In fr, this message translates to:
  /// **'Renforce les bordures et les contrastes pour une meilleure lisibilité.'**
  String get high_contrast_desc;

  /// No description provided for @reduce_animations_title.
  ///
  /// In fr, this message translates to:
  /// **'Réduire les animations'**
  String get reduce_animations_title;

  /// No description provided for @reduce_animations_desc.
  ///
  /// In fr, this message translates to:
  /// **'Diminue les effets de mouvement et transitions dynamiques.'**
  String get reduce_animations_desc;

  /// No description provided for @privacy_gdpr_title.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité & Protection des données (RGPD)'**
  String get privacy_gdpr_title;

  /// No description provided for @privacy_gdpr_desc.
  ///
  /// In fr, this message translates to:
  /// **'Contrôlez vos données personnelles et vos préférences de partage académique selon la loi marocaine 09-08 et le RGPD.'**
  String get privacy_gdpr_desc;

  /// No description provided for @gdpr_badge.
  ///
  /// In fr, this message translates to:
  /// **'Conforme RGPD • Hébergement Souverain'**
  String get gdpr_badge;

  /// No description provided for @data_export_title.
  ///
  /// In fr, this message translates to:
  /// **'Exportation de vos données académiques'**
  String get data_export_title;

  /// No description provided for @data_export_desc.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargez une copie intégrale de vos informations personnelles, notes, devoirs et historique d\'activités.'**
  String get data_export_desc;

  /// No description provided for @download_json_btn.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger l\'archive JSON'**
  String get download_json_btn;

  /// No description provided for @download_pdf_btn.
  ///
  /// In fr, this message translates to:
  /// **'Relevé officiel PDF'**
  String get download_pdf_btn;

  /// No description provided for @privacy_visibility_title.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité et partage dans la classe'**
  String get privacy_visibility_title;

  /// No description provided for @privacy_visibility_profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil visible par les camarades de promotion'**
  String get privacy_visibility_profile;

  /// No description provided for @privacy_visibility_profile_desc.
  ///
  /// In fr, this message translates to:
  /// **'Permet aux étudiants de votre groupe de voir votre prénom et photo dans les projets d\'équipe.'**
  String get privacy_visibility_profile_desc;

  /// No description provided for @privacy_visibility_ranking.
  ///
  /// In fr, this message translates to:
  /// **'Afficher mon rang et classement dans les cours'**
  String get privacy_visibility_ranking;

  /// No description provided for @privacy_visibility_ranking_desc.
  ///
  /// In fr, this message translates to:
  /// **'Participer aux classements anonymisés d\'exercices et défis de code.'**
  String get privacy_visibility_ranking_desc;

  /// No description provided for @privacy_share_notes.
  ///
  /// In fr, this message translates to:
  /// **'Partager mes synthèses de cours générées par IA'**
  String get privacy_share_notes;

  /// No description provided for @privacy_share_notes_desc.
  ///
  /// In fr, this message translates to:
  /// **'Permet de mutualiser vos notes de révision avec votre groupe de TD.'**
  String get privacy_share_notes_desc;

  /// No description provided for @danger_zone_title.
  ///
  /// In fr, this message translates to:
  /// **'Zone de gestion critique du compte'**
  String get danger_zone_title;

  /// No description provided for @danger_freeze_account.
  ///
  /// In fr, this message translates to:
  /// **'Geler temporairement mon compte'**
  String get danger_freeze_account;

  /// No description provided for @danger_freeze_desc.
  ///
  /// In fr, this message translates to:
  /// **'Désactive temporairement votre accès sans supprimer vos devoirs ni vos notes.'**
  String get danger_freeze_desc;

  /// No description provided for @danger_delete_account.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement mon compte'**
  String get danger_delete_account;

  /// No description provided for @danger_delete_desc.
  ///
  /// In fr, this message translates to:
  /// **'Supprime irréversiblement toutes vos données de la plateforme SmartClass (Droit à l\'oubli).'**
  String get danger_delete_desc;

  /// No description provided for @freeze_confirm_title.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la mise en veille'**
  String get freeze_confirm_title;

  /// No description provided for @freeze_confirm_desc.
  ///
  /// In fr, this message translates to:
  /// **'Votre session sera immédiatement déconnectée. Vous pourrez réactiver votre compte en vous reconnectant.'**
  String get freeze_confirm_desc;

  /// No description provided for @delete_confirm_title.
  ///
  /// In fr, this message translates to:
  /// **'Suppression définitive du compte'**
  String get delete_confirm_title;

  /// No description provided for @delete_confirm_desc.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Toutes vos fiches de cours, résultats de quiz et échanges de projet seront effacés.'**
  String get delete_confirm_desc;

  /// No description provided for @sessions_devices_title.
  ///
  /// In fr, this message translates to:
  /// **'Sessions & Appareils connectés'**
  String get sessions_devices_title;

  /// No description provided for @sessions_devices_desc.
  ///
  /// In fr, this message translates to:
  /// **'Consultez et révoquez les appareils actuellement connectés à votre compte étudiant.'**
  String get sessions_devices_desc;

  /// No description provided for @active_sessions_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} sessions actives'**
  String active_sessions_count(Object count);

  /// No description provided for @current_session_badge.
  ///
  /// In fr, this message translates to:
  /// **'Session active (Cet appareil)'**
  String get current_session_badge;

  /// No description provided for @current_session_desc.
  ///
  /// In fr, this message translates to:
  /// **'Microsoft Edge sur Windows 11 • Rabat, Maroc'**
  String get current_session_desc;

  /// No description provided for @last_active_now.
  ///
  /// In fr, this message translates to:
  /// **'En ligne actuellement'**
  String get last_active_now;

  /// No description provided for @device_mobile_name.
  ///
  /// In fr, this message translates to:
  /// **'SmartClass Mobile (Samsung Galaxy S23)'**
  String get device_mobile_name;

  /// No description provided for @device_mobile_details.
  ///
  /// In fr, this message translates to:
  /// **'Application Android 14 • Rabat, Maroc'**
  String get device_mobile_details;

  /// No description provided for @device_mobile_time.
  ///
  /// In fr, this message translates to:
  /// **'Actif il y a 2 heures'**
  String get device_mobile_time;

  /// No description provided for @device_safari_name.
  ///
  /// In fr, this message translates to:
  /// **'Safari sur macOS Sequoia'**
  String get device_safari_name;

  /// No description provided for @device_safari_details.
  ///
  /// In fr, this message translates to:
  /// **'Navigateur Web • MacBook Pro • Casablanca, Maroc'**
  String get device_safari_details;

  /// No description provided for @device_safari_time.
  ///
  /// In fr, this message translates to:
  /// **'Actif il y a 3 jours'**
  String get device_safari_time;

  /// No description provided for @revoke_session_btn.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get revoke_session_btn;

  /// No description provided for @revoke_all_sessions_btn.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter toutes les autres sessions'**
  String get revoke_all_sessions_btn;

  /// No description provided for @revoke_all_confirm_title.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter tous les autres appareils ?'**
  String get revoke_all_confirm_title;

  /// No description provided for @revoke_all_confirm_desc.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les sessions distantes sur vos téléphones, tablettes ou ordinateurs seront immédiatement closes.'**
  String get revoke_all_confirm_desc;

  /// No description provided for @all_sessions_revoked.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les autres sessions ont été révoquées avec succès !'**
  String get all_sessions_revoked;

  /// No description provided for @last_ent_sync.
  ///
  /// In fr, this message translates to:
  /// **'Dernière synchronisation ENT : Aujourd\'hui à 14:32'**
  String get last_ent_sync;

  /// No description provided for @discard_changes.
  ///
  /// In fr, this message translates to:
  /// **'Annuler les modifications'**
  String get discard_changes;

  /// No description provided for @save_changes.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get save_changes;

  /// No description provided for @changes_saved_success.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées avec succès !'**
  String get changes_saved_success;

  /// No description provided for @two_factor_active_badge.
  ///
  /// In fr, this message translates to:
  /// **'2FA Actif'**
  String get two_factor_active_badge;

  /// No description provided for @two_factor_inactive_badge.
  ///
  /// In fr, this message translates to:
  /// **'2FA Inactif'**
  String get two_factor_inactive_badge;

  /// No description provided for @ai_revision_studio.
  ///
  /// In fr, this message translates to:
  /// **'Studio de Révision IA'**
  String get ai_revision_studio;

  /// No description provided for @generate_quiz_action.
  ///
  /// In fr, this message translates to:
  /// **'Générer un QCM d\'entraînement'**
  String get generate_quiz_action;

  /// No description provided for @smart_summaries_action.
  ///
  /// In fr, this message translates to:
  /// **'Fiches de synthèse intelligentes'**
  String get smart_summaries_action;

  /// No description provided for @ai_tutor_247.
  ///
  /// In fr, this message translates to:
  /// **'Tuteur interactif 24/7'**
  String get ai_tutor_247;

  /// No description provided for @open_catalog_courses.
  ///
  /// In fr, this message translates to:
  /// **'Modules en libre accès & Cours recommandés'**
  String get open_catalog_courses;

  /// No description provided for @start_learning.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir le cours'**
  String get start_learning;

  /// No description provided for @explore_catalog.
  ///
  /// In fr, this message translates to:
  /// **'Explorer le catalogue'**
  String get explore_catalog;

  /// No description provided for @scan_qr_code.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un QR code'**
  String get scan_qr_code;

  /// No description provided for @academic_timetable.
  ///
  /// In fr, this message translates to:
  /// **'Emploi du temps académique'**
  String get academic_timetable;

  /// No description provided for @homework_due.
  ///
  /// In fr, this message translates to:
  /// **'Devoirs à rendre'**
  String get homework_due;

  /// No description provided for @code_resent.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau code a été envoyé !'**
  String get code_resent;

  /// No description provided for @error_unexpected.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue'**
  String get error_unexpected;

  /// No description provided for @validate_action.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate_action;

  /// No description provided for @other_connected_devices.
  ///
  /// In fr, this message translates to:
  /// **'Autres appareils connectés'**
  String get other_connected_devices;

  /// No description provided for @current_session_location.
  ///
  /// In fr, this message translates to:
  /// **'IP : 196.200.185.42 • Rabat, Maroc'**
  String get current_session_location;

  /// No description provided for @device_windows_edge.
  ///
  /// In fr, this message translates to:
  /// **'Microsoft Edge sur Windows 11'**
  String get device_windows_edge;

  /// No description provided for @security_log_2fa_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Validation par clé temporaire 6 chiffres'**
  String get security_log_2fa_subtitle;

  /// No description provided for @registered_on.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré le {date}'**
  String registered_on(Object date);

  /// No description provided for @danger_freeze_btn.
  ///
  /// In fr, this message translates to:
  /// **'Geler mon compte'**
  String get danger_freeze_btn;

  /// No description provided for @freeze_confirm_btn.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la mise en veille'**
  String get freeze_confirm_btn;

  /// No description provided for @password_strength_weak.
  ///
  /// In fr, this message translates to:
  /// **'Force : Faible (minimum 8 caractères)'**
  String get password_strength_weak;

  /// No description provided for @password_strength_medium.
  ///
  /// In fr, this message translates to:
  /// **'Force : Moyenne'**
  String get password_strength_medium;

  /// No description provided for @password_strength_good.
  ///
  /// In fr, this message translates to:
  /// **'Force : Bonne'**
  String get password_strength_good;

  /// No description provided for @password_strength_excellent.
  ///
  /// In fr, this message translates to:
  /// **'Force : Excellente'**
  String get password_strength_excellent;

  /// No description provided for @admin_supervision_badge.
  ///
  /// In fr, this message translates to:
  /// **'SUPERVISION ACADÉMIQUE'**
  String get admin_supervision_badge;

  /// No description provided for @admin_winter_spring_session.
  ///
  /// In fr, this message translates to:
  /// **'•  Session Hiver-Printemps'**
  String get admin_winter_spring_session;

  /// No description provided for @admin_dashboard_title.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de Bord Administrateur'**
  String get admin_dashboard_title;

  /// No description provided for @admin_dashboard_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble et supervision de l\'établissement académique • Données en direct'**
  String get admin_dashboard_subtitle;

  /// No description provided for @admin_refresh_data.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser les données'**
  String get admin_refresh_data;

  /// No description provided for @admin_reports_audits.
  ///
  /// In fr, this message translates to:
  /// **'Rapports & Audits'**
  String get admin_reports_audits;

  /// No description provided for @admin_metric_headcount.
  ///
  /// In fr, this message translates to:
  /// **'EFFECTIF TOTAL'**
  String get admin_metric_headcount;

  /// No description provided for @admin_this_month_students.
  ///
  /// In fr, this message translates to:
  /// **'+{count} ce mois'**
  String admin_this_month_students(Object count);

  /// No description provided for @admin_real_time.
  ///
  /// In fr, this message translates to:
  /// **'Temps réel'**
  String get admin_real_time;

  /// No description provided for @admin_metric_faculty.
  ///
  /// In fr, this message translates to:
  /// **'CORPS ENSEIGNANT'**
  String get admin_metric_faculty;

  /// No description provided for @admin_active_teachers_label.
  ///
  /// In fr, this message translates to:
  /// **'Enseignants actifs'**
  String get admin_active_teachers_label;

  /// No description provided for @admin_active_pct.
  ///
  /// In fr, this message translates to:
  /// **'{pct}% actifs'**
  String admin_active_pct(Object pct);

  /// No description provided for @admin_metric_groups.
  ///
  /// In fr, this message translates to:
  /// **'GROUPES PÉDAGOGIQUES'**
  String get admin_metric_groups;

  /// No description provided for @admin_active_classes_label.
  ///
  /// In fr, this message translates to:
  /// **'Classes actives'**
  String get admin_active_classes_label;

  /// No description provided for @admin_created_count.
  ///
  /// In fr, this message translates to:
  /// **'+{count} créées'**
  String admin_created_count(Object count);

  /// No description provided for @admin_metric_integrity.
  ///
  /// In fr, this message translates to:
  /// **'INTÉGRITÉ & FRAUDE'**
  String get admin_metric_integrity;

  /// No description provided for @admin_pending_status.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get admin_pending_status;

  /// No description provided for @admin_action_24h.
  ///
  /// In fr, this message translates to:
  /// **'Action requise sous 24h'**
  String get admin_action_24h;

  /// No description provided for @admin_handle_action.
  ///
  /// In fr, this message translates to:
  /// **'Traiter >'**
  String get admin_handle_action;

  /// No description provided for @admin_recent_fraud_incidents.
  ///
  /// In fr, this message translates to:
  /// **'Derniers incidents de fraude signalés'**
  String get admin_recent_fraud_incidents;

  /// No description provided for @admin_biometric_surveillance.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance biométrique et comportementale SmartClass IA'**
  String get admin_biometric_surveillance;

  /// No description provided for @admin_filter_all_count.
  ///
  /// In fr, this message translates to:
  /// **'Tous ({count})'**
  String admin_filter_all_count(Object count);

  /// No description provided for @admin_filter_untreated_count.
  ///
  /// In fr, this message translates to:
  /// **'Non traités ({count})'**
  String admin_filter_untreated_count(Object count);

  /// No description provided for @admin_no_untreated_fraud.
  ///
  /// In fr, this message translates to:
  /// **'Aucun incident de fraude non traité'**
  String get admin_no_untreated_fraud;

  /// No description provided for @admin_no_fraud_recorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun incident de fraude enregistré'**
  String get admin_no_fraud_recorded;

  /// No description provided for @admin_all_reports_handled.
  ///
  /// In fr, this message translates to:
  /// **'Tous les signalements ont été traités par l\'administration.'**
  String get admin_all_reports_handled;

  /// No description provided for @admin_all_exams_compliant.
  ///
  /// In fr, this message translates to:
  /// **'Tous les examens et sessions surveillés sont conformes aux règles académiques.'**
  String get admin_all_exams_compliant;

  /// No description provided for @admin_student_fallback.
  ///
  /// In fr, this message translates to:
  /// **'Étudiant'**
  String get admin_student_fallback;

  /// No description provided for @admin_exam_session.
  ///
  /// In fr, this message translates to:
  /// **'Session d\'examen'**
  String get admin_exam_session;

  /// No description provided for @admin_evaluation_fallback.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation'**
  String get admin_evaluation_fallback;

  /// No description provided for @admin_auto_ai_detection.
  ///
  /// In fr, this message translates to:
  /// **'Détection automatique IA'**
  String get admin_auto_ai_detection;

  /// No description provided for @admin_take_charge.
  ///
  /// In fr, this message translates to:
  /// **'Prendre en charge'**
  String get admin_take_charge;

  /// No description provided for @admin_consult.
  ///
  /// In fr, this message translates to:
  /// **'Consulter'**
  String get admin_consult;

  /// No description provided for @admin_certified_ai_consensus.
  ///
  /// In fr, this message translates to:
  /// **'Intégrité académique certifiée par consensus IA'**
  String get admin_certified_ai_consensus;

  /// No description provided for @admin_view_all_integrity_reports.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les rapports d\'intégrité ({count})'**
  String admin_view_all_integrity_reports(Object count);

  /// No description provided for @admin_recent_system_activity.
  ///
  /// In fr, this message translates to:
  /// **'Activité récente du système'**
  String get admin_recent_system_activity;

  /// No description provided for @admin_active_cohorts_promos.
  ///
  /// In fr, this message translates to:
  /// **'Cohortes & promotions actives'**
  String get admin_active_cohorts_promos;

  /// No description provided for @admin_live_badge.
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get admin_live_badge;

  /// No description provided for @admin_no_cohort_configured.
  ///
  /// In fr, this message translates to:
  /// **'Aucune cohorte configurée'**
  String get admin_no_cohort_configured;

  /// No description provided for @admin_services_db.
  ///
  /// In fr, this message translates to:
  /// **'Services & Base de données'**
  String get admin_services_db;

  /// No description provided for @admin_live_sync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation en direct'**
  String get admin_live_sync;

  /// No description provided for @admin_operational.
  ///
  /// In fr, this message translates to:
  /// **'Opérationnel'**
  String get admin_operational;

  /// No description provided for @admin_quick_actions_supervision.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides & Supervision'**
  String get admin_quick_actions_supervision;

  /// No description provided for @admin_certified_shortcuts.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcis administratifs certifiés'**
  String get admin_certified_shortcuts;

  /// No description provided for @admin_create_new_class_btn.
  ///
  /// In fr, this message translates to:
  /// **'Créer une nouvelle classe'**
  String get admin_create_new_class_btn;

  /// No description provided for @admin_manage_classes_promos.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les classes & promotions'**
  String get admin_manage_classes_promos;

  /// No description provided for @admin_timetable_rooms.
  ///
  /// In fr, this message translates to:
  /// **'Emplois du temps & Salles'**
  String get admin_timetable_rooms;

  /// No description provided for @admin_surveillance_frauds.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance & Fraudes'**
  String get admin_surveillance_frauds;

  /// No description provided for @admin_severity_critical.
  ///
  /// In fr, this message translates to:
  /// **'Critique'**
  String get admin_severity_critical;

  /// No description provided for @admin_severity_medium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get admin_severity_medium;

  /// No description provided for @admin_status_active.
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get admin_status_active;

  /// No description provided for @admin_status_draft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get admin_status_draft;

  /// No description provided for @admin_referent_with_students.
  ///
  /// In fr, this message translates to:
  /// **'Réf. {name} • {count} étudiants'**
  String admin_referent_with_students(Object count, Object name);

  /// No description provided for @admin_students_enrolled_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} étudiants inscrits'**
  String admin_students_enrolled_count(Object count);

  /// No description provided for @admin_classes_breadcrumb_cat.
  ///
  /// In fr, this message translates to:
  /// **'ESPACE ADMINISTRATION'**
  String get admin_classes_breadcrumb_cat;

  /// No description provided for @admin_classes_breadcrumb_current.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Classes'**
  String get admin_classes_breadcrumb_current;

  /// No description provided for @admin_realtime_synced_data.
  ///
  /// In fr, this message translates to:
  /// **'Données synchronisées en temps réel'**
  String get admin_realtime_synced_data;

  /// No description provided for @admin_classes_page_heading.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Classes & Cohortes'**
  String get admin_classes_page_heading;

  /// No description provided for @admin_classes_page_desc.
  ///
  /// In fr, this message translates to:
  /// **'Consultez, organisez et configurez les promotions, effectifs d\'étudiants et affectations d\'enseignants.'**
  String get admin_classes_page_desc;

  /// No description provided for @admin_refresh_button.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get admin_refresh_button;

  /// No description provided for @admin_create_class_button.
  ///
  /// In fr, this message translates to:
  /// **'Créer une classe'**
  String get admin_create_class_button;

  /// No description provided for @admin_kpi_classes_promos.
  ///
  /// In fr, this message translates to:
  /// **'CLASSES & PROMOTIONS'**
  String get admin_kpi_classes_promos;

  /// No description provided for @admin_kpi_classes_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} Classes'**
  String admin_kpi_classes_count(Object count);

  /// No description provided for @admin_kpi_classes_badge.
  ///
  /// In fr, this message translates to:
  /// **'Actives'**
  String get admin_kpi_classes_badge;

  /// No description provided for @admin_kpi_students_enrollment.
  ///
  /// In fr, this message translates to:
  /// **'INSCRIPTIONS ÉTUDIANTS'**
  String get admin_kpi_students_enrollment;

  /// No description provided for @admin_kpi_students_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} Étudiants'**
  String admin_kpi_students_count(Object count);

  /// No description provided for @admin_kpi_students_badge.
  ///
  /// In fr, this message translates to:
  /// **'Total inscrits'**
  String get admin_kpi_students_badge;

  /// No description provided for @admin_kpi_faculty.
  ///
  /// In fr, this message translates to:
  /// **'CORPS ENSEIGNANT'**
  String get admin_kpi_faculty;

  /// No description provided for @admin_kpi_faculty_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} Enseignants'**
  String admin_kpi_faculty_count(Object count);

  /// No description provided for @admin_kpi_faculty_badge.
  ///
  /// In fr, this message translates to:
  /// **'Corps professoral'**
  String get admin_kpi_faculty_badge;

  /// No description provided for @admin_search_classes_placeholder.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une classe (nom, filière)...'**
  String get admin_search_classes_placeholder;

  /// No description provided for @admin_level_filter_all.
  ///
  /// In fr, this message translates to:
  /// **'Niveau : Tous'**
  String get admin_level_filter_all;

  /// No description provided for @admin_level_filter_prefix.
  ///
  /// In fr, this message translates to:
  /// **'Niveau : {level}'**
  String admin_level_filter_prefix(Object level);

  /// No description provided for @admin_unable_load_classes.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les classes.'**
  String get admin_unable_load_classes;

  /// No description provided for @admin_no_classes_found.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe trouvée'**
  String get admin_no_classes_found;

  /// No description provided for @admin_no_classes_hint.
  ///
  /// In fr, this message translates to:
  /// **'Créez une première classe pour commencer à organiser les cohortes.'**
  String get admin_no_classes_hint;

  /// No description provided for @admin_col_class_name.
  ///
  /// In fr, this message translates to:
  /// **'NOM DE LA CLASSE'**
  String get admin_col_class_name;

  /// No description provided for @admin_col_level_dept.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU & DÉPARTEMENT'**
  String get admin_col_level_dept;

  /// No description provided for @admin_col_headcount.
  ///
  /// In fr, this message translates to:
  /// **'EFFECTIF ÉTUDIANTS'**
  String get admin_col_headcount;

  /// No description provided for @admin_col_faculty.
  ///
  /// In fr, this message translates to:
  /// **'CORPS ENSEIGNANT'**
  String get admin_col_faculty;

  /// No description provided for @admin_col_status.
  ///
  /// In fr, this message translates to:
  /// **'STATUT'**
  String get admin_col_status;

  /// No description provided for @admin_col_actions.
  ///
  /// In fr, this message translates to:
  /// **'ACTIONS'**
  String get admin_col_actions;

  /// No description provided for @admin_unattached_promo.
  ///
  /// In fr, this message translates to:
  /// **'Non rattaché'**
  String get admin_unattached_promo;

  /// No description provided for @admin_students_count_label.
  ///
  /// In fr, this message translates to:
  /// **'{count} étudiants'**
  String admin_students_count_label(Object count);

  /// No description provided for @admin_students_enrolled_tag.
  ///
  /// In fr, this message translates to:
  /// **'{count} inscrit(s)'**
  String admin_students_enrolled_tag(Object count);

  /// No description provided for @admin_teachers_count_label.
  ///
  /// In fr, this message translates to:
  /// **'{count} enseignant(s)'**
  String admin_teachers_count_label(Object count);

  /// No description provided for @admin_status_published.
  ///
  /// In fr, this message translates to:
  /// **'Publiée'**
  String get admin_status_published;

  /// No description provided for @admin_manage_students_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les étudiants'**
  String get admin_manage_students_tooltip;

  /// No description provided for @admin_assign_teachers_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Affecter des enseignants'**
  String get admin_assign_teachers_tooltip;

  /// No description provided for @admin_menu_edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get admin_menu_edit;

  /// No description provided for @admin_menu_delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get admin_menu_delete;

  /// No description provided for @admin_confirm_delete_title.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la classe'**
  String get admin_confirm_delete_title;

  /// No description provided for @admin_confirm_delete_msg.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer la classe {name} ?'**
  String admin_confirm_delete_msg(Object name);

  /// No description provided for @admin_teachers_breadcrumb_cat.
  ///
  /// In fr, this message translates to:
  /// **'ESPACE ADMINISTRATION'**
  String get admin_teachers_breadcrumb_cat;

  /// No description provided for @admin_teachers_breadcrumb_current.
  ///
  /// In fr, this message translates to:
  /// **'Corps Professoral & Enseignants'**
  String get admin_teachers_breadcrumb_current;

  /// No description provided for @admin_teachers_page_heading.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Enseignants & Profs'**
  String get admin_teachers_page_heading;

  /// No description provided for @admin_teachers_page_desc.
  ///
  /// In fr, this message translates to:
  /// **'Supervisez le corps professoral, validez les accréditations, affectez les cours et promouvez des administrateurs.'**
  String get admin_teachers_page_desc;

  /// No description provided for @admin_kpi_total_teachers.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL ENSEIGNANTS'**
  String get admin_kpi_total_teachers;

  /// No description provided for @admin_kpi_badge_faculty.
  ///
  /// In fr, this message translates to:
  /// **'Corps professoral'**
  String get admin_kpi_badge_faculty;

  /// No description provided for @admin_kpi_approved_accreditations.
  ///
  /// In fr, this message translates to:
  /// **'ACCRÉDITATIONS VALIDÉES'**
  String get admin_kpi_approved_accreditations;

  /// No description provided for @admin_kpi_badge_verified_profiles.
  ///
  /// In fr, this message translates to:
  /// **'Profils vérifiés'**
  String get admin_kpi_badge_verified_profiles;

  /// No description provided for @admin_kpi_pending_accreditation.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE D\'ACCRÉDITATION'**
  String get admin_kpi_pending_accreditation;

  /// No description provided for @admin_kpi_badge_to_handle.
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get admin_kpi_badge_to_handle;

  /// No description provided for @admin_kpi_badge_up_to_date.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get admin_kpi_badge_up_to_date;

  /// No description provided for @admin_kpi_assigned_teachers.
  ///
  /// In fr, this message translates to:
  /// **'ENSEIGNANTS ASSIGNÉS'**
  String get admin_kpi_assigned_teachers;

  /// No description provided for @admin_kpi_badge_active_in_class.
  ///
  /// In fr, this message translates to:
  /// **'Actifs en cours'**
  String get admin_kpi_badge_active_in_class;

  /// No description provided for @admin_filter_all_label.
  ///
  /// In fr, this message translates to:
  /// **'Tous ({count})'**
  String admin_filter_all_label(Object count);

  /// No description provided for @admin_filter_validated_label.
  ///
  /// In fr, this message translates to:
  /// **'Validés ({count})'**
  String admin_filter_validated_label(Object count);

  /// No description provided for @admin_filter_pending_label.
  ///
  /// In fr, this message translates to:
  /// **'En attente ({count})'**
  String admin_filter_pending_label(Object count);

  /// No description provided for @admin_filter_rejected_label.
  ///
  /// In fr, this message translates to:
  /// **'Refusés ({count})'**
  String admin_filter_rejected_label(Object count);

  /// No description provided for @admin_search_teachers_placeholder.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher enseignant, matière, email...'**
  String get admin_search_teachers_placeholder;

  /// No description provided for @admin_col_teacher.
  ///
  /// In fr, this message translates to:
  /// **'ENSEIGNANT'**
  String get admin_col_teacher;

  /// No description provided for @admin_col_specialty_courses.
  ///
  /// In fr, this message translates to:
  /// **'SPÉCIALITÉ & COURS'**
  String get admin_col_specialty_courses;

  /// No description provided for @admin_col_accreditation.
  ///
  /// In fr, this message translates to:
  /// **'ACCRÉDITATION'**
  String get admin_col_accreditation;

  /// No description provided for @admin_col_dedicated_actions.
  ///
  /// In fr, this message translates to:
  /// **'ACTIONS DÉDIÉES'**
  String get admin_col_dedicated_actions;

  /// No description provided for @admin_no_teachers_found.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enseignant trouvé pour ces critères.'**
  String get admin_no_teachers_found;

  /// No description provided for @admin_unassigned_teacher.
  ///
  /// In fr, this message translates to:
  /// **'Non affecté'**
  String get admin_unassigned_teacher;

  /// No description provided for @admin_promote_admin_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir au rôle Administrateur'**
  String get admin_promote_admin_tooltip;

  /// No description provided for @admin_btn_admin.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get admin_btn_admin;

  /// No description provided for @admin_assign_class_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Affecter à une classe'**
  String get admin_assign_class_tooltip;

  /// No description provided for @admin_validate_accreditation_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'accréditation'**
  String get admin_validate_accreditation_tooltip;

  /// No description provided for @admin_reject_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get admin_reject_tooltip;

  /// No description provided for @admin_badge_approved.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get admin_badge_approved;

  /// No description provided for @admin_badge_pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get admin_badge_pending;

  /// No description provided for @admin_badge_rejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusé'**
  String get admin_badge_rejected;

  /// No description provided for @admin_inspector_teacher_title.
  ///
  /// In fr, this message translates to:
  /// **'DÉTAILS DU PROFESSEUR'**
  String get admin_inspector_teacher_title;

  /// No description provided for @admin_inspector_accreditation_status.
  ///
  /// In fr, this message translates to:
  /// **'Statut accréditation'**
  String get admin_inspector_accreditation_status;

  /// No description provided for @admin_inspector_specialty.
  ///
  /// In fr, this message translates to:
  /// **'Spécialité'**
  String get admin_inspector_specialty;

  /// No description provided for @admin_inspector_general.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get admin_inspector_general;

  /// No description provided for @admin_inspector_hourly_load.
  ///
  /// In fr, this message translates to:
  /// **'Charge horaire'**
  String get admin_inspector_hourly_load;

  /// No description provided for @admin_inspector_unspecified.
  ///
  /// In fr, this message translates to:
  /// **'Non spécifiée'**
  String get admin_inspector_unspecified;

  /// No description provided for @admin_inspector_email_verified.
  ///
  /// In fr, this message translates to:
  /// **'Email vérifié'**
  String get admin_inspector_email_verified;

  /// No description provided for @admin_inspector_quick_actions.
  ///
  /// In fr, this message translates to:
  /// **'Actions Rapides'**
  String get admin_inspector_quick_actions;

  /// No description provided for @admin_btn_promote_admin.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir Administrateur'**
  String get admin_btn_promote_admin;

  /// No description provided for @admin_btn_assign_to_class.
  ///
  /// In fr, this message translates to:
  /// **'Affecter à une classe'**
  String get admin_btn_assign_to_class;

  /// No description provided for @admin_btn_validate_accreditation.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'accréditation'**
  String get admin_btn_validate_accreditation;

  /// No description provided for @admin_btn_suspend_reject.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre / Rejeter'**
  String get admin_btn_suspend_reject;

  /// No description provided for @admin_dialog_promote_title.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir {name} Administrateur ?'**
  String admin_dialog_promote_title(Object name);

  /// No description provided for @admin_dialog_promote_desc.
  ///
  /// In fr, this message translates to:
  /// **'Ce rôle confère un accès illimité à la console de gestion, aux effectifs, aux cours et aux sanctions académiques.'**
  String get admin_dialog_promote_desc;

  /// No description provided for @admin_btn_confirm_promotion.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la promotion'**
  String get admin_btn_confirm_promotion;

  /// No description provided for @admin_toast_promoted_success.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été promu Administrateur avec succès.'**
  String admin_toast_promoted_success(Object name);

  /// No description provided for @admin_toast_promote_fail.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la promotion: rôle non modifiable ou permission requise.'**
  String get admin_toast_promote_fail;

  /// No description provided for @admin_dialog_assign_title.
  ///
  /// In fr, this message translates to:
  /// **'Affecter à une classe'**
  String get admin_dialog_assign_title;

  /// No description provided for @admin_dialog_assign_class_label.
  ///
  /// In fr, this message translates to:
  /// **'CLASSE CIBLE'**
  String get admin_dialog_assign_class_label;

  /// No description provided for @admin_dialog_subject_label.
  ///
  /// In fr, this message translates to:
  /// **'MATIÈRE / COURS ENSEIGNÉ'**
  String get admin_dialog_subject_label;

  /// No description provided for @admin_dialog_subject_hint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Mathématiques, Algorithmique...'**
  String get admin_dialog_subject_hint;

  /// No description provided for @admin_dialog_hours_label.
  ///
  /// In fr, this message translates to:
  /// **'CHARGE HORAIRE HEBDOMADAIRE'**
  String get admin_dialog_hours_label;

  /// No description provided for @admin_dialog_hours_hint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 4h / semaine'**
  String get admin_dialog_hours_hint;

  /// No description provided for @admin_btn_save_assignment.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer l\'affectation'**
  String get admin_btn_save_assignment;

  /// No description provided for @admin_toast_assign_success.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant {name} affecté à la classe avec succès.'**
  String admin_toast_assign_success(Object name);

  /// No description provided for @admin_toast_assign_fail.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'affectation à la classe.'**
  String get admin_toast_assign_fail;

  /// No description provided for @admin_students_breadcrumb_cat.
  ///
  /// In fr, this message translates to:
  /// **'ESPACE ADMINISTRATION'**
  String get admin_students_breadcrumb_cat;

  /// No description provided for @admin_students_breadcrumb_current.
  ///
  /// In fr, this message translates to:
  /// **'Annuaire & Cohortes'**
  String get admin_students_breadcrumb_current;

  /// No description provided for @admin_students_page_heading.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Étudiants & Promotions'**
  String get admin_students_page_heading;

  /// No description provided for @admin_students_page_desc.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les effectifs étudiants, gérez les affectations aux classes et supervisez les comptes.'**
  String get admin_students_page_desc;

  /// No description provided for @admin_kpi_total_students.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL ÉTUDIANTS'**
  String get admin_kpi_total_students;

  /// No description provided for @admin_kpi_badge_enrolled.
  ///
  /// In fr, this message translates to:
  /// **'Effectif inscrit'**
  String get admin_kpi_badge_enrolled;

  /// No description provided for @admin_kpi_in_cohort.
  ///
  /// In fr, this message translates to:
  /// **'INSCRITS EN COHORTE'**
  String get admin_kpi_in_cohort;

  /// No description provided for @admin_kpi_badge_assigned.
  ///
  /// In fr, this message translates to:
  /// **'Affectés en classe'**
  String get admin_kpi_badge_assigned;

  /// No description provided for @admin_kpi_unassigned.
  ///
  /// In fr, this message translates to:
  /// **'SANS CLASSE ASSIGNÉE'**
  String get admin_kpi_unassigned;

  /// No description provided for @admin_kpi_badge_to_assign.
  ///
  /// In fr, this message translates to:
  /// **'À affecter'**
  String get admin_kpi_badge_to_assign;

  /// No description provided for @admin_kpi_badge_all_assigned.
  ///
  /// In fr, this message translates to:
  /// **'Tous assignés'**
  String get admin_kpi_badge_all_assigned;

  /// No description provided for @admin_kpi_verified_accounts.
  ///
  /// In fr, this message translates to:
  /// **'COMPTES VÉRIFIÉS'**
  String get admin_kpi_verified_accounts;

  /// No description provided for @admin_kpi_badge_verified_email.
  ///
  /// In fr, this message translates to:
  /// **'Email vérifié'**
  String get admin_kpi_badge_verified_email;

  /// No description provided for @admin_dropdown_all_promos.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les promotions ({count} classes)'**
  String admin_dropdown_all_promos(Object count);

  /// No description provided for @admin_search_students_placeholder.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher étudiant, email, matricule...'**
  String get admin_search_students_placeholder;

  /// No description provided for @admin_col_student.
  ///
  /// In fr, this message translates to:
  /// **'ÉTUDIANT'**
  String get admin_col_student;

  /// No description provided for @admin_col_class_cohort.
  ///
  /// In fr, this message translates to:
  /// **'CLASSE & COHORTE'**
  String get admin_col_class_cohort;

  /// No description provided for @admin_col_account_status.
  ///
  /// In fr, this message translates to:
  /// **'STATUT COMPTE'**
  String get admin_col_account_status;

  /// No description provided for @admin_no_students_found.
  ///
  /// In fr, this message translates to:
  /// **'Aucun étudiant trouvé pour ces critères.'**
  String get admin_no_students_found;

  /// No description provided for @admin_unassigned_badge.
  ///
  /// In fr, this message translates to:
  /// **'Non assigné'**
  String get admin_unassigned_badge;

  /// No description provided for @admin_badge_verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get admin_badge_verified;

  /// No description provided for @admin_badge_unverified.
  ///
  /// In fr, this message translates to:
  /// **'Non vérifié'**
  String get admin_badge_unverified;

  /// No description provided for @admin_btn_change.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get admin_btn_change;

  /// No description provided for @admin_btn_assign.
  ///
  /// In fr, this message translates to:
  /// **'Affecter'**
  String get admin_btn_assign;

  /// No description provided for @admin_tooltip_change_class.
  ///
  /// In fr, this message translates to:
  /// **'Changer de classe'**
  String get admin_tooltip_change_class;

  /// No description provided for @admin_tooltip_assign_class.
  ///
  /// In fr, this message translates to:
  /// **'Affecter à une classe'**
  String get admin_tooltip_assign_class;

  /// No description provided for @admin_tooltip_remove_class.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la classe'**
  String get admin_tooltip_remove_class;

  /// No description provided for @admin_inspector_student_title.
  ///
  /// In fr, this message translates to:
  /// **'DOSSIER ÉTUDIANT'**
  String get admin_inspector_student_title;

  /// No description provided for @admin_inspector_current_class.
  ///
  /// In fr, this message translates to:
  /// **'Classe actuelle'**
  String get admin_inspector_current_class;

  /// No description provided for @admin_inspector_level_cycle.
  ///
  /// In fr, this message translates to:
  /// **'Niveau / Cycle'**
  String get admin_inspector_level_cycle;

  /// No description provided for @admin_inspector_cohort_assignment.
  ///
  /// In fr, this message translates to:
  /// **'Affectation de Cohorte'**
  String get admin_inspector_cohort_assignment;

  /// No description provided for @admin_btn_transfer_class.
  ///
  /// In fr, this message translates to:
  /// **'Transférer de classe'**
  String get admin_btn_transfer_class;

  /// No description provided for @admin_btn_assign_class.
  ///
  /// In fr, this message translates to:
  /// **'Assigner à une classe'**
  String get admin_btn_assign_class;

  /// No description provided for @admin_btn_remove_from_class.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la classe'**
  String get admin_btn_remove_from_class;

  /// No description provided for @admin_dialog_assign_student_title.
  ///
  /// In fr, this message translates to:
  /// **'Affecter {name} à une classe'**
  String admin_dialog_assign_student_title(Object name);

  /// No description provided for @admin_btn_confirm_assignment.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'affectation'**
  String get admin_btn_confirm_assignment;

  /// No description provided for @admin_toast_student_assigned_success.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été assigné(e) à la classe avec succès.'**
  String admin_toast_student_assigned_success(Object name);

  /// No description provided for @admin_toast_student_assign_fail.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'affectation de l\'étudiant.'**
  String get admin_toast_student_assign_fail;

  /// No description provided for @admin_dialog_remove_title.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la classe'**
  String get admin_dialog_remove_title;

  /// No description provided for @admin_dialog_remove_msg.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous retirer {name} de sa classe actuelle ? L\'étudiant sera placé en statut libre sans cohorte.'**
  String admin_dialog_remove_msg(Object name);

  /// No description provided for @admin_btn_remove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get admin_btn_remove;

  /// No description provided for @admin_toast_student_removed.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été retiré(e) de la classe.'**
  String admin_toast_student_removed(Object name);

  /// No description provided for @admin_toast_student_remove_fail.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du retrait de l\'étudiant.'**
  String get admin_toast_student_remove_fail;

  /// No description provided for @admin_breadcrumb_classes.
  ///
  /// In fr, this message translates to:
  /// **'Classes'**
  String get admin_breadcrumb_classes;

  /// No description provided for @admin_breadcrumb_new_class.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle classe'**
  String get admin_breadcrumb_new_class;

  /// No description provided for @admin_breadcrumb_edit_class.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la classe'**
  String get admin_breadcrumb_edit_class;

  /// No description provided for @admin_btn_return_classes.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux classes'**
  String get admin_btn_return_classes;

  /// No description provided for @admin_class_create_heading.
  ///
  /// In fr, this message translates to:
  /// **'Créer une nouvelle classe'**
  String get admin_class_create_heading;

  /// No description provided for @admin_class_edit_heading.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la classe'**
  String get admin_class_edit_heading;

  /// No description provided for @admin_class_create_sub.
  ///
  /// In fr, this message translates to:
  /// **'Configurez la cohorte académique, son effectif cible et son enseignant référent avec synchronisation en temps réel.'**
  String get admin_class_create_sub;

  /// No description provided for @admin_step1_badge.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE 1'**
  String get admin_step1_badge;

  /// No description provided for @admin_step1_title.
  ///
  /// In fr, this message translates to:
  /// **'Identité Académique & Cursus'**
  String get admin_step1_title;

  /// No description provided for @admin_step1_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Nom officiel, niveau d\'études et rattachement de la filière'**
  String get admin_step1_subtitle;

  /// No description provided for @admin_class_name_example.
  ///
  /// In fr, this message translates to:
  /// **'Ex: L3 Informatique - Groupe A'**
  String get admin_class_name_example;

  /// No description provided for @admin_study_level_label.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU D\'ÉTUDES ACADÉMIQUE'**
  String get admin_study_level_label;

  /// No description provided for @admin_department_label.
  ///
  /// In fr, this message translates to:
  /// **'FILIÈRE & DÉPARTEMENT DE RATTACHEMENT'**
  String get admin_department_label;

  /// No description provided for @admin_custom_department_hint.
  ///
  /// In fr, this message translates to:
  /// **'Ou saisir une nouvelle filière / département personnalisé...'**
  String get admin_custom_department_hint;

  /// No description provided for @admin_step2_badge.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE 2'**
  String get admin_step2_badge;

  /// No description provided for @admin_step2_title.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant Référent & Effectif Cible'**
  String get admin_step2_title;

  /// No description provided for @admin_step2_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Affectation pédagogique et dimensionnement de la classe'**
  String get admin_step2_subtitle;

  /// No description provided for @admin_teacher_referent_label.
  ///
  /// In fr, this message translates to:
  /// **'ENSEIGNANT RÉFÉRENT (OPTIONNEL)'**
  String get admin_teacher_referent_label;

  /// No description provided for @admin_teacher_loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des enseignants...'**
  String get admin_teacher_loading;

  /// No description provided for @admin_teacher_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des enseignants'**
  String get admin_teacher_error;

  /// No description provided for @admin_no_referent_option.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enseignant référent (assigner ultérieurement)'**
  String get admin_no_referent_option;

  /// No description provided for @admin_group_capacity_label.
  ///
  /// In fr, this message translates to:
  /// **'CAPACITÉ D\'ACCUEIL DU GROUPE'**
  String get admin_group_capacity_label;

  /// No description provided for @admin_students_max_label.
  ///
  /// In fr, this message translates to:
  /// **'étudiants max'**
  String get admin_students_max_label;

  /// No description provided for @admin_presets_label.
  ///
  /// In fr, this message translates to:
  /// **'Préréglages universitaires :'**
  String get admin_presets_label;

  /// No description provided for @admin_step3_badge.
  ///
  /// In fr, this message translates to:
  /// **'OPTIONNEL'**
  String get admin_step3_badge;

  /// No description provided for @admin_step3_title.
  ///
  /// In fr, this message translates to:
  /// **'Description & Modules Collaboratifs'**
  String get admin_step3_title;

  /// No description provided for @admin_step3_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Présentation et activation des services interactifs'**
  String get admin_step3_subtitle;

  /// No description provided for @admin_description_label_title.
  ///
  /// In fr, this message translates to:
  /// **'DESCRIPTION ACADÉMIQUE'**
  String get admin_description_label_title;

  /// No description provided for @admin_description_placeholder.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs de la cohorte, prérequis, remarques pédagogiques...'**
  String get admin_description_placeholder;

  /// No description provided for @admin_smartclass_services_label.
  ///
  /// In fr, this message translates to:
  /// **'SERVICES & INTÉGRATIONS SMARTCLASS'**
  String get admin_smartclass_services_label;

  /// No description provided for @admin_service_forum_title.
  ///
  /// In fr, this message translates to:
  /// **'Forum d\'échange'**
  String get admin_service_forum_title;

  /// No description provided for @admin_service_forum_sub.
  ///
  /// In fr, this message translates to:
  /// **'Discussion entre étudiants'**
  String get admin_service_forum_sub;

  /// No description provided for @admin_service_ent_title.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation ENT'**
  String get admin_service_ent_title;

  /// No description provided for @admin_service_ent_sub.
  ///
  /// In fr, this message translates to:
  /// **'Plannings et cours auto'**
  String get admin_service_ent_sub;

  /// No description provided for @admin_live_preview_header.
  ///
  /// In fr, this message translates to:
  /// **'APERÇU EN DIRECT'**
  String get admin_live_preview_header;

  /// No description provided for @admin_dept_unspecified_session.
  ///
  /// In fr, this message translates to:
  /// **'Filière non spécifiée • 2026-2027'**
  String get admin_dept_unspecified_session;

  /// No description provided for @admin_dept_specified_session.
  ///
  /// In fr, this message translates to:
  /// **'{dept} • Session 2026-2027'**
  String admin_dept_specified_session(Object dept);

  /// No description provided for @admin_referent_teacher_title.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant Référent'**
  String get admin_referent_teacher_title;

  /// No description provided for @admin_referent_unassigned.
  ///
  /// In fr, this message translates to:
  /// **'Non assigné'**
  String get admin_referent_unassigned;

  /// No description provided for @admin_capacity_label_preview.
  ///
  /// In fr, this message translates to:
  /// **'Capacité d\'accueil'**
  String get admin_capacity_label_preview;

  /// No description provided for @admin_capacity_students_ratio.
  ///
  /// In fr, this message translates to:
  /// **'0 / {capacity} étudiants'**
  String admin_capacity_students_ratio(Object capacity);

  /// No description provided for @admin_chip_forum_active.
  ///
  /// In fr, this message translates to:
  /// **'Forum actif'**
  String get admin_chip_forum_active;

  /// No description provided for @admin_chip_ent_synced.
  ///
  /// In fr, this message translates to:
  /// **'ENT synchronisé'**
  String get admin_chip_ent_synced;

  /// No description provided for @admin_validation_criteria_title.
  ///
  /// In fr, this message translates to:
  /// **'CRITÈRES DE VALIDATION'**
  String get admin_validation_criteria_title;

  /// No description provided for @admin_criterion_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la cohorte renseigné'**
  String get admin_criterion_name;

  /// No description provided for @admin_criterion_level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'études sélectionné'**
  String get admin_criterion_level;

  /// No description provided for @admin_criterion_dept.
  ///
  /// In fr, this message translates to:
  /// **'Filière ou département associé'**
  String get admin_criterion_dept;

  /// No description provided for @admin_criterion_capacity.
  ///
  /// In fr, this message translates to:
  /// **'Capacité d\'accueil valide (> 0)'**
  String get admin_criterion_capacity;

  /// No description provided for @admin_btn_save_changes.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get admin_btn_save_changes;

  /// No description provided for @admin_btn_save_draft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer comme brouillon'**
  String get admin_btn_save_draft;

  /// No description provided for @admin_toast_class_updated.
  ///
  /// In fr, this message translates to:
  /// **'Classe modifiée avec succès.'**
  String get admin_toast_class_updated;

  /// No description provided for @admin_toast_class_draft_saved.
  ///
  /// In fr, this message translates to:
  /// **'Classe enregistrée comme brouillon.'**
  String get admin_toast_class_draft_saved;

  /// No description provided for @admin_toast_class_created.
  ///
  /// In fr, this message translates to:
  /// **'Classe créée avec succès.'**
  String get admin_toast_class_created;

  /// No description provided for @admin_cycle_licence.
  ///
  /// In fr, this message translates to:
  /// **'Cycle Licence (LMD)'**
  String get admin_cycle_licence;

  /// No description provided for @admin_cycle_master.
  ///
  /// In fr, this message translates to:
  /// **'Cycle Master & Spécialités'**
  String get admin_cycle_master;

  /// No description provided for @admin_cycle_doctorat.
  ///
  /// In fr, this message translates to:
  /// **'Troisième Cycle & Doctorat'**
  String get admin_cycle_doctorat;

  /// No description provided for @admin_planning_breadcrumb_current.
  ///
  /// In fr, this message translates to:
  /// **'Emploi du Temps & Planning'**
  String get admin_planning_breadcrumb_current;

  /// No description provided for @admin_planning_heading.
  ///
  /// In fr, this message translates to:
  /// **'Planning Hebdomadaire des Classes'**
  String get admin_planning_heading;

  /// No description provided for @admin_planning_sub.
  ///
  /// In fr, this message translates to:
  /// **'Consultez et ajustez la grille horaire des cours, salles et enseignants par classe.'**
  String get admin_planning_sub;

  /// No description provided for @admin_prev_week_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Semaine précédente'**
  String get admin_prev_week_tooltip;

  /// No description provided for @admin_next_week_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Semaine suivante'**
  String get admin_next_week_tooltip;

  /// No description provided for @admin_today_btn.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get admin_today_btn;

  /// No description provided for @admin_selected_class_label.
  ///
  /// In fr, this message translates to:
  /// **'Classe sélectionnée :'**
  String get admin_selected_class_label;

  /// No description provided for @admin_hours_planned.
  ///
  /// In fr, this message translates to:
  /// **'{hours} prévues'**
  String admin_hours_planned(Object hours);

  /// No description provided for @admin_unable_load_planning.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le planning.'**
  String get admin_unable_load_planning;

  /// No description provided for @admin_first_create_class_planning.
  ///
  /// In fr, this message translates to:
  /// **'Créez d\'abord une classe pour gérer son planning.'**
  String get admin_first_create_class_planning;

  /// No description provided for @admin_no_courses_this_week.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cours programmé cette semaine.'**
  String get admin_no_courses_this_week;

  /// No description provided for @admin_no_courses_day.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cours'**
  String get admin_no_courses_day;

  /// No description provided for @admin_reports_breadcrumb_current.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance Anti-Fraude & Intégrité'**
  String get admin_reports_breadcrumb_current;

  /// No description provided for @admin_reports_heading.
  ///
  /// In fr, this message translates to:
  /// **'Audit d\'Intégrité & Rapports de Fraude'**
  String get admin_reports_heading;

  /// No description provided for @admin_reports_sub.
  ///
  /// In fr, this message translates to:
  /// **'Supervisez les alertes télémétriques générées lors des examens en ligne et appliquez les sanctions administratives.'**
  String get admin_reports_sub;

  /// No description provided for @admin_kpi_untreated.
  ///
  /// In fr, this message translates to:
  /// **'NON TRAITÉS'**
  String get admin_kpi_untreated;

  /// No description provided for @admin_kpi_badge_action_req.
  ///
  /// In fr, this message translates to:
  /// **'Action requise'**
  String get admin_kpi_badge_action_req;

  /// No description provided for @admin_kpi_in_arbitration.
  ///
  /// In fr, this message translates to:
  /// **'EN COURS D\'ARBITRAGE'**
  String get admin_kpi_in_arbitration;

  /// No description provided for @admin_kpi_badge_instructing.
  ///
  /// In fr, this message translates to:
  /// **'En instruction'**
  String get admin_kpi_badge_instructing;

  /// No description provided for @admin_kpi_resolved_this_month.
  ///
  /// In fr, this message translates to:
  /// **'RÉSOLUS CE MOIS'**
  String get admin_kpi_resolved_this_month;

  /// No description provided for @admin_kpi_badge_closed.
  ///
  /// In fr, this message translates to:
  /// **'Clôturés'**
  String get admin_kpi_badge_closed;

  /// No description provided for @admin_dialog_close_dossier_title.
  ///
  /// In fr, this message translates to:
  /// **'Clôturer le dossier'**
  String get admin_dialog_close_dossier_title;

  /// No description provided for @admin_dialog_dossier_of.
  ///
  /// In fr, this message translates to:
  /// **'Dossier de : {name} ({title})'**
  String admin_dialog_dossier_of(Object name, Object title);

  /// No description provided for @admin_dialog_decision_hint.
  ///
  /// In fr, this message translates to:
  /// **'Précisez la décision ou les sanctions éventuelles...'**
  String get admin_dialog_decision_hint;

  /// No description provided for @admin_btn_confirm_closure.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la clôture'**
  String get admin_btn_confirm_closure;

  /// No description provided for @admin_toast_dossier_updated.
  ///
  /// In fr, this message translates to:
  /// **'Statut du dossier mis à jour.'**
  String get admin_toast_dossier_updated;

  /// No description provided for @admin_toast_dossier_update_fail.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour le dossier.'**
  String get admin_toast_dossier_update_fail;

  /// No description provided for @admin_enrolled_count.
  ///
  /// In fr, this message translates to:
  /// **'{count} inscrits'**
  String admin_enrolled_count(Object count);

  /// No description provided for @admin_student_assign_notice.
  ///
  /// In fr, this message translates to:
  /// **'L\'étudiant recevra immédiatement ses emplois du temps et les devoirs associés à cette classe.'**
  String get admin_student_assign_notice;

  /// No description provided for @admin_choose_cohort_assign.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la promotion / cohorte d\'affectation:'**
  String get admin_choose_cohort_assign;

  /// No description provided for @admin_no_classes_available.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe disponible. Créez d\'abord une classe.'**
  String get admin_no_classes_available;

  /// No description provided for @admin_student_label.
  ///
  /// In fr, this message translates to:
  /// **'Étudiant: {name}'**
  String admin_student_label(Object name);

  /// No description provided for @admin_teacher_label.
  ///
  /// In fr, this message translates to:
  /// **'Professeur: {name}'**
  String admin_teacher_label(Object name);

  /// No description provided for @admin_col_assigned_class.
  ///
  /// In fr, this message translates to:
  /// **'CLASSE ASSIGNÉE'**
  String get admin_col_assigned_class;

  /// No description provided for @admin_toast_accreditation_approved.
  ///
  /// In fr, this message translates to:
  /// **'Accréditation de {name} validée.'**
  String admin_toast_accreditation_approved(Object name);

  /// No description provided for @admin_toast_accreditation_rejected.
  ///
  /// In fr, this message translates to:
  /// **'Accréditation de {name} refusée.'**
  String admin_toast_accreditation_rejected(Object name);

  /// No description provided for @admin_toast_update_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour.'**
  String get admin_toast_update_error;

  /// No description provided for @admin_select_class_cohort.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la classe / cohorte:'**
  String get admin_select_class_cohort;

  /// No description provided for @admin_weekly_hours_label.
  ///
  /// In fr, this message translates to:
  /// **'Volume horaire hebdomadaire:'**
  String get admin_weekly_hours_label;

  /// No description provided for @admin_hours_per_week.
  ///
  /// In fr, this message translates to:
  /// **'{hours}h / semaine'**
  String admin_hours_per_week(Object hours);

  /// No description provided for @admin_planning_lunch.
  ///
  /// In fr, this message translates to:
  /// **'DÉJEUNER'**
  String get admin_planning_lunch;

  /// No description provided for @admin_planning_room_undefined.
  ///
  /// In fr, this message translates to:
  /// **'Salle non définie'**
  String get admin_planning_room_undefined;

  /// No description provided for @admin_filter_all_alerts.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les alertes'**
  String get admin_filter_all_alerts;

  /// No description provided for @admin_filter_in_progress_count.
  ///
  /// In fr, this message translates to:
  /// **'En cours ({count})'**
  String admin_filter_in_progress_count(Object count);

  /// No description provided for @admin_filter_closed_count.
  ///
  /// In fr, this message translates to:
  /// **'Clôturés ({count})'**
  String admin_filter_closed_count(Object count);

  /// No description provided for @admin_no_fraud_reports.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signalement de fraude'**
  String get admin_no_fraud_reports;

  /// No description provided for @admin_select_an_alert.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une alerte'**
  String get admin_select_an_alert;

  /// No description provided for @admin_findings_detected.
  ///
  /// In fr, this message translates to:
  /// **'Anomalies détectées :'**
  String get admin_findings_detected;

  /// No description provided for @admin_resolution_administrative.
  ///
  /// In fr, this message translates to:
  /// **'Résolution administrative :'**
  String get admin_resolution_administrative;

  /// No description provided for @admin_btn_take_charge.
  ///
  /// In fr, this message translates to:
  /// **'Prendre en charge'**
  String get admin_btn_take_charge;

  /// No description provided for @admin_btn_close_case.
  ///
  /// In fr, this message translates to:
  /// **'Clôturer'**
  String get admin_btn_close_case;

  /// No description provided for @admin_severity_closed.
  ///
  /// In fr, this message translates to:
  /// **'Classé'**
  String get admin_severity_closed;

  /// No description provided for @admin_status_in_progress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get admin_status_in_progress;

  /// No description provided for @admin_status_closed.
  ///
  /// In fr, this message translates to:
  /// **'Clôturé'**
  String get admin_status_closed;

  /// No description provided for @admin_users_breadcrumb_cat.
  ///
  /// In fr, this message translates to:
  /// **'ESPACE ADMINISTRATION'**
  String get admin_users_breadcrumb_cat;

  /// No description provided for @admin_users_breadcrumb_current.
  ///
  /// In fr, this message translates to:
  /// **'Annuaire & Rôles'**
  String get admin_users_breadcrumb_current;

  /// No description provided for @admin_users_page_heading.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Utilisateurs'**
  String get admin_users_page_heading;

  /// No description provided for @admin_users_page_desc.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les effectifs, validez les accréditations d\'enseignants et supervisez les comptes.'**
  String get admin_users_page_desc;

  /// No description provided for @admin_kpi_enrolled_students.
  ///
  /// In fr, this message translates to:
  /// **'ÉTUDIANTS INSCRITS'**
  String get admin_kpi_enrolled_students;

  /// No description provided for @admin_kpi_student_headcount.
  ///
  /// In fr, this message translates to:
  /// **'Effectif étudiant'**
  String get admin_kpi_student_headcount;

  /// No description provided for @admin_tab_students_count.
  ///
  /// In fr, this message translates to:
  /// **'Étudiants ({count})'**
  String admin_tab_students_count(Object count);

  /// No description provided for @admin_no_users_match_filter.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur ne correspond à ce filtre.'**
  String get admin_no_users_match_filter;

  /// No description provided for @admin_toast_teacher_approved.
  ///
  /// In fr, this message translates to:
  /// **'Compte enseignant validé avec succès.'**
  String get admin_toast_teacher_approved;

  /// No description provided for @admin_toast_teacher_updated.
  ///
  /// In fr, this message translates to:
  /// **'Compte enseignant mis à jour.'**
  String get admin_toast_teacher_updated;

  /// No description provided for @admin_status_assigned.
  ///
  /// In fr, this message translates to:
  /// **'Assigné'**
  String get admin_status_assigned;

  /// No description provided for @admin_step_1_badge.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE 1'**
  String get admin_step_1_badge;

  /// No description provided for @admin_step_2_badge.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE 2'**
  String get admin_step_2_badge;

  /// No description provided for @admin_step_3_badge.
  ///
  /// In fr, this message translates to:
  /// **'OPTIONNEL'**
  String get admin_step_3_badge;

  /// No description provided for @admin_live_preview.
  ///
  /// In fr, this message translates to:
  /// **'APERÇU EN DIRECT'**
  String get admin_live_preview;

  /// No description provided for @admin_assign_students_desc.
  ///
  /// In fr, this message translates to:
  /// **'Affecter des étudiants inscrits à {title}'**
  String admin_assign_students_desc(Object title);

  /// No description provided for @admin_assign_teachers_desc.
  ///
  /// In fr, this message translates to:
  /// **'Affecter des enseignants et matières à {title}'**
  String admin_assign_teachers_desc(Object title);

  /// No description provided for @admin_loading_classes.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des classes...'**
  String get admin_loading_classes;

  /// No description provided for @admin_loading_students.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des étudiants...'**
  String get admin_loading_students;

  /// No description provided for @admin_toast_teacher_approved_short.
  ///
  /// In fr, this message translates to:
  /// **'Compte enseignant validé avec succès'**
  String get admin_toast_teacher_approved_short;

  /// No description provided for @admin_toast_teacher_rejected_short.
  ///
  /// In fr, this message translates to:
  /// **'Compte enseignant refusé'**
  String get admin_toast_teacher_rejected_short;

  /// No description provided for @admin_btn_reapprove.
  ///
  /// In fr, this message translates to:
  /// **'Réapprouver'**
  String get admin_btn_reapprove;

  /// No description provided for @admin_btn_suspend_revoke.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre / Révoquer'**
  String get admin_btn_suspend_revoke;

  /// No description provided for @admin_col_exam.
  ///
  /// In fr, this message translates to:
  /// **'Épreuve'**
  String get admin_col_exam;

  /// No description provided for @admin_col_class.
  ///
  /// In fr, this message translates to:
  /// **'Classe'**
  String get admin_col_class;

  /// No description provided for @admin_col_severity.
  ///
  /// In fr, this message translates to:
  /// **'Gravité'**
  String get admin_col_severity;

  /// No description provided for @admin_col_user.
  ///
  /// In fr, this message translates to:
  /// **'UTILISATEUR'**
  String get admin_col_user;

  /// No description provided for @admin_col_academic_email.
  ///
  /// In fr, this message translates to:
  /// **'EMAIL ACADÉMIQUE'**
  String get admin_col_academic_email;

  /// No description provided for @admin_col_role_class.
  ///
  /// In fr, this message translates to:
  /// **'RÔLE & CLASSE'**
  String get admin_col_role_class;

  /// No description provided for @admin_select_a_user.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un utilisateur'**
  String get admin_select_a_user;

  /// No description provided for @admin_label_role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get admin_label_role;

  /// No description provided for @admin_label_assignment.
  ///
  /// In fr, this message translates to:
  /// **'Affectation'**
  String get admin_label_assignment;

  /// No description provided for @admin_label_pedagogical_accreditation.
  ///
  /// In fr, this message translates to:
  /// **'Accréditation pédagogique'**
  String get admin_label_pedagogical_accreditation;

  /// No description provided for @admin_btn_validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get admin_btn_validate;

  /// No description provided for @admin_btn_suspend.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre'**
  String get admin_btn_suspend;
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
