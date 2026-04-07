import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'TeeStats'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get rounds;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSignInToContinue;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// No description provided for @loginDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginDontHaveAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Play  ·  Track  ·  Improve'**
  String get loginTagline;

  /// No description provided for @loginResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get loginResetPasswordTitle;

  /// No description provided for @loginResetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a reset link to your email'**
  String get loginResetPasswordSubtitle;

  /// No description provided for @loginEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get loginEnterYourEmail;

  /// No description provided for @loginEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get loginEnterValidEmail;

  /// No description provided for @loginSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get loginSendResetLink;

  /// No description provided for @loginResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent!'**
  String get loginResetLinkSent;

  /// No description provided for @loginCheckInboxFor.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for {email}'**
  String loginCheckInboxFor(String email);

  /// No description provided for @loginErrorNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get loginErrorNoAccount;

  /// No description provided for @loginErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get loginErrorInvalidEmail;

  /// No description provided for @loginErrorSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get loginErrorSomethingWrong;

  /// No description provided for @loginErrorIncorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get loginErrorIncorrectCredentials;

  /// No description provided for @loginErrorAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get loginErrorAccountDisabled;

  /// No description provided for @loginErrorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get loginErrorTooManyAttempts;

  /// No description provided for @loginErrorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get loginErrorTryAgain;

  /// No description provided for @signupCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupCreateAccount;

  /// No description provided for @signupJoinToday.
  ///
  /// In en, this message translates to:
  /// **'Join TeeStats today'**
  String get signupJoinToday;

  /// No description provided for @signupFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signupFullName;

  /// No description provided for @signupEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get signupEnterYourName;

  /// No description provided for @signupEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmail;

  /// No description provided for @signupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPassword;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get signupEnterPassword;

  /// No description provided for @signupMinimumChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get signupMinimumChars;

  /// No description provided for @signupConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get signupConfirmYourPassword;

  /// No description provided for @signupPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupPasswordsDoNotMatch;

  /// No description provided for @signupPasswordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength: {label}'**
  String signupPasswordStrength(String label);

  /// No description provided for @signupPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get signupPasswordWeak;

  /// No description provided for @signupPasswordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get signupPasswordFair;

  /// No description provided for @signupPasswordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get signupPasswordGood;

  /// No description provided for @signupPasswordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get signupPasswordStrong;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupErrorAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get signupErrorAccountExists;

  /// No description provided for @signupErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get signupErrorInvalidEmail;

  /// No description provided for @signupErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get signupErrorWeakPassword;

  /// No description provided for @signupErrorNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email sign-up is not enabled.'**
  String get signupErrorNotEnabled;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Swing. Track. Win.'**
  String get onboardingTagline;

  /// No description provided for @onboardingScoreTrackingTag.
  ///
  /// In en, this message translates to:
  /// **'SCORE TRACKING'**
  String get onboardingScoreTrackingTag;

  /// No description provided for @onboardingTrackEveryRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Every\nRound'**
  String get onboardingTrackEveryRoundTitle;

  /// No description provided for @onboardingScoreTrackingBody.
  ///
  /// In en, this message translates to:
  /// **'GPS-powered scoring for every hole. Your complete round history, always in your pocket.'**
  String get onboardingScoreTrackingBody;

  /// No description provided for @onboardingPerformanceTag.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE'**
  String get onboardingPerformanceTag;

  /// No description provided for @onboardingGolfDNATitle.
  ///
  /// In en, this message translates to:
  /// **'Know Your\nGolf DNA'**
  String get onboardingGolfDNATitle;

  /// No description provided for @onboardingPerformanceBody.
  ///
  /// In en, this message translates to:
  /// **'Fairways hit, GIR, putts per round, handicap trends — pinpoint exactly where to improve.'**
  String get onboardingPerformanceBody;

  /// No description provided for @onboardingMultiplayerTag.
  ///
  /// In en, this message translates to:
  /// **'MULTIPLAYER'**
  String get onboardingMultiplayerTag;

  /// No description provided for @onboardingPlayTogetherTitle.
  ///
  /// In en, this message translates to:
  /// **'Play\nTogether'**
  String get onboardingPlayTogetherTitle;

  /// No description provided for @onboardingMultiplayerBody.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to a live group round. Real-time leaderboard, zero extra scorekeeping.'**
  String get onboardingMultiplayerBody;

  /// No description provided for @onboardingSocialTag.
  ///
  /// In en, this message translates to:
  /// **'SOCIAL'**
  String get onboardingSocialTag;

  /// No description provided for @onboardingFriendsLeaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends &\nLeaderboard'**
  String get onboardingFriendsLeaderboardTitle;

  /// No description provided for @onboardingSocialBody.
  ///
  /// In en, this message translates to:
  /// **'Connect with your golf crew. See who\'s on a hot streak and challenge them to beat you.'**
  String get onboardingSocialBody;

  /// No description provided for @onboardingAITag.
  ///
  /// In en, this message translates to:
  /// **'AI POWERED'**
  String get onboardingAITag;

  /// No description provided for @onboardingPersonalCaddieTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Personal\nCaddie'**
  String get onboardingPersonalCaddieTitle;

  /// No description provided for @onboardingAIBody.
  ///
  /// In en, this message translates to:
  /// **'After every round, Gemini AI analyses your stats and delivers coaching insights — strengths, weaknesses and a focus area to sharpen next time.'**
  String get onboardingAIBody;

  /// No description provided for @onboardingPoweredByGemini.
  ///
  /// In en, this message translates to:
  /// **'Powered by Google Gemini'**
  String get onboardingPoweredByGemini;

  /// No description provided for @homeReadyToPlay.
  ///
  /// In en, this message translates to:
  /// **'⛳  Ready to play?'**
  String get homeReadyToPlay;

  /// No description provided for @homeStartRound.
  ///
  /// In en, this message translates to:
  /// **'Start Round'**
  String get homeStartRound;

  /// No description provided for @homeTapToTeeOff.
  ///
  /// In en, this message translates to:
  /// **'Tap to tee off'**
  String get homeTapToTeeOff;

  /// No description provided for @homeGolfNews.
  ///
  /// In en, this message translates to:
  /// **'Golf News'**
  String get homeGolfNews;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeRecentRounds.
  ///
  /// In en, this message translates to:
  /// **'Recent Rounds'**
  String get homeRecentRounds;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @homeNoRoundsYet.
  ///
  /// In en, this message translates to:
  /// **'No rounds yet — start your first!'**
  String get homeNoRoundsYet;

  /// No description provided for @homeInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get homeInProgress;

  /// No description provided for @homeActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get homeActive;

  /// No description provided for @homeNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get homeNoLocation;

  /// No description provided for @homePerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get homePerformance;

  /// No description provided for @homeCompleteRoundsForStats.
  ///
  /// In en, this message translates to:
  /// **'Complete rounds to see your handicap and performance stats.'**
  String get homeCompleteRoundsForStats;

  /// No description provided for @homeHandicapIndex.
  ///
  /// In en, this message translates to:
  /// **'Handicap Index'**
  String get homeHandicapIndex;

  /// No description provided for @homeRoundsNeeded.
  ///
  /// In en, this message translates to:
  /// **'{n}/20 rounds'**
  String homeRoundsNeeded(int n);

  /// No description provided for @homeMoreRoundsToUnlock.
  ///
  /// In en, this message translates to:
  /// **'{n} more rounds to unlock your Handicap Index'**
  String homeMoreRoundsToUnlock(int n);

  /// No description provided for @homeFairwaysHit.
  ///
  /// In en, this message translates to:
  /// **'Fairways Hit'**
  String get homeFairwaysHit;

  /// No description provided for @homePar4And5.
  ///
  /// In en, this message translates to:
  /// **'Par 4 & 5 holes'**
  String get homePar4And5;

  /// No description provided for @homeGIR.
  ///
  /// In en, this message translates to:
  /// **'Greens in Reg.'**
  String get homeGIR;

  /// No description provided for @homeAllHoles.
  ///
  /// In en, this message translates to:
  /// **'All holes'**
  String get homeAllHoles;

  /// No description provided for @homeAvgPutts.
  ///
  /// In en, this message translates to:
  /// **'Avg Putts'**
  String get homeAvgPutts;

  /// No description provided for @homePerHole.
  ///
  /// In en, this message translates to:
  /// **'Per hole'**
  String get homePerHole;

  /// No description provided for @homeBirdies.
  ///
  /// In en, this message translates to:
  /// **'Birdies'**
  String get homeBirdies;

  /// No description provided for @homeAllRounds.
  ///
  /// In en, this message translates to:
  /// **'All rounds'**
  String get homeAllRounds;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get homeYesterday;

  /// No description provided for @homeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} days ago'**
  String homeDaysAgo(int n);

  /// No description provided for @homeWeekAgo.
  ///
  /// In en, this message translates to:
  /// **'1 week ago'**
  String get homeWeekAgo;

  /// No description provided for @homeTwoWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'2 weeks ago'**
  String get homeTwoWeeksAgo;

  /// No description provided for @homeThreeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'3 weeks ago'**
  String get homeThreeWeeksAgo;

  /// No description provided for @homeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} months ago'**
  String homeMonthsAgo(int n);

  /// No description provided for @homeInvitedToPlay.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to play'**
  String homeInvitedToPlay(String name);

  /// No description provided for @homeChangeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get homeChangeLocation;

  /// No description provided for @homeSearchCityOrArea.
  ///
  /// In en, this message translates to:
  /// **'Search a city or area'**
  String get homeSearchCityOrArea;

  /// No description provided for @homeLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dubai, London, New York…'**
  String get homeLocationHint;

  /// No description provided for @homeSearchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get homeSearchLocation;

  /// No description provided for @homeLocationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found. Try a different city name.'**
  String get homeLocationNotFound;

  /// No description provided for @homeUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get homeUseCurrentLocation;

  /// No description provided for @homeWelcomeTour.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TeeStats'**
  String get homeWelcomeTour;

  /// No description provided for @homeWelcomeTourBody.
  ///
  /// In en, this message translates to:
  /// **'This is your home — see recent rounds, performance and nearby courses at a glance.'**
  String get homeWelcomeTourBody;

  /// No description provided for @homeFriendsAndLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Friends & Leaderboard'**
  String get homeFriendsAndLeaderboard;

  /// No description provided for @homeFriendsAndLeaderboardBody.
  ///
  /// In en, this message translates to:
  /// **'Add golf buddies, accept friend requests, and compare scores on the leaderboard. A green dot appears when you have a pending request.'**
  String get homeFriendsAndLeaderboardBody;

  /// No description provided for @homeStartARound.
  ///
  /// In en, this message translates to:
  /// **'Start a Round'**
  String get homeStartARound;

  /// No description provided for @homeStartARoundBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the green button anytime to start scoring a new round at any course.'**
  String get homeStartARoundBody;

  /// No description provided for @homeYourActiveRound.
  ///
  /// In en, this message translates to:
  /// **'Your Active Round'**
  String get homeYourActiveRound;

  /// No description provided for @homeResumeRoundBody.
  ///
  /// In en, this message translates to:
  /// **'If you leave mid-round, it\'s saved here. Tap Resume to pick up where you left off.'**
  String get homeResumeRoundBody;

  /// No description provided for @homeRoundHistory.
  ///
  /// In en, this message translates to:
  /// **'Round History'**
  String get homeRoundHistory;

  /// No description provided for @homeRoundHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'All your completed rounds live here. Tap any round for a full hole-by-hole breakdown.'**
  String get homeRoundHistoryBody;

  /// No description provided for @homeYourStats.
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get homeYourStats;

  /// No description provided for @homeYourStatsBody.
  ///
  /// In en, this message translates to:
  /// **'Track your handicap trend, scoring patterns, GIR, fairways and strokes gained over time.'**
  String get homeYourStatsBody;

  /// No description provided for @homeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get homeYourProfile;

  /// No description provided for @homeYourProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Set your handicap goal, pick an avatar, and view your Golf DNA and Play Style identity.'**
  String get homeYourProfileBody;

  /// No description provided for @homeQuickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get homeQuickStats;

  /// No description provided for @homeQuickStatsBody.
  ///
  /// In en, this message translates to:
  /// **'Live averages across all your rounds — fairways, GIR, putts and birdies per round.'**
  String get homeQuickStatsBody;

  /// No description provided for @homeNearbyCourses.
  ///
  /// In en, this message translates to:
  /// **'Nearby Courses'**
  String get homeNearbyCourses;

  /// No description provided for @homeNearbyCoursesBody.
  ///
  /// In en, this message translates to:
  /// **'Golf courses near your location. Tap any course to start a round there instantly.'**
  String get homeNearbyCoursesBody;

  /// No description provided for @roundsMyRounds.
  ///
  /// In en, this message translates to:
  /// **'My Rounds'**
  String get roundsMyRounds;

  /// No description provided for @roundsRoundsTab.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get roundsRoundsTab;

  /// No description provided for @roundsPracticeTab.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get roundsPracticeTab;

  /// No description provided for @roundsTournamentsTab.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get roundsTournamentsTab;

  /// No description provided for @roundsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Round History'**
  String get roundsHistoryTitle;

  /// No description provided for @roundsHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All completed rounds are here. Tap any round for a full hole-by-hole breakdown and stats.'**
  String get roundsHistorySubtitle;

  /// No description provided for @roundsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Round in Progress'**
  String get roundsInProgress;

  /// No description provided for @roundsHolesProgress.
  ///
  /// In en, this message translates to:
  /// **'{played}/{total} holes'**
  String roundsHolesProgress(int played, int total);

  /// No description provided for @roundsNoRoundsYet.
  ///
  /// In en, this message translates to:
  /// **'No rounds yet'**
  String get roundsNoRoundsYet;

  /// No description provided for @roundsStartFirst.
  ///
  /// In en, this message translates to:
  /// **'Start your first round from the Home tab'**
  String get roundsStartFirst;

  /// No description provided for @roundsOrScanScorecard.
  ///
  /// In en, this message translates to:
  /// **'or scan a paper scorecard'**
  String get roundsOrScanScorecard;

  /// No description provided for @roundsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Round?'**
  String get roundsDeleteTitle;

  /// No description provided for @roundsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your round at {courseName}?'**
  String roundsDeleteConfirm(String courseName);

  /// No description provided for @roundsBirdies.
  ///
  /// In en, this message translates to:
  /// **'Birdies'**
  String get roundsBirdies;

  /// No description provided for @roundsPars.
  ///
  /// In en, this message translates to:
  /// **'Pars'**
  String get roundsPars;

  /// No description provided for @roundsBogeys.
  ///
  /// In en, this message translates to:
  /// **'Bogeys'**
  String get roundsBogeys;

  /// No description provided for @roundsPutts.
  ///
  /// In en, this message translates to:
  /// **'Putts'**
  String get roundsPutts;

  /// No description provided for @roundsFIR.
  ///
  /// In en, this message translates to:
  /// **'FIR'**
  String get roundsFIR;

  /// No description provided for @roundSummaryComplete.
  ///
  /// In en, this message translates to:
  /// **'Round Complete!'**
  String get roundSummaryComplete;

  /// No description provided for @roundSummaryScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get roundSummaryScore;

  /// No description provided for @roundSummaryVsPar.
  ///
  /// In en, this message translates to:
  /// **'vs Par'**
  String get roundSummaryVsPar;

  /// No description provided for @roundSummaryHoles.
  ///
  /// In en, this message translates to:
  /// **'Holes'**
  String get roundSummaryHoles;

  /// No description provided for @roundSummaryBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get roundSummaryBackToHome;

  /// No description provided for @roundSummaryEven.
  ///
  /// In en, this message translates to:
  /// **'Even'**
  String get roundSummaryEven;

  /// No description provided for @roundDetailScorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get roundDetailScorecard;

  /// No description provided for @roundDetailShotTrails.
  ///
  /// In en, this message translates to:
  /// **'Shot Trails'**
  String get roundDetailShotTrails;

  /// No description provided for @roundDetailHole.
  ///
  /// In en, this message translates to:
  /// **'Hole'**
  String get roundDetailHole;

  /// No description provided for @roundDetailPar.
  ///
  /// In en, this message translates to:
  /// **'Par'**
  String get roundDetailPar;

  /// No description provided for @roundDetailGIR.
  ///
  /// In en, this message translates to:
  /// **'GIR'**
  String get roundDetailGIR;

  /// No description provided for @roundDetailTotal.
  ///
  /// In en, this message translates to:
  /// **'TOT'**
  String get roundDetailTotal;

  /// No description provided for @roundDetailShare.
  ///
  /// In en, this message translates to:
  /// **'Share scorecard'**
  String get roundDetailShare;

  /// No description provided for @roundDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete round'**
  String get roundDetailDelete;

  /// No description provided for @roundDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Round?'**
  String get roundDetailDeleteTitle;

  /// No description provided for @roundDetailDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove your round at {courseName}.'**
  String roundDetailDeleteConfirm(String courseName);

  /// No description provided for @startRoundPickCourse.
  ///
  /// In en, this message translates to:
  /// **'📍  Pick your course'**
  String get startRoundPickCourse;

  /// No description provided for @startRoundWherePlaying.
  ///
  /// In en, this message translates to:
  /// **'Where are\nyou playing?'**
  String get startRoundWherePlaying;

  /// No description provided for @startRoundSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a nearby golf course'**
  String get startRoundSearchHint;

  /// No description provided for @startRoundCourseName.
  ///
  /// In en, this message translates to:
  /// **'Course Name'**
  String get startRoundCourseName;

  /// No description provided for @startRoundEnterCourseName.
  ///
  /// In en, this message translates to:
  /// **'Enter course name'**
  String get startRoundEnterCourseName;

  /// No description provided for @startRoundFetchingTeeData.
  ///
  /// In en, this message translates to:
  /// **'Fetching tee data…'**
  String get startRoundFetchingTeeData;

  /// No description provided for @startRoundSelectTee.
  ///
  /// In en, this message translates to:
  /// **'SELECT TEE'**
  String get startRoundSelectTee;

  /// No description provided for @startRoundCourseRating.
  ///
  /// In en, this message translates to:
  /// **'COURSE RATING (OPTIONAL)'**
  String get startRoundCourseRating;

  /// No description provided for @startRoundRatingForHandicap.
  ///
  /// In en, this message translates to:
  /// **'For an accurate USGA Handicap Index'**
  String get startRoundRatingForHandicap;

  /// No description provided for @startRoundCourseRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Course Rating'**
  String get startRoundCourseRatingLabel;

  /// No description provided for @startRoundCourseRatingHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 72.5'**
  String get startRoundCourseRatingHint;

  /// No description provided for @startRoundSlopeRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Slope Rating'**
  String get startRoundSlopeRatingLabel;

  /// No description provided for @startRoundSlopeRatingHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 113'**
  String get startRoundSlopeRatingHint;

  /// No description provided for @startRoundSlopeError.
  ///
  /// In en, this message translates to:
  /// **'55–155'**
  String get startRoundSlopeError;

  /// No description provided for @startRoundNumberOfHoles.
  ///
  /// In en, this message translates to:
  /// **'NUMBER OF HOLES'**
  String get startRoundNumberOfHoles;

  /// No description provided for @startRoundHoles.
  ///
  /// In en, this message translates to:
  /// **'Holes'**
  String get startRoundHoles;

  /// No description provided for @startRoundInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'INVITE FRIENDS (MAX 3)'**
  String get startRoundInviteFriends;

  /// No description provided for @startRoundSearchFriends.
  ///
  /// In en, this message translates to:
  /// **'Search friends…'**
  String get startRoundSearchFriends;

  /// No description provided for @startRoundNoFriends.
  ///
  /// In en, this message translates to:
  /// **'No friends yet.'**
  String get startRoundNoFriends;

  /// No description provided for @startRoundNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches.'**
  String get startRoundNoMatches;

  /// No description provided for @startRoundFriendsInvited.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 friend will be invited} other{{count} friends will be invited}}'**
  String startRoundFriendsInvited(int count);

  /// No description provided for @startRoundTeeOff.
  ///
  /// In en, this message translates to:
  /// **'Tee Off!'**
  String get startRoundTeeOff;

  /// No description provided for @startRoundNoCoursesFound.
  ///
  /// In en, this message translates to:
  /// **'No golf courses found nearby'**
  String get startRoundNoCoursesFound;

  /// No description provided for @startRoundNoHoleData.
  ///
  /// In en, this message translates to:
  /// **'No hole data found for this course.'**
  String get startRoundNoHoleData;

  /// No description provided for @startRoundUploadScorecard.
  ///
  /// In en, this message translates to:
  /// **'Upload Scorecard'**
  String get startRoundUploadScorecard;

  /// No description provided for @startRoundError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String startRoundError(String error);

  /// No description provided for @scorecardScoringARound.
  ///
  /// In en, this message translates to:
  /// **'Scoring a Round'**
  String get scorecardScoringARound;

  /// No description provided for @scorecardInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your score, putts, fairway and GIR for each hole. Tap the club to track your club selection.'**
  String get scorecardInstructions;

  /// No description provided for @scorecardHole.
  ///
  /// In en, this message translates to:
  /// **'Hole'**
  String get scorecardHole;

  /// No description provided for @scorecardPlayingWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Playing with friends'**
  String get scorecardPlayingWithFriends;

  /// No description provided for @scorecardScore.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get scorecardScore;

  /// No description provided for @scorecardPutts.
  ///
  /// In en, this message translates to:
  /// **'PUTTS'**
  String get scorecardPutts;

  /// No description provided for @scorecardFairwayHit.
  ///
  /// In en, this message translates to:
  /// **'FAIRWAY HIT'**
  String get scorecardFairwayHit;

  /// No description provided for @scorecardGIR.
  ///
  /// In en, this message translates to:
  /// **'GREEN IN REGULATION'**
  String get scorecardGIR;

  /// No description provided for @scorecardTrackShots.
  ///
  /// In en, this message translates to:
  /// **'Track shots'**
  String get scorecardTrackShots;

  /// No description provided for @scorecardTeeSet.
  ///
  /// In en, this message translates to:
  /// **'Tee set'**
  String get scorecardTeeSet;

  /// No description provided for @scorecardShotsTracked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shot tracked} other{{count} shots tracked}}'**
  String scorecardShotsTracked(int count);

  /// No description provided for @scorecardClub.
  ///
  /// In en, this message translates to:
  /// **'CLUB'**
  String get scorecardClub;

  /// No description provided for @scorecardScorecardLabel.
  ///
  /// In en, this message translates to:
  /// **'SCORECARD'**
  String get scorecardScorecardLabel;

  /// No description provided for @scorecardLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Round?'**
  String get scorecardLeaveTitle;

  /// No description provided for @scorecardLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved automatically.\nYou can resume this round from the home screen.'**
  String get scorecardLeaveBody;

  /// No description provided for @scorecardSaveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save & Exit'**
  String get scorecardSaveAndExit;

  /// No description provided for @scorecardKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep Playing'**
  String get scorecardKeepPlaying;

  /// No description provided for @scorecardAbandon.
  ///
  /// In en, this message translates to:
  /// **'Abandon'**
  String get scorecardAbandon;

  /// No description provided for @scorecardNextHole.
  ///
  /// In en, this message translates to:
  /// **'Next Hole'**
  String get scorecardNextHole;

  /// No description provided for @scorecardFinishRound.
  ///
  /// In en, this message translates to:
  /// **'Finish Round'**
  String get scorecardFinishRound;

  /// No description provided for @scorecardAICaddy.
  ///
  /// In en, this message translates to:
  /// **'AI CADDY'**
  String get scorecardAICaddy;

  /// No description provided for @scorecardTipPar3.
  ///
  /// In en, this message translates to:
  /// **'Par 3: commit to one club and trust the swing.'**
  String get scorecardTipPar3;

  /// No description provided for @scorecardTipInsightsUnlock.
  ///
  /// In en, this message translates to:
  /// **'Play your game — insights unlock after 3 holes.'**
  String get scorecardTipInsightsUnlock;

  /// No description provided for @scorecardTipAvgPutts.
  ///
  /// In en, this message translates to:
  /// **'Averaging {avgPutts} putts — focus on lag putting from distance.'**
  String scorecardTipAvgPutts(String avgPutts);

  /// No description provided for @scorecardTipFairways.
  ///
  /// In en, this message translates to:
  /// **'Only {fwhitPercent}% fairways hit — consider a 3-wood off the tee.'**
  String scorecardTipFairways(String fwhitPercent);

  /// No description provided for @scorecardTipApproach.
  ///
  /// In en, this message translates to:
  /// **'Approaches struggling — aim for the fat of the green today.'**
  String get scorecardTipApproach;

  /// No description provided for @scorecardTipSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid round so far — keep the same rhythm and tempo.'**
  String get scorecardTipSolid;

  /// No description provided for @scorecardYds.
  ///
  /// In en, this message translates to:
  /// **'YDS'**
  String get scorecardYds;

  /// No description provided for @scorecardPlaysLike.
  ///
  /// In en, this message translates to:
  /// **'PLAYS LIKE {distance} YDS'**
  String scorecardPlaysLike(String distance);

  /// No description provided for @scorecardEagle.
  ///
  /// In en, this message translates to:
  /// **'Eagle'**
  String get scorecardEagle;

  /// No description provided for @scorecardAlbatross.
  ///
  /// In en, this message translates to:
  /// **'Albatross'**
  String get scorecardAlbatross;

  /// No description provided for @scorecardBirdie.
  ///
  /// In en, this message translates to:
  /// **'Birdie'**
  String get scorecardBirdie;

  /// No description provided for @scorecardPar.
  ///
  /// In en, this message translates to:
  /// **'Par'**
  String get scorecardPar;

  /// No description provided for @scorecardBogey.
  ///
  /// In en, this message translates to:
  /// **'Bogey'**
  String get scorecardBogey;

  /// No description provided for @scorecardDouble.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get scorecardDouble;

  /// No description provided for @scorecardEditHole.
  ///
  /// In en, this message translates to:
  /// **'Edit Hole {hole}'**
  String scorecardEditHole(int hole);

  /// No description provided for @scorecardErrorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String scorecardErrorSaving(String error);

  /// No description provided for @scorecardOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get scorecardOn;

  /// No description provided for @scorecardOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get scorecardOff;

  /// No description provided for @statsHub.
  ///
  /// In en, this message translates to:
  /// **'Your Stats Hub'**
  String get statsHub;

  /// No description provided for @statsPlayMoreRounds.
  ///
  /// In en, this message translates to:
  /// **'Play more rounds to unlock trend charts, strokes gained and score distribution analysis.'**
  String get statsPlayMoreRounds;

  /// No description provided for @statsHandicapIndex.
  ///
  /// In en, this message translates to:
  /// **'Handicap Index'**
  String get statsHandicapIndex;

  /// No description provided for @statsBasedOnRounds.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Based on 1 round} other{Based on {n} rounds}}'**
  String statsBasedOnRounds(int n);

  /// No description provided for @statsCompleteToCalculate.
  ///
  /// In en, this message translates to:
  /// **'Complete rounds to calculate'**
  String get statsCompleteToCalculate;

  /// No description provided for @statsAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg Score'**
  String get statsAvgScore;

  /// No description provided for @statsBestRound.
  ///
  /// In en, this message translates to:
  /// **'Best Round'**
  String get statsBestRound;

  /// No description provided for @statsTotalRounds.
  ///
  /// In en, this message translates to:
  /// **'Total Rounds'**
  String get statsTotalRounds;

  /// No description provided for @statsTotalBirdies.
  ///
  /// In en, this message translates to:
  /// **'Total Birdies'**
  String get statsTotalBirdies;

  /// No description provided for @statsScoreDistribution.
  ///
  /// In en, this message translates to:
  /// **'Score Distribution'**
  String get statsScoreDistribution;

  /// No description provided for @statsEagles.
  ///
  /// In en, this message translates to:
  /// **'Eagles'**
  String get statsEagles;

  /// No description provided for @statsBirdies.
  ///
  /// In en, this message translates to:
  /// **'Birdies'**
  String get statsBirdies;

  /// No description provided for @statsPars.
  ///
  /// In en, this message translates to:
  /// **'Pars'**
  String get statsPars;

  /// No description provided for @statsBogeys.
  ///
  /// In en, this message translates to:
  /// **'Bogeys'**
  String get statsBogeys;

  /// No description provided for @statsDoublePlus.
  ///
  /// In en, this message translates to:
  /// **'Double+'**
  String get statsDoublePlus;

  /// No description provided for @statsScoreVsPar.
  ///
  /// In en, this message translates to:
  /// **'Score vs Par (Last {n} Rounds)'**
  String statsScoreVsPar(int n);

  /// No description provided for @statsOldestToRecent.
  ///
  /// In en, this message translates to:
  /// **'Oldest → Most Recent'**
  String get statsOldestToRecent;

  /// No description provided for @statsHandicapTrend.
  ///
  /// In en, this message translates to:
  /// **'Handicap Trend'**
  String get statsHandicapTrend;

  /// No description provided for @statsGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {n}'**
  String statsGoal(String n);

  /// No description provided for @statsLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest: {n}'**
  String statsLatest(String n);

  /// No description provided for @statsFairwaysHit.
  ///
  /// In en, this message translates to:
  /// **'Fairways Hit'**
  String get statsFairwaysHit;

  /// No description provided for @statsGIR.
  ///
  /// In en, this message translates to:
  /// **'Greens in Regulation'**
  String get statsGIR;

  /// No description provided for @statsAvgPuttsPerHole.
  ///
  /// In en, this message translates to:
  /// **'Avg Putts / Hole'**
  String get statsAvgPuttsPerHole;

  /// No description provided for @statsClubStats.
  ///
  /// In en, this message translates to:
  /// **'Club Stats'**
  String get statsClubStats;

  /// No description provided for @statsClubStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Score vs par & avg putts per club'**
  String get statsClubStatsSubtitle;

  /// No description provided for @statsClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get statsClub;

  /// No description provided for @statsHoles.
  ///
  /// In en, this message translates to:
  /// **'Holes'**
  String get statsHoles;

  /// No description provided for @statsAvgPlusMinus.
  ///
  /// In en, this message translates to:
  /// **'Avg ±Par'**
  String get statsAvgPlusMinus;

  /// No description provided for @statsAvgPutts.
  ///
  /// In en, this message translates to:
  /// **'Avg Putts'**
  String get statsAvgPutts;

  /// No description provided for @statsStrokesGained.
  ///
  /// In en, this message translates to:
  /// **'Strokes Gained'**
  String get statsStrokesGained;

  /// No description provided for @statsVsScratch.
  ///
  /// In en, this message translates to:
  /// **'vs scratch golfer baseline'**
  String get statsVsScratch;

  /// No description provided for @statsOffTheTee.
  ///
  /// In en, this message translates to:
  /// **'Off the Tee'**
  String get statsOffTheTee;

  /// No description provided for @statsApproach.
  ///
  /// In en, this message translates to:
  /// **'Approach'**
  String get statsApproach;

  /// No description provided for @statsAroundGreen.
  ///
  /// In en, this message translates to:
  /// **'Around Green'**
  String get statsAroundGreen;

  /// No description provided for @statsPutting.
  ///
  /// In en, this message translates to:
  /// **'Putting'**
  String get statsPutting;

  /// No description provided for @statsBetterThanAvg.
  ///
  /// In en, this message translates to:
  /// **'Better\nthan avg'**
  String get statsBetterThanAvg;

  /// No description provided for @statsPressureScore.
  ///
  /// In en, this message translates to:
  /// **'Pressure Score'**
  String get statsPressureScore;

  /// No description provided for @statsPressureResilience.
  ///
  /// In en, this message translates to:
  /// **'Resilience'**
  String get statsPressureResilience;

  /// No description provided for @statsPressureUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Play {count} more round(s) to unlock your mental game profile'**
  String statsPressureUnlockHint(int count);

  /// No description provided for @statsPressureOpeningHole.
  ///
  /// In en, this message translates to:
  /// **'Opening Hole'**
  String get statsPressureOpeningHole;

  /// No description provided for @statsPressureBirdieHangover.
  ///
  /// In en, this message translates to:
  /// **'Birdie Hangover'**
  String get statsPressureBirdieHangover;

  /// No description provided for @statsPressureBackNine.
  ///
  /// In en, this message translates to:
  /// **'Back-Nine Decay'**
  String get statsPressureBackNine;

  /// No description provided for @statsPressureFinishingStretch.
  ///
  /// In en, this message translates to:
  /// **'Finishing Stretch'**
  String get statsPressureFinishingStretch;

  /// No description provided for @statsPressureThreePutt.
  ///
  /// In en, this message translates to:
  /// **'Three-Putt Timing'**
  String get statsPressureThreePutt;

  /// No description provided for @statsPressureTopDrill.
  ///
  /// In en, this message translates to:
  /// **'Top Drill'**
  String get statsPressureTopDrill;

  /// No description provided for @statsPressureInsufficientData.
  ///
  /// In en, this message translates to:
  /// **'Low data'**
  String get statsPressureInsufficientData;

  /// No description provided for @tournamentNoTournaments.
  ///
  /// In en, this message translates to:
  /// **'No tournaments yet'**
  String get tournamentNoTournaments;

  /// No description provided for @tournamentCreateInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New Tournament\" to create one,\nthen start rounds to score for the tournament.'**
  String get tournamentCreateInstructions;

  /// No description provided for @tournamentNew.
  ///
  /// In en, this message translates to:
  /// **'New Tournament'**
  String get tournamentNew;

  /// No description provided for @tournamentStartInstructions.
  ///
  /// In en, this message translates to:
  /// **'Create a tournament first, then use the ＋ FAB on the home screen to start a tournament round.'**
  String get tournamentStartInstructions;

  /// No description provided for @tournamentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Tournament?'**
  String get tournamentDeleteTitle;

  /// No description provided for @tournamentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"? The rounds themselves will not be deleted.'**
  String tournamentDeleteConfirm(String name);

  /// No description provided for @tournamentRoundByRound.
  ///
  /// In en, this message translates to:
  /// **'Round by Round'**
  String get tournamentRoundByRound;

  /// No description provided for @tournamentVsPar.
  ///
  /// In en, this message translates to:
  /// **'vs Par'**
  String get tournamentVsPar;

  /// No description provided for @tournamentRoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get tournamentRoundsLabel;

  /// No description provided for @tournamentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Tournament Name'**
  String get tournamentNameLabel;

  /// No description provided for @tournamentNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Club Championship 2026'**
  String get tournamentNameHint;

  /// No description provided for @tournamentCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Tournament'**
  String get tournamentCreate;

  /// No description provided for @tournamentRoundsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 round} other{{n} rounds}}'**
  String tournamentRoundsCount(int n);

  /// No description provided for @tournamentRunning.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get tournamentRunning;

  /// No description provided for @practiceNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No practice sessions yet'**
  String get practiceNoSessions;

  /// No description provided for @practiceStartInstructions.
  ///
  /// In en, this message translates to:
  /// **'Start a round to score holes,\nor log range and short-game sessions.'**
  String get practiceStartInstructions;

  /// No description provided for @practiceLogSession.
  ///
  /// In en, this message translates to:
  /// **'Log Session'**
  String get practiceLogSession;

  /// No description provided for @practiceScoredRound.
  ///
  /// In en, this message translates to:
  /// **'Scored Round'**
  String get practiceScoredRound;

  /// No description provided for @practiceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Session?'**
  String get practiceDeleteTitle;

  /// No description provided for @practiceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This practice session will be permanently removed.'**
  String get practiceDeleteConfirm;

  /// No description provided for @practiceLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Practice Session'**
  String get practiceLogTitle;

  /// No description provided for @practiceType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get practiceType;

  /// No description provided for @practiceBallsHit.
  ///
  /// In en, this message translates to:
  /// **'Balls hit'**
  String get practiceBallsHit;

  /// No description provided for @practiceDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get practiceDuration;

  /// No description provided for @practiceNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get practiceNotes;

  /// No description provided for @practiceNotesHint.
  ///
  /// In en, this message translates to:
  /// **'What did you work on?'**
  String get practiceNotesHint;

  /// No description provided for @practiceSave.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get practiceSave;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendsLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get friendsLeaderboard;

  /// No description provided for @friendsNoFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsNoFriendsYet;

  /// No description provided for @friendsEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a friend\'s email above to add them'**
  String get friendsEnterEmail;

  /// No description provided for @friendsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by email address…'**
  String get friendsSearchHint;

  /// No description provided for @friendsPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get friendsPendingRequests;

  /// No description provided for @friendsWantsToBeF.
  ///
  /// In en, this message translates to:
  /// **'Wants to be friends'**
  String get friendsWantsToBeF;

  /// No description provided for @friendsRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get friendsRequestSent;

  /// No description provided for @friendsAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept Request'**
  String get friendsAcceptRequest;

  /// No description provided for @friendsAlreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'Already Friends'**
  String get friendsAlreadyFriends;

  /// No description provided for @friendsAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get friendsAddFriend;

  /// No description provided for @friendsNoLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard yet'**
  String get friendsNoLeaderboard;

  /// No description provided for @friendsAddToCompare.
  ///
  /// In en, this message translates to:
  /// **'Add friends to compare scores'**
  String get friendsAddToCompare;

  /// No description provided for @friendsHandicap.
  ///
  /// In en, this message translates to:
  /// **'Handicap'**
  String get friendsHandicap;

  /// No description provided for @friendsAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg Score'**
  String get friendsAvgScore;

  /// No description provided for @friendsYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get friendsYou;

  /// No description provided for @notifPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Notifications'**
  String get notifPrefsTitle;

  /// No description provided for @notifPrefsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered alerts for your game'**
  String get notifPrefsSubtitle;

  /// No description provided for @notifPrefsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION TYPES'**
  String get notifPrefsSectionTitle;

  /// No description provided for @notifPrefsPracticeReminders.
  ///
  /// In en, this message translates to:
  /// **'Practice Reminders'**
  String get notifPrefsPracticeReminders;

  /// No description provided for @notifPrefsPracticeDesc.
  ///
  /// In en, this message translates to:
  /// **'AI-tailored drills for your weakest areas'**
  String get notifPrefsPracticeDesc;

  /// No description provided for @notifPrefsResumeRound.
  ///
  /// In en, this message translates to:
  /// **'Resume Round'**
  String get notifPrefsResumeRound;

  /// No description provided for @notifPrefsResumeDesc.
  ///
  /// In en, this message translates to:
  /// **'Nudges to complete rounds you left unfinished'**
  String get notifPrefsResumeDesc;

  /// No description provided for @notifPrefsPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance Insights'**
  String get notifPrefsPerformance;

  /// No description provided for @notifPrefsPerformanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Celebrate improvement streaks and trends'**
  String get notifPrefsPerformanceDesc;

  /// No description provided for @notifPrefsTeeTime.
  ///
  /// In en, this message translates to:
  /// **'Tee Time Reminders'**
  String get notifPrefsTeeTime;

  /// No description provided for @notifPrefsTeeTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Alerts before upcoming tee times'**
  String get notifPrefsTeeTimeDesc;

  /// No description provided for @notifPrefsSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved'**
  String get notifPrefsSaved;

  /// No description provided for @notifPrefsPersonalised.
  ///
  /// In en, this message translates to:
  /// **'Notifications are personalised based on your\nrecent rounds and performance trends.'**
  String get notifPrefsPersonalised;

  /// No description provided for @notifPrefsAIDriven.
  ///
  /// In en, this message translates to:
  /// **'✨ AI-Driven Alerts'**
  String get notifPrefsAIDriven;

  /// No description provided for @notifPrefsSmartDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart notifications\ntailored to your golf game'**
  String get notifPrefsSmartDesc;

  /// No description provided for @notifPrefsExplanation.
  ///
  /// In en, this message translates to:
  /// **'TeeStats analyses your rounds, practice habits, and performance trends to send notifications that actually help your game.'**
  String get notifPrefsExplanation;

  /// No description provided for @notifPrefsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get notifPrefsSave;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make It Yours'**
  String get profileSubtitle;

  /// No description provided for @profileDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your handicap goal, pick an avatar, and explore your Golf DNA and Play Style.'**
  String get profileDescription;

  /// No description provided for @profileGolfer.
  ///
  /// In en, this message translates to:
  /// **'Golfer'**
  String get profileGolfer;

  /// No description provided for @profileGolfPlaces.
  ///
  /// In en, this message translates to:
  /// **'Golf Places'**
  String get profileGolfPlaces;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// No description provided for @profileSmartNotifications.
  ///
  /// In en, this message translates to:
  /// **'Smart Notifications'**
  String get profileSmartNotifications;

  /// No description provided for @profileAchievementsSection.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENTS'**
  String get profileAchievementsSection;

  /// No description provided for @profileRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get profileRounds;

  /// No description provided for @profileHandicap.
  ///
  /// In en, this message translates to:
  /// **'Handicap'**
  String get profileHandicap;

  /// No description provided for @profileBirdies.
  ///
  /// In en, this message translates to:
  /// **'Birdies'**
  String get profileBirdies;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccount;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'TeeStats v{version}'**
  String profileVersion(String version);

  /// No description provided for @profileCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} TeeStats. All rights reserved.'**
  String profileCopyright(String year);

  /// No description provided for @profileHandicapGoal.
  ///
  /// In en, this message translates to:
  /// **'Handicap Goal'**
  String get profileHandicapGoal;

  /// No description provided for @profileHandicapGoalDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a target handicap index to track on your trend chart.'**
  String get profileHandicapGoalDesc;

  /// No description provided for @profileTargetPrefix.
  ///
  /// In en, this message translates to:
  /// **'Target: {value}'**
  String profileTargetPrefix(String value);

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — tap to set'**
  String get profileNotSet;

  /// No description provided for @profileClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get profileClear;

  /// No description provided for @profileSaveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get profileSaveGoal;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the login screen.'**
  String get profileSignOutBody;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all your golf data including rounds, stats, and achievements.'**
  String get profileDeleteBody;

  /// No description provided for @profileDeleteAreYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get profileDeleteAreYouSure;

  /// No description provided for @profileDeleteRoundsItem.
  ///
  /// In en, this message translates to:
  /// **'All your rounds and scorecards'**
  String get profileDeleteRoundsItem;

  /// No description provided for @profileDeleteStatsItem.
  ///
  /// In en, this message translates to:
  /// **'Stats, handicap history and achievements'**
  String get profileDeleteStatsItem;

  /// No description provided for @profileDeleteProfileItem.
  ///
  /// In en, this message translates to:
  /// **'Your profile and preferences'**
  String get profileDeleteProfileItem;

  /// No description provided for @profileDeleteNotificationsItem.
  ///
  /// In en, this message translates to:
  /// **'Smart notifications and tee times'**
  String get profileDeleteNotificationsItem;

  /// No description provided for @profileDeleteCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get profileDeleteCannotUndo;

  /// No description provided for @profileDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get profileDeleteButton;

  /// No description provided for @profileKeepButton.
  ///
  /// In en, this message translates to:
  /// **'Keep My Account'**
  String get profileKeepButton;

  /// No description provided for @profileDeletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get profileDeletingAccount;

  /// No description provided for @profileReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign out and sign back in before deleting your account.'**
  String get profileReauthRequired;

  /// No description provided for @profileSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get profileSomethingWrong;

  /// No description provided for @profileContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileContinue;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get profileDisplayName;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// No description provided for @profileChooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get profileChooseAvatar;

  /// No description provided for @profileSelectPresetAvatar.
  ///
  /// In en, this message translates to:
  /// **'Select a preset avatar'**
  String get profileSelectPresetAvatar;

  /// No description provided for @profileRemoveAvatar.
  ///
  /// In en, this message translates to:
  /// **'Remove Avatar'**
  String get profileRemoveAvatar;

  /// No description provided for @profileSaveAvatar.
  ///
  /// In en, this message translates to:
  /// **'Save Avatar'**
  String get profileSaveAvatar;

  /// No description provided for @shotTrackerTapToMark.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to mark the tee'**
  String get shotTrackerTapToMark;

  /// No description provided for @shotTrackerTeeMarked.
  ///
  /// In en, this message translates to:
  /// **'Tee marked · tap to track shots'**
  String get shotTrackerTeeMarked;

  /// No description provided for @shotTrackerShotsFromTee.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shot from tee} other{{count} shots from tee}}'**
  String shotTrackerShotsFromTee(int count);

  /// No description provided for @shotTrackerAcquiringGPS.
  ///
  /// In en, this message translates to:
  /// **'Acquiring GPS…'**
  String get shotTrackerAcquiringGPS;

  /// No description provided for @shotTrackerDistToPin.
  ///
  /// In en, this message translates to:
  /// **'{distance} yds to pin'**
  String shotTrackerDistToPin(String distance);

  /// No description provided for @shotTrackerLastShot.
  ///
  /// In en, this message translates to:
  /// **'Last shot: {distance} yds'**
  String shotTrackerLastShot(String distance);

  /// No description provided for @shotTrackerUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get shotTrackerUndo;

  /// No description provided for @shotTrackerFinishHole.
  ///
  /// In en, this message translates to:
  /// **'Finish Hole'**
  String get shotTrackerFinishHole;

  /// No description provided for @shotTrackerFinishHoleWithCount.
  ///
  /// In en, this message translates to:
  /// **'Finish Hole  ({count} shots)'**
  String shotTrackerFinishHoleWithCount(int count);

  /// No description provided for @shotTrackerNiceApproach.
  ///
  /// In en, this message translates to:
  /// **'Nice approach!'**
  String get shotTrackerNiceApproach;

  /// No description provided for @shotTrackerOnGreen.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the green — {shotCount}Ready to log putts for Hole {holeNumber}?'**
  String shotTrackerOnGreen(String shotCount, int holeNumber);

  /// No description provided for @shotTrackerNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get shotTrackerNotYet;

  /// No description provided for @shotTrackerLogPutts.
  ///
  /// In en, this message translates to:
  /// **'Log putts for Hole {holeNumber}'**
  String shotTrackerLogPutts(int holeNumber);

  /// No description provided for @swingAnalyzerTitle.
  ///
  /// In en, this message translates to:
  /// **'Swing Analyzer'**
  String get swingAnalyzerTitle;

  /// No description provided for @swingAnalyzerSaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get swingAnalyzerSaveToGallery;

  /// No description provided for @swingAnalyzerShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get swingAnalyzerShare;

  /// No description provided for @swingAnalyzerLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video…'**
  String get swingAnalyzerLoadingVideo;

  /// No description provided for @swingAnalyzerUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading video…'**
  String get swingAnalyzerUploading;

  /// No description provided for @swingAnalyzerAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing ball flight…'**
  String get swingAnalyzerAnalyzing;

  /// No description provided for @swingAnalyzerPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable — tap where the ball is'**
  String get swingAnalyzerPreviewUnavailable;

  /// No description provided for @swingAnalyzerTapBall.
  ///
  /// In en, this message translates to:
  /// **'Tap on the golf ball'**
  String get swingAnalyzerTapBall;

  /// No description provided for @swingAnalyzerReposition.
  ///
  /// In en, this message translates to:
  /// **'Tap to reposition'**
  String get swingAnalyzerReposition;

  /// No description provided for @swingAnalyzerSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get swingAnalyzerSkip;

  /// No description provided for @swingAnalyzerAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get swingAnalyzerAnalyze;

  /// No description provided for @swingAnalyzerAITracerTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Swing Tracer'**
  String get swingAnalyzerAITracerTitle;

  /// No description provided for @swingAnalyzerAITracerDesc.
  ///
  /// In en, this message translates to:
  /// **'Record or upload a golf swing video.\nGemini AI will track the ball and overlay a live tracer.'**
  String get swingAnalyzerAITracerDesc;

  /// No description provided for @swingAnalyzerButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze Swing'**
  String get swingAnalyzerButton;

  /// No description provided for @swingAnalyzerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get swingAnalyzerComingSoon;

  /// No description provided for @swingAnalyzerComingSoonMsg.
  ///
  /// In en, this message translates to:
  /// **'AI Swing Tracer is currently under development. Stay tuned for the update!'**
  String get swingAnalyzerComingSoonMsg;

  /// No description provided for @swingAnalyzerGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get swingAnalyzerGotIt;

  /// No description provided for @swingAnalyzerFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis Failed'**
  String get swingAnalyzerFailed;

  /// No description provided for @swingAnalyzerFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get swingAnalyzerFailedMsg;

  /// No description provided for @swingAnalyzerTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get swingAnalyzerTryAgain;

  /// No description provided for @swingAnalyzerRecording.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get swingAnalyzerRecording;

  /// No description provided for @swingAnalyzerBallNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Ball not detected in video'**
  String get swingAnalyzerBallNotDetected;

  /// No description provided for @swingAnalyzerNoVideoFile.
  ///
  /// In en, this message translates to:
  /// **'No video file to save'**
  String get swingAnalyzerNoVideoFile;

  /// No description provided for @swingAnalyzerVideoSaved.
  ///
  /// In en, this message translates to:
  /// **'Video saved to gallery'**
  String get swingAnalyzerVideoSaved;

  /// No description provided for @swingAnalyzerCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save video: {error}'**
  String swingAnalyzerCouldNotSave(String error);

  /// No description provided for @swingAnalyzerShareText.
  ///
  /// In en, this message translates to:
  /// **'Check out my swing trace from TeeStats! 🏌️'**
  String get swingAnalyzerShareText;

  /// No description provided for @swingAnalyzerShotAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Shot Analysis'**
  String get swingAnalyzerShotAnalysis;

  /// No description provided for @swingAnalyzerCarry.
  ///
  /// In en, this message translates to:
  /// **'Carry'**
  String get swingAnalyzerCarry;

  /// No description provided for @swingAnalyzerHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get swingAnalyzerHeight;

  /// No description provided for @swingAnalyzerLaunch.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get swingAnalyzerLaunch;

  /// No description provided for @swingAnalyzerPathNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Ball path not detected. Try better lighting or a closer angle.'**
  String get swingAnalyzerPathNotDetected;

  /// No description provided for @swingAnalyzerAnotherSwing.
  ///
  /// In en, this message translates to:
  /// **'Analyze Another Swing'**
  String get swingAnalyzerAnotherSwing;

  /// No description provided for @scorecardUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Your Scorecard'**
  String get scorecardUploadTitle;

  /// No description provided for @scorecardUploadDesc.
  ///
  /// In en, this message translates to:
  /// **'AI will extract hole-by-hole data including par, yardage, and handicap.'**
  String get scorecardUploadDesc;

  /// No description provided for @scorecardUploadChooseSource.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE SOURCE'**
  String get scorecardUploadChooseSource;

  /// No description provided for @scorecardUploadTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get scorecardUploadTakePhoto;

  /// No description provided for @scorecardUploadFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get scorecardUploadFromGallery;

  /// No description provided for @scorecardUploadAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing scorecard…'**
  String get scorecardUploadAnalyzing;

  /// No description provided for @scorecardUploadAnalyzingNote.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a few seconds'**
  String get scorecardUploadAnalyzingNote;

  /// No description provided for @scorecardUploadReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Scorecard'**
  String get scorecardUploadReviewTitle;

  /// No description provided for @scorecardUploadUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Scorecard'**
  String get scorecardUploadUploadTitle;

  /// No description provided for @scorecardUploadCourseName.
  ///
  /// In en, this message translates to:
  /// **'COURSE NAME'**
  String get scorecardUploadCourseName;

  /// No description provided for @scorecardUploadCourseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter course name'**
  String get scorecardUploadCourseNameHint;

  /// No description provided for @scorecardUploadCityState.
  ///
  /// In en, this message translates to:
  /// **'City, State'**
  String get scorecardUploadCityState;

  /// No description provided for @scorecardUploadSelectTee.
  ///
  /// In en, this message translates to:
  /// **'SELECT TEE'**
  String get scorecardUploadSelectTee;

  /// No description provided for @scorecardUploadRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get scorecardUploadRetake;

  /// No description provided for @scorecardUploadSaveUse.
  ///
  /// In en, this message translates to:
  /// **'Save & Use'**
  String get scorecardUploadSaveUse;

  /// No description provided for @scorecardUploadNoTeeData.
  ///
  /// In en, this message translates to:
  /// **'No tee data was extracted. Try a clearer photo.'**
  String get scorecardUploadNoTeeData;

  /// No description provided for @scorecardUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Extraction failed. Try a clearer photo.\n{error}'**
  String scorecardUploadFailed(String error);

  /// No description provided for @scorecardUploadRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get scorecardUploadRating;

  /// No description provided for @scorecardUploadSlope.
  ///
  /// In en, this message translates to:
  /// **'Slope'**
  String get scorecardUploadSlope;

  /// No description provided for @scorecardUploadHoleHeader.
  ///
  /// In en, this message translates to:
  /// **'HOLE'**
  String get scorecardUploadHoleHeader;

  /// No description provided for @scorecardUploadParHeader.
  ///
  /// In en, this message translates to:
  /// **'PAR'**
  String get scorecardUploadParHeader;

  /// No description provided for @scorecardUploadYdsHeader.
  ///
  /// In en, this message translates to:
  /// **'YDS'**
  String get scorecardUploadYdsHeader;

  /// No description provided for @scorecardUploadHcpHeader.
  ///
  /// In en, this message translates to:
  /// **'HCP'**
  String get scorecardUploadHcpHeader;

  /// No description provided for @scorecardUploadRatingFooter.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating}'**
  String scorecardUploadRatingFooter(String rating);

  /// No description provided for @scorecardUploadSlopeFooter.
  ///
  /// In en, this message translates to:
  /// **'Slope {slope}'**
  String scorecardUploadSlopeFooter(String slope);

  /// No description provided for @scorecardUploadValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter the course name.'**
  String get scorecardUploadValidation;

  /// No description provided for @scorecardUploadMissingScores.
  ///
  /// In en, this message translates to:
  /// **'Some Scores Missing'**
  String get scorecardUploadMissingScores;

  /// No description provided for @scorecardUploadMissingMsg.
  ///
  /// In en, this message translates to:
  /// **'A few holes still show 0. They\'ll be saved as 0 strokes — you can edit them after import.'**
  String get scorecardUploadMissingMsg;

  /// No description provided for @scorecardUploadImportAnyway.
  ///
  /// In en, this message translates to:
  /// **'Import Anyway'**
  String get scorecardUploadImportAnyway;

  /// No description provided for @scorecardUploadFixFirst.
  ///
  /// In en, this message translates to:
  /// **'Fix First'**
  String get scorecardUploadFixFirst;

  /// No description provided for @scorecardImportCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get scorecardImportCourse;

  /// No description provided for @scorecardImportCourseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Course name'**
  String get scorecardImportCourseNameHint;

  /// No description provided for @scorecardImportLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Location — search a course above'**
  String get scorecardImportLocationHint;

  /// No description provided for @scorecardImportNoCoursesFound.
  ///
  /// In en, this message translates to:
  /// **'No golf courses found'**
  String get scorecardImportNoCoursesFound;

  /// No description provided for @scorecardImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get scorecardImportButton;

  /// No description provided for @scorecardImportConditions.
  ///
  /// In en, this message translates to:
  /// **'Round Conditions'**
  String get scorecardImportConditions;

  /// No description provided for @scorecardImportAvgTemp.
  ///
  /// In en, this message translates to:
  /// **'Avg Temp'**
  String get scorecardImportAvgTemp;

  /// No description provided for @scorecardImportAvgWind.
  ///
  /// In en, this message translates to:
  /// **'Avg Wind'**
  String get scorecardImportAvgWind;

  /// No description provided for @scorecardImportConditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get scorecardImportConditionsLabel;

  /// No description provided for @scorecardImportWeatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable'**
  String get scorecardImportWeatherUnavailable;

  /// No description provided for @scorecardImportToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get scorecardImportToday;

  /// No description provided for @scorecardImportHowToAdd.
  ///
  /// In en, this message translates to:
  /// **'How would you like to add your scorecard?'**
  String get scorecardImportHowToAdd;

  /// No description provided for @scorecardImportTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get scorecardImportTakePhoto;

  /// No description provided for @scorecardImportPhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Photograph your paper scorecard'**
  String get scorecardImportPhotoDesc;

  /// No description provided for @scorecardImportFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from Library'**
  String get scorecardImportFromLibrary;

  /// No description provided for @scorecardImportLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Select an existing photo'**
  String get scorecardImportLibraryDesc;

  /// No description provided for @scorecardImportReading.
  ///
  /// In en, this message translates to:
  /// **'Reading your scorecard…'**
  String get scorecardImportReading;

  /// No description provided for @scorecardImportAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analysing with AI — this takes a few seconds'**
  String get scorecardImportAnalyzing;

  /// No description provided for @scorecardImportUnableRead.
  ///
  /// In en, this message translates to:
  /// **'Unable to Read Scorecard'**
  String get scorecardImportUnableRead;

  /// No description provided for @scorecardImportConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the AI service. Check your connection and try again.'**
  String get scorecardImportConnectionError;

  /// No description provided for @notifPersonalBestTitle.
  ///
  /// In en, this message translates to:
  /// **'🏆 New Personal Best!'**
  String get notifPersonalBestTitle;

  /// No description provided for @notifPersonalBestMsg.
  ///
  /// In en, this message translates to:
  /// **'You scored {score} — your best round yet. Keep it up!'**
  String notifPersonalBestMsg(String score);

  /// No description provided for @notifTeeTime1HourTitle.
  ///
  /// In en, this message translates to:
  /// **'⛳ Tee time in 1 hour!'**
  String get notifTeeTime1HourTitle;

  /// No description provided for @notifTeeTime1HourMsg.
  ///
  /// In en, this message translates to:
  /// **'Get ready for your round at {courseName}.'**
  String notifTeeTime1HourMsg(String courseName);

  /// No description provided for @notifTeeTime15MinTitle.
  ///
  /// In en, this message translates to:
  /// **'⛳ Tee time in 15 minutes!'**
  String get notifTeeTime15MinTitle;

  /// No description provided for @notifTeeTime15MinMsg.
  ///
  /// In en, this message translates to:
  /// **'Head to the first tee at {courseName}.'**
  String notifTeeTime15MinMsg(String courseName);

  /// No description provided for @notifStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'⛳ Time to hit the course!'**
  String get notifStreakTitle;

  /// No description provided for @notifStreakMsg.
  ///
  /// In en, this message translates to:
  /// **'It\'s been a while since your last round. Get out there!'**
  String get notifStreakMsg;

  /// No description provided for @noNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsTitle;

  /// No description provided for @noNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Play more rounds to unlock\nAI-personalised alerts'**
  String get noNotificationsDesc;

  /// No description provided for @widgetLeaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Leaderboard'**
  String get widgetLeaderboardTitle;

  /// No description provided for @widgetLeaderboardUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates after each hole'**
  String get widgetLeaderboardUpdates;

  /// No description provided for @widgetLeaderboardPos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get widgetLeaderboardPos;

  /// No description provided for @widgetLeaderboardPlayer.
  ///
  /// In en, this message translates to:
  /// **'PLAYER'**
  String get widgetLeaderboardPlayer;

  /// No description provided for @widgetLeaderboardThru.
  ///
  /// In en, this message translates to:
  /// **'THRU'**
  String get widgetLeaderboardThru;

  /// No description provided for @widgetLeaderboardScore.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get widgetLeaderboardScore;

  /// No description provided for @widgetLeaderboardThruHoles.
  ///
  /// In en, this message translates to:
  /// **'Thru {holes}'**
  String widgetLeaderboardThruHoles(String holes);

  /// No description provided for @widgetLeaderboardTeeOff.
  ///
  /// In en, this message translates to:
  /// **'Tee Off'**
  String get widgetLeaderboardTeeOff;

  /// No description provided for @widgetLeaderboardFinished.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get widgetLeaderboardFinished;

  /// No description provided for @widgetLeaderboardInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get widgetLeaderboardInvited;

  /// No description provided for @widgetLeaderboardDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get widgetLeaderboardDeclined;

  /// No description provided for @widgetUnfinishedRound.
  ///
  /// In en, this message translates to:
  /// **'Unfinished Round'**
  String get widgetUnfinishedRound;

  /// No description provided for @widgetHolesPlayed.
  ///
  /// In en, this message translates to:
  /// **'{played} / {total} holes played'**
  String widgetHolesPlayed(int played, int total);

  /// No description provided for @widgetResumeRound.
  ///
  /// In en, this message translates to:
  /// **'Resume Round'**
  String get widgetResumeRound;

  /// No description provided for @widgetDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Round?'**
  String get widgetDiscardTitle;

  /// No description provided for @widgetDiscardMsg.
  ///
  /// In en, this message translates to:
  /// **'All progress on \"{courseName}\" will be permanently lost.'**
  String widgetDiscardMsg(String courseName);

  /// No description provided for @widgetKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get widgetKeep;

  /// No description provided for @widgetDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get widgetDiscard;

  /// No description provided for @widgetClubsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap clubs below to track each shot'**
  String get widgetClubsHint;

  /// No description provided for @widgetClubsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} clubs selected'**
  String widgetClubsSelected(int count, int max);

  /// No description provided for @widgetGolfDNA.
  ///
  /// In en, this message translates to:
  /// **'GOLF DNA'**
  String get widgetGolfDNA;

  /// No description provided for @widgetProAnalysis.
  ///
  /// In en, this message translates to:
  /// **'PRO ANALYSIS'**
  String get widgetProAnalysis;

  /// No description provided for @widgetPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get widgetPower;

  /// No description provided for @widgetAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get widgetAccuracy;

  /// No description provided for @widgetPutting.
  ///
  /// In en, this message translates to:
  /// **'Putting'**
  String get widgetPutting;

  /// No description provided for @widgetStrengthsWeaknesses.
  ///
  /// In en, this message translates to:
  /// **'Strengths & Weaknesses'**
  String get widgetStrengthsWeaknesses;

  /// No description provided for @widgetPerformanceTrends.
  ///
  /// In en, this message translates to:
  /// **'Performance Trends'**
  String get widgetPerformanceTrends;

  /// No description provided for @widgetTraitAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Trait Analysis'**
  String get widgetTraitAnalysis;

  /// No description provided for @widgetDrivingPower.
  ///
  /// In en, this message translates to:
  /// **'Driving Power'**
  String get widgetDrivingPower;

  /// No description provided for @widgetConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get widgetConsistency;

  /// No description provided for @widgetRiskLevel.
  ///
  /// In en, this message translates to:
  /// **'Risk Level'**
  String get widgetRiskLevel;

  /// No description provided for @widgetStamina.
  ///
  /// In en, this message translates to:
  /// **'Stamina'**
  String get widgetStamina;

  /// No description provided for @widgetAIRoundSummary.
  ///
  /// In en, this message translates to:
  /// **'AI Round Summary'**
  String get widgetAIRoundSummary;

  /// No description provided for @widgetAnalyzingRound.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your round…'**
  String get widgetAnalyzingRound;

  /// No description provided for @widgetGemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get widgetGemini;

  /// No description provided for @widgetStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get widgetStrength;

  /// No description provided for @widgetWeakness.
  ///
  /// In en, this message translates to:
  /// **'Weakness'**
  String get widgetWeakness;

  /// No description provided for @widgetFocusArea.
  ///
  /// In en, this message translates to:
  /// **'Focus Area'**
  String get widgetFocusArea;

  /// No description provided for @widgetPlayStyle.
  ///
  /// In en, this message translates to:
  /// **'PLAY STYLE'**
  String get widgetPlayStyle;

  /// No description provided for @widgetAIPowered.
  ///
  /// In en, this message translates to:
  /// **'AI Powered'**
  String get widgetAIPowered;

  /// No description provided for @widgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String widgetUpdated(String date);

  /// No description provided for @widgetUpdatedToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get widgetUpdatedToday;

  /// No description provided for @widgetUpdatedYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get widgetUpdatedYesterday;

  /// No description provided for @widgetUpdatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String widgetUpdatedDaysAgo(int days);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeDaysAgo(int days);
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
      <String>['de', 'en', 'es', 'fr', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
