// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'TeeStats';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get save => 'सहेजें';

  @override
  String get done => 'हो गया';

  @override
  String get search => 'खोजें';

  @override
  String get ok => 'ठीक है';

  @override
  String get yes => 'हां';

  @override
  String get no => 'नहीं';

  @override
  String get next => 'अगला';

  @override
  String get back => 'वापस';

  @override
  String get skip => 'छोड़ें';

  @override
  String get close => 'बंद करें';

  @override
  String get edit => 'संपादित करें';

  @override
  String get view => 'देखें';

  @override
  String get accept => 'स्वीकार करें';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get home => 'होम';

  @override
  String get rounds => 'राउंड';

  @override
  String get stats => 'आंकड़े';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get friends => 'मित्र';

  @override
  String get loginWelcomeBack => 'वापसी पर स्वागत है';

  @override
  String get loginSignInToContinue => 'जारी रखने के लिए साइन इन करें';

  @override
  String get loginEmail => 'ईमेल';

  @override
  String get loginPassword => 'पासवर्ड';

  @override
  String get loginForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get loginSignIn => 'साइन इन करें';

  @override
  String get loginDontHaveAccount => 'खाता नहीं है?';

  @override
  String get loginSignUp => 'साइन अप करें';

  @override
  String get loginTagline => 'खेलें  ·  ट्रैक करें  ·  सुधारें';

  @override
  String get loginResetPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get loginResetPasswordSubtitle =>
      'हम आपके ईमेल पर एक रीसेट लिंक भेजेंगे';

  @override
  String get loginEnterYourEmail => 'अपना ईमेल दर्ज करें';

  @override
  String get loginEnterValidEmail => 'एक मान्य ईमेल दर्ज करें';

  @override
  String get loginSendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get loginResetLinkSent => 'रीसेट लिंक भेज दिया गया!';

  @override
  String loginCheckInboxFor(String email) {
    return '$email के लिए अपना इनबॉक्स देखें';
  }

  @override
  String get loginErrorNoAccount => 'इस ईमेल से कोई खाता नहीं मिला।';

  @override
  String get loginErrorInvalidEmail => 'कृपया एक मान्य ईमेल दर्ज करें।';

  @override
  String get loginErrorSomethingWrong => 'कुछ गलत हो गया। पुनः प्रयास करें।';

  @override
  String get loginErrorIncorrectCredentials => 'गलत ईमेल या पासवर्ड।';

  @override
  String get loginErrorAccountDisabled => 'यह खाता अक्षम कर दिया गया है।';

  @override
  String get loginErrorTooManyAttempts =>
      'बहुत अधिक प्रयास। बाद में पुनः प्रयास करें।';

  @override
  String get loginErrorTryAgain => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get signupCreateAccount => 'खाता बनाएं';

  @override
  String get signupJoinToday => 'आज TeeStats से जुड़ें';

  @override
  String get signupFullName => 'पूरा नाम';

  @override
  String get signupEnterYourName => 'अपना नाम दर्ज करें';

  @override
  String get signupEmail => 'ईमेल';

  @override
  String get signupPassword => 'पासवर्ड';

  @override
  String get signupConfirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get signupEnterPassword => 'एक पासवर्ड दर्ज करें';

  @override
  String get signupMinimumChars => 'न्यूनतम 6 अक्षर';

  @override
  String get signupConfirmYourPassword => 'अपने पासवर्ड की पुष्टि करें';

  @override
  String get signupPasswordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String signupPasswordStrength(String label) {
    return 'पासवर्ड की मजबूती: $label';
  }

  @override
  String get signupPasswordWeak => 'कमज़ोर';

  @override
  String get signupPasswordFair => 'ठीक-ठाक';

  @override
  String get signupPasswordGood => 'अच्छा';

  @override
  String get signupPasswordStrong => 'मजबूत';

  @override
  String get signupAlreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get signupErrorAccountExists => 'इस ईमेल से एक खाता पहले से मौजूद है।';

  @override
  String get signupErrorInvalidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें।';

  @override
  String get signupErrorWeakPassword =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए।';

  @override
  String get signupErrorNotEnabled => 'ईमेल साइन-अप सक्षम नहीं है।';

  @override
  String get onboardingTagline => 'स्विंग करें। ट्रैक करें। जीतें।';

  @override
  String get onboardingScoreTrackingTag => 'स्कोर ट्रैकिंग';

  @override
  String get onboardingTrackEveryRoundTitle => 'हर राउंड\nट्रैक करें';

  @override
  String get onboardingScoreTrackingBody =>
      'हर होल के लिए GPS-संचालित स्कोरिंग। आपका पूरा राउंड इतिहास, हमेशा आपकी जेब में।';

  @override
  String get onboardingPerformanceTag => 'प्रदर्शन';

  @override
  String get onboardingGolfDNATitle => 'अपना\nगोल्फ DNA जानें';

  @override
  String get onboardingPerformanceBody =>
      'फेयरवे हिट, GIR, प्रति राउंड पट, हैंडीकैप ट्रेंड — ठीक वह जगह पहचानें जहाँ सुधार करना है।';

  @override
  String get onboardingMultiplayerTag => 'मल्टीप्लेयर';

  @override
  String get onboardingPlayTogetherTitle => 'साथ\nखेलें';

  @override
  String get onboardingMultiplayerBody =>
      'मित्रों को एक लाइव ग्रुप राउंड में आमंत्रित करें। रियल-टाइम लीडरबोर्ड, बिना अतिरिक्त स्कोरकीपिंग।';

  @override
  String get onboardingSocialTag => 'सोशल';

  @override
  String get onboardingFriendsLeaderboardTitle => 'मित्र और\nलीडरबोर्ड';

  @override
  String get onboardingSocialBody =>
      'अपने गोल्फ क्रू से जुड़ें। देखें कौन शानदार फॉर्म में है और उन्हें आपको हराने की चुनौती दें।';

  @override
  String get onboardingAITag => 'AI संचालित';

  @override
  String get onboardingPersonalCaddieTitle => 'आपका व्यक्तिगत\nकैडी';

  @override
  String get onboardingAIBody =>
      'हर राउंड के बाद, Gemini AI आपके आंकड़े विश्लेषण करता है और कोचिंग अंतर्दृष्टि देता है — ताकत, कमज़ोरियां और अगली बार तेज करने का फोकस क्षेत्र।';

  @override
  String get onboardingPoweredByGemini => 'Google Gemini द्वारा संचालित';

  @override
  String get homeReadyToPlay => '⛳  खेलने के लिए तैयार?';

  @override
  String get homeStartRound => 'राउंड शुरू करें';

  @override
  String get homeTapToTeeOff => 'टी ऑफ के लिए टैप करें';

  @override
  String get greetingPerfectTeeTime => 'टी टाइम एकदम सही ⛳';

  @override
  String get greetingSunnyBreezy => 'धूप और हल्की हवा ⛳';

  @override
  String get greetingToughWeather => 'मुश्किल मौसम आगे 🌧️';

  @override
  String get greetingGoodScoring => 'अच्छे स्कोर का मौसम ⛅';

  @override
  String get greetingPlaySmart => 'आज समझदारी से खेलें 💨';

  @override
  String get greetingEarlyTeeTime => 'सुबह की शुरुआत';

  @override
  String get greetingMorningRound => 'सुबह का राउंड';

  @override
  String get greetingPerfectMorning => 'बेहतरीन सुबह';

  @override
  String get greetingMiddayFairways => 'दोपहर के फेयरवे';

  @override
  String get greetingAfternoonLinks => 'दोपहर बाद के लिंक्स';

  @override
  String get greetingEveningRound => 'शाम का राउंड';

  @override
  String get greetingClubbouseTime => 'क्लबहाउस का समय';

  @override
  String get insightWetCourse => '🌧️ गीला कोर्स — एक क्लब कम लें';

  @override
  String get insightIdealConditions =>
      '💡 आदर्श परिस्थितियाँ — अपनी दूरियों पर भरोसा रखें';

  @override
  String insightTry7Iron(String wind) {
    return '💡 आज 7 आयरन आज़माएं (हवा $wind)';
  }

  @override
  String insightClubUp(String wind) {
    return '💨 एक क्लब बड़ा लें — हवा $wind';
  }

  @override
  String insightWindConservative(String wind) {
    return '💨 हवा $wind — सावधानी से खेलें';
  }

  @override
  String get insightPuttingImproved => '📈 पटिंग सुधरी — यही रफ्तार बनाए रखें';

  @override
  String get insightFocusPutts => '💡 इस राउंड में छोटे पट्ट पर ध्यान दें';

  @override
  String get insightReadyToPlay => '🏌️ खेलने के लिए तैयार';

  @override
  String subtitlePuttingImproved(String sign, int pct) {
    return 'इस हफ्ते आपकी पटिंग $sign$pct% बेहतर हुई';
  }

  @override
  String subtitlePuttingUp(String sign, int pct) {
    return 'इस हफ्ते पटिंग $sign$pct% ऊपर';
  }

  @override
  String subtitleGirDelta(String sign, int pct) {
    return 'GIR $sign$pct% पिछले 4 राउंड की तुलना में';
  }

  @override
  String get homeGolfNews => 'गोल्फ समाचार';

  @override
  String get homeSeeAll => 'सभी देखें';

  @override
  String get homeRecentRounds => 'हाल के राउंड';

  @override
  String get homeViewAll => 'सभी देखें';

  @override
  String get homeNoRoundsYet => 'अभी तक कोई राउंड नहीं — अपना पहला शुरू करें!';

  @override
  String get homeInProgress => 'जारी है';

  @override
  String get homeActive => 'सक्रिय';

  @override
  String get homeNoLocation => 'कोई स्थान नहीं';

  @override
  String get homePerformance => 'प्रदर्शन';

  @override
  String get homeCompleteRoundsForStats =>
      'अपना हैंडीकैप और प्रदर्शन आंकड़े देखने के लिए राउंड पूरे करें।';

  @override
  String get homeHandicapIndex => 'हैंडीकैप इंडेक्स';

  @override
  String homeRoundsNeeded(int n) {
    return '$n/20 राउंड';
  }

  @override
  String homeMoreRoundsToUnlock(int n) {
    return 'अपना हैंडीकैप इंडेक्स अनलॉक करने के लिए $n और राउंड';
  }

  @override
  String get homeFairwaysHit => 'फेयरवे हिट';

  @override
  String get homePar4And5 => 'पार 4 और 5 होल';

  @override
  String get homeGIR => 'ग्रीन इन रेग.';

  @override
  String get homeAllHoles => 'सभी होल';

  @override
  String get homeAvgPutts => 'औसत पट';

  @override
  String get homePerHole => 'प्रति होल';

  @override
  String get homeBirdies => 'बर्डी';

  @override
  String get homeAllRounds => 'सभी राउंड';

  @override
  String get homeToday => 'आज';

  @override
  String get homeYesterday => 'कल';

  @override
  String homeDaysAgo(int n) {
    return '$n दिन पहले';
  }

  @override
  String get homeWeekAgo => '1 सप्ताह पहले';

  @override
  String get homeTwoWeeksAgo => '2 सप्ताह पहले';

  @override
  String get homeThreeWeeksAgo => '3 सप्ताह पहले';

  @override
  String homeMonthsAgo(int n) {
    return '$n महीने पहले';
  }

  @override
  String homeInvitedToPlay(String name) {
    return '$name ने आपको खेलने के लिए आमंत्रित किया';
  }

  @override
  String get homeChangeLocation => 'स्थान बदलें';

  @override
  String get homeSearchCityOrArea => 'कोई शहर या क्षेत्र खोजें';

  @override
  String get homeLocationHint => 'जैसे: दुबई, लंदन, न्यूयॉर्क…';

  @override
  String get homeSearchLocation => 'स्थान खोजें';

  @override
  String get homeLocationNotFound =>
      'स्थान नहीं मिला। किसी अन्य शहर का नाम आज़माएं।';

  @override
  String get homeUseCurrentLocation => 'मेरी वर्तमान स्थान का उपयोग करें';

  @override
  String get homeWelcomeTour => 'TeeStats में आपका स्वागत है';

  @override
  String get homeWelcomeTourBody =>
      'यह आपका होम है — एक नज़र में हाल के राउंड, प्रदर्शन और पास के कोर्स देखें।';

  @override
  String get homeFriendsAndLeaderboard => 'मित्र और लीडरबोर्ड';

  @override
  String get homeFriendsAndLeaderboardBody =>
      'गोल्फ साथियों को जोड़ें, मित्र अनुरोध स्वीकार करें, और लीडरबोर्ड पर स्कोर तुलना करें। जब कोई लंबित अनुरोध हो तो एक हरा डॉट दिखता है।';

  @override
  String get homeStartARound => 'राउंड शुरू करें';

  @override
  String get homeStartARoundBody =>
      'किसी भी कोर्स पर नया राउंड स्कोर करना शुरू करने के लिए कभी भी हरे बटन पर टैप करें।';

  @override
  String get homeYourActiveRound => 'आपका सक्रिय राउंड';

  @override
  String get homeResumeRoundBody =>
      'यदि आप बीच में छोड़ते हैं, तो यह यहाँ सहेजा जाता है। जहाँ छोड़ा था वहाँ से जारी रखने के लिए Resume टैप करें।';

  @override
  String get homeRoundHistory => 'राउंड इतिहास';

  @override
  String get homeRoundHistoryBody =>
      'आपके सभी पूर्ण राउंड यहाँ हैं। प्रत्येक होल के विस्तृत विवरण के लिए किसी भी राउंड पर टैप करें।';

  @override
  String get homeYourStats => 'आपके आंकड़े';

  @override
  String get homeYourStatsBody =>
      'समय के साथ अपना हैंडीकैप ट्रेंड, स्कोरिंग पैटर्न, GIR, फेयरवे और स्ट्रोक्स गेंड ट्रैक करें।';

  @override
  String get homeYourProfile => 'आपकी प्रोफ़ाइल';

  @override
  String get homeYourProfileBody =>
      'अपना हैंडीकैप लक्ष्य निर्धारित करें, एक अवतार चुनें, और अपनी गोल्फ DNA और प्ले स्टाइल पहचान देखें।';

  @override
  String get homeQuickStats => 'त्वरित आंकड़े';

  @override
  String get homeQuickStatsBody =>
      'आपके सभी राउंड में लाइव औसत — फेयरवे, GIR, पट और बर्डी प्रति राउंड।';

  @override
  String get homeNearbyCourses => 'पास के कोर्स';

  @override
  String get homeNearbyCoursesBody =>
      'आपके स्थान के पास गोल्फ कोर्स। तुरंत वहाँ राउंड शुरू करने के लिए किसी भी कोर्स पर टैप करें।';

  @override
  String get roundsMyRounds => 'मेरे राउंड';

  @override
  String get roundsRoundsTab => 'राउंड';

  @override
  String get roundsPracticeTab => 'अभ्यास';

  @override
  String get roundsTournamentsTab => 'टूर्नामेंट';

  @override
  String get roundsHistoryTitle => 'आपका राउंड इतिहास';

  @override
  String get roundsHistorySubtitle =>
      'सभी पूर्ण राउंड यहाँ हैं। प्रत्येक होल के विस्तृत विवरण और आंकड़ों के लिए किसी भी राउंड पर टैप करें।';

  @override
  String get roundsInProgress => 'राउंड जारी है';

  @override
  String roundsHolesProgress(int played, int total) {
    return '$played/$total होल';
  }

  @override
  String get roundsNoRoundsYet => 'अभी तक कोई राउंड नहीं';

  @override
  String get roundsStartFirst => 'होम टैब से अपना पहला राउंड शुरू करें';

  @override
  String get roundsOrScanScorecard => 'या एक कागज़ी स्कोरकार्ड स्कैन करें';

  @override
  String get roundsDeleteTitle => 'राउंड हटाएं?';

  @override
  String roundsDeleteConfirm(String courseName) {
    return '$courseName पर आपका राउंड स्थायी रूप से हटाएं?';
  }

  @override
  String get roundsBirdies => 'बर्डी';

  @override
  String get roundsPars => 'पार';

  @override
  String get roundsBogeys => 'बोगी';

  @override
  String get roundsPutts => 'पट';

  @override
  String get roundsFIR => 'FIR';

  @override
  String get roundSummaryComplete => 'राउंड पूर्ण!';

  @override
  String get roundSummaryScore => 'स्कोर';

  @override
  String get roundSummaryVsPar => 'पार बनाम';

  @override
  String get roundSummaryHoles => 'होल';

  @override
  String get roundSummaryBackToHome => 'होम पर वापस';

  @override
  String get roundSummaryEven => 'बराबर';

  @override
  String get roundDetailScorecard => 'स्कोरकार्ड';

  @override
  String get roundDetailShotTrails => 'शॉट ट्रेल्स';

  @override
  String get roundDetailHole => 'होल';

  @override
  String get roundDetailPar => 'पार';

  @override
  String get roundDetailGIR => 'GIR';

  @override
  String get roundDetailTotal => 'कुल';

  @override
  String get roundDetailShare => 'स्कोरकार्ड शेयर करें';

  @override
  String get roundDetailDelete => 'राउंड हटाएं';

  @override
  String get roundDetailDeleteTitle => 'राउंड हटाएं?';

  @override
  String roundDetailDeleteConfirm(String courseName) {
    return 'यह $courseName पर आपका राउंड स्थायी रूप से हटा देगा।';
  }

  @override
  String get startRoundPickCourse => '📍  अपना कोर्स चुनें';

  @override
  String get startRoundWherePlaying => 'आप कहाँ\nखेल रहे हैं?';

  @override
  String get startRoundSearchHint => 'पास के गोल्फ कोर्स की खोज करें';

  @override
  String get startRoundCourseName => 'कोर्स का नाम';

  @override
  String get startRoundEnterCourseName => 'कोर्स का नाम दर्ज करें';

  @override
  String get startRoundFetchingTeeData => 'टी डेटा प्राप्त हो रहा है…';

  @override
  String get startRoundSelectTee => 'टी चुनें';

  @override
  String get startRoundCourseRating => 'कोर्स रेटिंग (वैकल्पिक)';

  @override
  String get startRoundRatingForHandicap => 'सटीक USGA हैंडीकैप इंडेक्स के लिए';

  @override
  String get startRoundCourseRatingLabel => 'कोर्स रेटिंग';

  @override
  String get startRoundCourseRatingHint => 'जैसे: 72.5';

  @override
  String get startRoundSlopeRatingLabel => 'स्लोप रेटिंग';

  @override
  String get startRoundSlopeRatingHint => 'जैसे: 113';

  @override
  String get startRoundSlopeError => '55–155';

  @override
  String get startRoundNumberOfHoles => 'होल की संख्या';

  @override
  String get startRoundHoles => 'होल';

  @override
  String get startRoundInviteFriends => 'मित्रों को आमंत्रित करें (अधिकतम 3)';

  @override
  String get startRoundSearchFriends => 'मित्र खोजें…';

  @override
  String get startRoundNoFriends => 'अभी तक कोई मित्र नहीं।';

  @override
  String get startRoundNoMatches => 'कोई मेल नहीं।';

  @override
  String startRoundFriendsInvited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मित्रों को आमंत्रित किया जाएगा',
      one: '1 मित्र को आमंत्रित किया जाएगा',
    );
    return '$_temp0';
  }

  @override
  String get startRoundTeeOff => 'टी ऑफ करें!';

  @override
  String get startRoundNoCoursesFound => 'पास में कोई गोल्फ कोर्स नहीं मिला';

  @override
  String get startRoundNoHoleData => 'इस कोर्स के लिए कोई होल डेटा नहीं मिला।';

  @override
  String get startRoundUploadScorecard => 'स्कोरकार्ड अपलोड करें';

  @override
  String startRoundError(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get scorecardScoringARound => 'राउंड स्कोर करना';

  @override
  String get scorecardInstructions =>
      'प्रत्येक होल के लिए अपना स्कोर, पट, फेयरवे और GIR दर्ज करें। क्लब चयन ट्रैक करने के लिए क्लब पर टैप करें।';

  @override
  String get scorecardHole => 'होल';

  @override
  String get scorecardPlayingWithFriends => 'मित्रों के साथ खेल रहे हैं';

  @override
  String get scorecardScore => 'स्कोर';

  @override
  String get scorecardPutts => 'पट';

  @override
  String get scorecardFairwayHit => 'फेयरवे हिट';

  @override
  String get scorecardGIR => 'ग्रीन इन रेगुलेशन';

  @override
  String get scorecardTrackShots => 'शॉट ट्रैक करें';

  @override
  String get scorecardTeeSet => 'टी सेट';

  @override
  String scorecardShotsTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शॉट ट्रैक किए गए',
      one: '1 शॉट ट्रैक किया गया',
    );
    return '$_temp0';
  }

  @override
  String get scorecardClub => 'क्लब';

  @override
  String get scorecardScorecardLabel => 'स्कोरकार्ड';

  @override
  String get scorecardLeaveTitle => 'राउंड छोड़ें?';

  @override
  String get scorecardLeaveBody =>
      'आपकी प्रगति स्वचालित रूप से सहेजी जाती है।\nआप होम स्क्रीन से यह राउंड फिर शुरू कर सकते हैं।';

  @override
  String get scorecardSaveAndExit => 'सहेजें और बाहर निकलें';

  @override
  String get scorecardKeepPlaying => 'खेलते रहें';

  @override
  String get scorecardAbandon => 'छोड़ें';

  @override
  String get scorecardNextHole => 'अगला होल';

  @override
  String get scorecardFinishRound => 'राउंड समाप्त करें';

  @override
  String get scorecardAICaddy => 'AI कैडी';

  @override
  String get scorecardTipPar3 =>
      'पार 3: एक क्लब पर निर्णय लें और स्विंग पर भरोसा करें।';

  @override
  String get scorecardTipInsightsUnlock =>
      'अपना खेल खेलें — 3 होल के बाद अंतर्दृष्टि अनलॉक होगी।';

  @override
  String scorecardTipAvgPutts(String avgPutts) {
    return 'औसत $avgPutts पट — दूरी से लैग पटिंग पर ध्यान दें।';
  }

  @override
  String scorecardTipFairways(String fwhitPercent) {
    return 'केवल $fwhitPercent% फेयरवे हिट — टी से 3-वुड का प्रयोग करें।';
  }

  @override
  String get scorecardTipApproach =>
      'अप्रोच संघर्ष कर रही है — आज ग्रीन के बीच का हिस्सा लक्ष्य रखें।';

  @override
  String get scorecardTipSolid =>
      'अब तक शानदार राउंड — वही लय और टेम्पो बनाए रखें।';

  @override
  String get scorecardYds => 'गज';

  @override
  String scorecardPlaysLike(String distance) {
    return 'खेलता है $distance गज जैसा';
  }

  @override
  String get scorecardEagle => 'ईगल';

  @override
  String get scorecardAlbatross => 'अल्बाट्रॉस';

  @override
  String get scorecardBirdie => 'बर्डी';

  @override
  String get scorecardPar => 'पार';

  @override
  String get scorecardBogey => 'बोगी';

  @override
  String get scorecardDouble => 'डबल';

  @override
  String scorecardEditHole(int hole) {
    return 'होल $hole संपादित करें';
  }

  @override
  String scorecardErrorSaving(String error) {
    return 'सहेजने में त्रुटि: $error';
  }

  @override
  String get scorecardOn => 'चालू';

  @override
  String get scorecardOff => 'बंद';

  @override
  String get statsHub => 'आपका आंकड़े हब';

  @override
  String get statsPlayMoreRounds =>
      'ट्रेंड चार्ट, स्ट्रोक्स गेंड और स्कोर वितरण विश्लेषण अनलॉक करने के लिए अधिक राउंड खेलें।';

  @override
  String get statsHandicapIndex => 'हैंडीकैप इंडेक्स';

  @override
  String statsBasedOnRounds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n राउंड के आधार पर',
      one: '1 राउंड के आधार पर',
    );
    return '$_temp0';
  }

  @override
  String get statsCompleteToCalculate => 'गणना करने के लिए राउंड पूरे करें';

  @override
  String get statsAvgScore => 'औसत स्कोर';

  @override
  String get statsBestRound => 'सर्वश्रेष्ठ राउंड';

  @override
  String get statsTotalRounds => 'कुल राउंड';

  @override
  String get statsTotalBirdies => 'कुल बर्डी';

  @override
  String get statsScoreDistribution => 'स्कोर वितरण';

  @override
  String get statsEagles => 'ईगल';

  @override
  String get statsBirdies => 'बर्डी';

  @override
  String get statsPars => 'पार';

  @override
  String get statsBogeys => 'बोगी';

  @override
  String get statsDoublePlus => 'डबल+';

  @override
  String statsScoreVsPar(int n) {
    return 'स्कोर बनाम पार (पिछले $n राउंड)';
  }

  @override
  String get statsOldestToRecent => 'सबसे पुराना → सबसे हाल का';

  @override
  String get statsHandicapTrend => 'हैंडीकैप ट्रेंड';

  @override
  String statsGoal(String n) {
    return 'लक्ष्य: $n';
  }

  @override
  String statsLatest(String n) {
    return 'नवीनतम: $n';
  }

  @override
  String get statsFairwaysHit => 'फेयरवे हिट';

  @override
  String get statsGIR => 'ग्रीन इन रेगुलेशन';

  @override
  String get statsAvgPuttsPerHole => 'औसत पट / होल';

  @override
  String get statsClubStats => 'क्लब आंकड़े';

  @override
  String get statsClubStatsSubtitle => 'प्रति क्लब स्कोर बनाम पार और औसत पट';

  @override
  String get statsClub => 'क्लब';

  @override
  String get statsHoles => 'होल';

  @override
  String get statsAvgPlusMinus => 'औसत ±पार';

  @override
  String get statsAvgPutts => 'औसत पट';

  @override
  String get statsStrokesGained => 'स्ट्रोक्स गेंड';

  @override
  String get statsVsScratch => 'स्क्रैच गोल्फर बेसलाइन बनाम';

  @override
  String get statsOffTheTee => 'टी से';

  @override
  String get statsApproach => 'अप्रोच';

  @override
  String get statsAroundGreen => 'ग्रीन के आसपास';

  @override
  String get statsPutting => 'पटिंग';

  @override
  String get statsBetterThanAvg => 'औसत से\nbेहतर';

  @override
  String get statsPressureScore => 'प्रेशर स्कोर';

  @override
  String get statsPressureResilience => 'लचीलापन';

  @override
  String statsPressureUnlockHint(int count) {
    return 'अपना मानसिक प्रोफ़ाइल अनलॉक करने के लिए $count राउंड और खेलें';
  }

  @override
  String get statsPressureOpeningHole => 'पहला होल';

  @override
  String get statsPressureBirdieHangover => 'बर्डी हैंगओवर';

  @override
  String get statsPressureBackNine => 'बैक नाइन गिरावट';

  @override
  String get statsPressureFinishingStretch => 'अंतिम होल';

  @override
  String get statsPressureThreePutt => 'थ्री-पुट टाइमिंग';

  @override
  String get statsPressureTopDrill => 'मुख्य अभ्यास';

  @override
  String get statsPressureInsufficientData => 'कम डेटा';

  @override
  String get tournamentNoTournaments => 'अभी तक कोई टूर्नामेंट नहीं';

  @override
  String get tournamentCreateInstructions =>
      'एक बनाने के लिए \"नया टूर्नामेंट\" टैप करें,\nफिर टूर्नामेंट के लिए स्कोर करने हेतु राउंड शुरू करें।';

  @override
  String get tournamentNew => 'नया टूर्नामेंट';

  @override
  String get tournamentStartInstructions =>
      'पहले एक टूर्नामेंट बनाएं, फिर टूर्नामेंट राउंड शुरू करने के लिए होम स्क्रीन पर ＋ FAB का उपयोग करें।';

  @override
  String get tournamentDeleteTitle => 'टूर्नामेंट हटाएं?';

  @override
  String tournamentDeleteConfirm(String name) {
    return '\"$name\" हटाएं? राउंड स्वयं हटाए नहीं जाएंगे।';
  }

  @override
  String get tournamentRoundByRound => 'राउंड दर राउंड';

  @override
  String get tournamentVsPar => 'पार बनाम';

  @override
  String get tournamentRoundsLabel => 'राउंड';

  @override
  String get tournamentNameLabel => 'टूर्नामेंट का नाम';

  @override
  String get tournamentNameHint => 'जैसे: क्लब चैंपियनशिप 2026';

  @override
  String get tournamentCreate => 'टूर्नामेंट बनाएं';

  @override
  String tournamentRoundsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n राउंड',
      one: '1 राउंड',
    );
    return '$_temp0';
  }

  @override
  String get tournamentRunning => 'जारी है';

  @override
  String get practiceNoSessions => 'अभी तक कोई अभ्यास सत्र नहीं';

  @override
  String get practiceStartInstructions =>
      'होल स्कोर करने के लिए एक राउंड शुरू करें,\nया रेंज और शॉर्ट-गेम सत्र लॉग करें।';

  @override
  String get practiceLogSession => 'सत्र लॉग करें';

  @override
  String get practiceScoredRound => 'स्कोर किया गया राउंड';

  @override
  String get practiceDeleteTitle => 'सत्र हटाएं?';

  @override
  String get practiceDeleteConfirm =>
      'यह अभ्यास सत्र स्थायी रूप से हटा दिया जाएगा।';

  @override
  String get practiceLogTitle => 'अभ्यास सत्र लॉग करें';

  @override
  String get practiceType => 'प्रकार';

  @override
  String get practiceBallsHit => 'बॉल हिट';

  @override
  String get practiceDuration => 'अवधि (मिनट)';

  @override
  String get practiceNotes => 'नोट्स (वैकल्पिक)';

  @override
  String get practiceNotesHint => 'आपने किस पर काम किया?';

  @override
  String get practiceSave => 'सत्र सहेजें';

  @override
  String get friendsTitle => 'मित्र';

  @override
  String get friendsLeaderboard => 'लीडरबोर्ड';

  @override
  String get friendsNoFriendsYet => 'अभी तक कोई मित्र नहीं';

  @override
  String get friendsEnterEmail =>
      'उन्हें जोड़ने के लिए ऊपर एक मित्र का ईमेल दर्ज करें';

  @override
  String get friendsSearchHint => 'ईमेल पते से खोजें…';

  @override
  String get friendsPendingRequests => 'लंबित अनुरोध';

  @override
  String get friendsWantsToBeF => 'मित्र बनना चाहता है';

  @override
  String get friendsRequestSent => 'अनुरोध भेजा गया';

  @override
  String get friendsAcceptRequest => 'अनुरोध स्वीकार करें';

  @override
  String get friendsAlreadyFriends => 'पहले से मित्र हैं';

  @override
  String get friendsAddFriend => 'मित्र जोड़ें';

  @override
  String get friendsNoLeaderboard => 'अभी तक कोई लीडरबोर्ड नहीं';

  @override
  String get friendsAddToCompare => 'स्कोर तुलना करने के लिए मित्र जोड़ें';

  @override
  String get friendsHandicap => 'हैंडीकैप';

  @override
  String get friendsAvgScore => 'औसत स्कोर';

  @override
  String get friendsYou => 'आप';

  @override
  String get notifPrefsTitle => 'स्मार्ट सूचनाएं';

  @override
  String get notifPrefsSubtitle => 'आपके खेल के लिए AI-संचालित अलर्ट';

  @override
  String get notifPrefsSectionTitle => 'सूचना प्रकार';

  @override
  String get notifPrefsPracticeReminders => 'अभ्यास अनुस्मारक';

  @override
  String get notifPrefsPracticeDesc =>
      'आपके कमजोर क्षेत्रों के लिए AI-अनुकूलित अभ्यास';

  @override
  String get notifPrefsResumeRound => 'राउंड फिर शुरू करें';

  @override
  String get notifPrefsResumeDesc => 'अधूरे राउंड पूरे करने के लिए प्रेरणा';

  @override
  String get notifPrefsPerformance => 'प्रदर्शन अंतर्दृष्टि';

  @override
  String get notifPrefsPerformanceDesc =>
      'सुधार की लकीरों और रुझानों का जश्न मनाएं';

  @override
  String get notifPrefsTeeTime => 'टी टाइम अनुस्मारक';

  @override
  String get notifPrefsTeeTimeDesc => 'आगामी टी टाइम से पहले अलर्ट';

  @override
  String get notifPrefsSaved => 'प्राथमिकताएं सहेजी गईं';

  @override
  String get notifPrefsPersonalised =>
      'सूचनाएं आपके हाल के राउंड और\nप्रदर्शन रुझानों के आधार पर व्यक्तिगत हैं।';

  @override
  String get notifPrefsAIDriven => '✨ AI-संचालित अलर्ट';

  @override
  String get notifPrefsSmartDesc => 'आपके गोल्फ खेल के अनुकूल\nस्मार्ट सूचनाएं';

  @override
  String get notifPrefsExplanation =>
      'TeeStats आपके राउंड, अभ्यास की आदतें और प्रदर्शन रुझानों का विश्लेषण करके ऐसी सूचनाएं भेजता है जो वास्तव में आपके खेल में मदद करती हैं।';

  @override
  String get notifPrefsSave => 'प्राथमिकताएं सहेजें';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get profileSubtitle => 'इसे अपना बनाएं';

  @override
  String get profileDescription =>
      'अपना हैंडीकैप लक्ष्य निर्धारित करें, एक अवतार चुनें, और अपनी गोल्फ DNA और प्ले स्टाइल जानें।';

  @override
  String get profileGolfer => 'गोल्फर';

  @override
  String get profileGolfPlaces => 'गोल्फ स्थान';

  @override
  String get profileEditProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileSmartNotifications => 'स्मार्ट सूचनाएं';

  @override
  String get profileAchievementsSection => 'उपलब्धियां';

  @override
  String get profileRounds => 'राउंड';

  @override
  String get profileHandicap => 'हैंडीकैप';

  @override
  String get profileBirdies => 'बर्डी';

  @override
  String get profileAccount => 'खाता';

  @override
  String get profileSignOut => 'साइन आउट करें';

  @override
  String get profileDeleteAccount => 'खाता हटाएं';

  @override
  String profileVersion(String version) {
    return 'TeeStats v$version';
  }

  @override
  String profileCopyright(String year) {
    return '© $year TeeStats. सर्वाधिकार सुरक्षित।';
  }

  @override
  String get profileHandicapGoal => 'हैंडीकैप लक्ष्य';

  @override
  String get profileHandicapGoalDesc =>
      'अपने ट्रेंड चार्ट पर ट्रैक करने के लिए एक लक्ष्य हैंडीकैप इंडेक्स निर्धारित करें।';

  @override
  String profileTargetPrefix(String value) {
    return 'लक्ष्य: $value';
  }

  @override
  String get profileNotSet => 'निर्धारित नहीं — सेट करने के लिए टैप करें';

  @override
  String get profileClear => 'साफ़ करें';

  @override
  String get profileSaveGoal => 'लक्ष्य सहेजें';

  @override
  String get profileSignOutTitle => 'साइन आउट करें?';

  @override
  String get profileSignOutBody => 'आपको लॉगिन स्क्रीन पर वापस किया जाएगा।';

  @override
  String get profileDeleteTitle => 'खाता हटाएं?';

  @override
  String get profileDeleteBody =>
      'यह आपका खाता और सभी गोल्फ डेटा सहित राउंड, आंकड़े और उपलब्धियां स्थायी रूप से हटा देगा।';

  @override
  String get profileDeleteAreYouSure => 'क्या आप बिल्कुल निश्चित हैं?';

  @override
  String get profileDeleteRoundsItem => 'आपके सभी राउंड और स्कोरकार्ड';

  @override
  String get profileDeleteStatsItem => 'आंकड़े, हैंडीकैप इतिहास और उपलब्धियां';

  @override
  String get profileDeleteProfileItem => 'आपकी प्रोफ़ाइल और प्राथमिकताएं';

  @override
  String get profileDeleteNotificationsItem => 'स्मार्ट सूचनाएं और टी टाइम';

  @override
  String get profileDeleteCannotUndo => 'यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get profileDeleteButton => 'मेरा खाता हटाएं';

  @override
  String get profileKeepButton => 'मेरा खाता रखें';

  @override
  String get profileDeletingAccount => 'खाता हटाया जा रहा है…';

  @override
  String get profileReauthRequired =>
      'अपना खाता हटाने से पहले कृपया साइन आउट करें और वापस साइन इन करें।';

  @override
  String get profileSomethingWrong => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get profileContinue => 'जारी रखें';

  @override
  String get profileDisplayName => 'प्रदर्शन नाम';

  @override
  String get profileSaveChanges => 'परिवर्तन सहेजें';

  @override
  String get profileChooseAvatar => 'अवतार चुनें';

  @override
  String get profileSelectPresetAvatar => 'एक प्रीसेट अवतार चुनें';

  @override
  String get profileRemoveAvatar => 'अवतार हटाएं';

  @override
  String get profileSaveAvatar => 'अवतार सहेजें';

  @override
  String get shotTrackerTapToMark => 'टी चिह्नित करने के लिए मैप पर टैप करें';

  @override
  String get shotTrackerTeeMarked =>
      'टी चिह्नित · शॉट ट्रैक करने के लिए टैप करें';

  @override
  String shotTrackerShotsFromTee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'टी से $count शॉट',
      one: 'टी से 1 शॉट',
    );
    return '$_temp0';
  }

  @override
  String get shotTrackerAcquiringGPS => 'GPS प्राप्त हो रहा है…';

  @override
  String shotTrackerDistToPin(String distance) {
    return 'पिन तक $distance गज';
  }

  @override
  String shotTrackerLastShot(String distance) {
    return 'आखिरी शॉट: $distance गज';
  }

  @override
  String get shotTrackerUndo => 'पूर्ववत करें';

  @override
  String get shotTrackerFinishHole => 'होल समाप्त करें';

  @override
  String shotTrackerFinishHoleWithCount(int count) {
    return 'होल समाप्त करें  ($count शॉट)';
  }

  @override
  String get shotTrackerNiceApproach => 'शानदार अप्रोच!';

  @override
  String shotTrackerOnGreen(String shotCount, int holeNumber) {
    return 'आप ग्रीन पर हैं — $shotCountहोल $holeNumber के पट लॉग करने के लिए तैयार?';
  }

  @override
  String get shotTrackerNotYet => 'अभी नहीं';

  @override
  String shotTrackerLogPutts(int holeNumber) {
    return 'होल $holeNumber के पट लॉग करें';
  }

  @override
  String get swingAnalyzerTitle => 'स्विंग एनालाइज़र';

  @override
  String get swingAnalyzerSaveToGallery => 'गैलरी में सहेजें';

  @override
  String get swingAnalyzerShare => 'शेयर करें';

  @override
  String get swingAnalyzerLoadingVideo => 'वीडियो लोड हो रहा है…';

  @override
  String get swingAnalyzerUploading => 'वीडियो अपलोड हो रहा है…';

  @override
  String get swingAnalyzerAnalyzing => 'बॉल फ्लाइट का विश्लेषण हो रहा है…';

  @override
  String get swingAnalyzerPreviewUnavailable =>
      'प्रीव्यू उपलब्ध नहीं — जहाँ बॉल है वहाँ टैप करें';

  @override
  String get swingAnalyzerTapBall => 'गोल्फ बॉल पर टैप करें';

  @override
  String get swingAnalyzerReposition => 'पुनः स्थित करने के लिए टैप करें';

  @override
  String get swingAnalyzerSkip => 'छोड़ें';

  @override
  String get swingAnalyzerAnalyze => 'विश्लेषण करें';

  @override
  String get swingAnalyzerAITracerTitle => 'AI स्विंग ट्रेसर';

  @override
  String get swingAnalyzerAITracerDesc =>
      'गोल्फ स्विंग वीडियो रिकॉर्ड या अपलोड करें।\nGemini AI बॉल ट्रैक करेगा और एक लाइव ट्रेसर ओवरले करेगा।';

  @override
  String get swingAnalyzerButton => 'स्विंग विश्लेषण करें';

  @override
  String get swingAnalyzerComingSoon => 'जल्द आ रहा है';

  @override
  String get swingAnalyzerComingSoonMsg =>
      'AI स्विंग ट्रेसर वर्तमान में विकास में है। अपडेट के लिए बने रहें!';

  @override
  String get swingAnalyzerGotIt => 'समझ गया';

  @override
  String get swingAnalyzerFailed => 'विश्लेषण विफल';

  @override
  String get swingAnalyzerFailedMsg =>
      'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get swingAnalyzerTryAgain => 'पुनः प्रयास करें';

  @override
  String get swingAnalyzerRecording => 'रिकॉर्डिंग';

  @override
  String get swingAnalyzerBallNotDetected => 'वीडियो में बॉल का पता नहीं चला';

  @override
  String get swingAnalyzerNoVideoFile => 'सहेजने के लिए कोई वीडियो फ़ाइल नहीं';

  @override
  String get swingAnalyzerVideoSaved => 'वीडियो गैलरी में सहेजा गया';

  @override
  String swingAnalyzerCouldNotSave(String error) {
    return 'वीडियो सहेज नहीं सका: $error';
  }

  @override
  String get swingAnalyzerShareText =>
      'TeeStats से मेरा स्विंग ट्रेस देखें! 🏌️';

  @override
  String get swingAnalyzerShotAnalysis => 'शॉट विश्लेषण';

  @override
  String get swingAnalyzerCarry => 'कैरी';

  @override
  String get swingAnalyzerHeight => 'ऊंचाई';

  @override
  String get swingAnalyzerLaunch => 'लॉन्च';

  @override
  String get swingAnalyzerPathNotDetected =>
      'बॉल पथ का पता नहीं चला। बेहतर रोशनी या नज़दीकी कोण आज़माएं।';

  @override
  String get swingAnalyzerAnotherSwing => 'एक और स्विंग विश्लेषण करें';

  @override
  String get scorecardUploadTitle => 'अपना स्कोरकार्ड स्कैन करें';

  @override
  String get scorecardUploadDesc =>
      'AI पार, यार्डेज और हैंडीकैप सहित होल-दर-होल डेटा निकालेगा।';

  @override
  String get scorecardUploadChooseSource => 'स्रोत चुनें';

  @override
  String get scorecardUploadTakePhoto => 'फोटो लें';

  @override
  String get scorecardUploadFromGallery => 'गैलरी से चुनें';

  @override
  String get scorecardUploadAnalyzing => 'स्कोरकार्ड का विश्लेषण हो रहा है…';

  @override
  String get scorecardUploadAnalyzingNote =>
      'इसमें आमतौर पर कुछ सेकंड लगते हैं';

  @override
  String get scorecardUploadReviewTitle => 'स्कोरकार्ड समीक्षा करें';

  @override
  String get scorecardUploadUploadTitle => 'स्कोरकार्ड अपलोड करें';

  @override
  String get scorecardUploadCourseName => 'कोर्स का नाम';

  @override
  String get scorecardUploadCourseNameHint => 'कोर्स का नाम दर्ज करें';

  @override
  String get scorecardUploadCityState => 'शहर, राज्य';

  @override
  String get scorecardUploadSelectTee => 'टी चुनें';

  @override
  String get scorecardUploadRetake => 'फिर से लें';

  @override
  String get scorecardUploadSaveUse => 'सहेजें और उपयोग करें';

  @override
  String get scorecardUploadNoTeeData =>
      'कोई टी डेटा नहीं निकाला गया। अधिक स्पष्ट फोटो आज़माएं।';

  @override
  String scorecardUploadFailed(String error) {
    return 'निष्कर्षण विफल। अधिक स्पष्ट फोटो आज़माएं।\n$error';
  }

  @override
  String get scorecardUploadRating => 'रेटिंग';

  @override
  String get scorecardUploadSlope => 'स्लोप';

  @override
  String get scorecardUploadHoleHeader => 'होल';

  @override
  String get scorecardUploadParHeader => 'पार';

  @override
  String get scorecardUploadYdsHeader => 'गज';

  @override
  String get scorecardUploadHcpHeader => 'HCP';

  @override
  String scorecardUploadRatingFooter(String rating) {
    return 'रेटिंग $rating';
  }

  @override
  String scorecardUploadSlopeFooter(String slope) {
    return 'स्लोप $slope';
  }

  @override
  String get scorecardUploadValidation => 'कृपया कोर्स का नाम दर्ज करें।';

  @override
  String get scorecardUploadMissingScores => 'कुछ स्कोर अनुपस्थित हैं';

  @override
  String get scorecardUploadMissingMsg =>
      'कुछ होल अभी भी 0 दिखाते हैं। उन्हें 0 स्ट्रोक के रूप में सहेजा जाएगा — आप आयात के बाद उन्हें संपादित कर सकते हैं।';

  @override
  String get scorecardUploadImportAnyway => 'फिर भी आयात करें';

  @override
  String get scorecardUploadFixFirst => 'पहले ठीक करें';

  @override
  String get scorecardImportCourse => 'कोर्स';

  @override
  String get scorecardImportCourseNameHint => 'कोर्स का नाम';

  @override
  String get scorecardImportLocationHint => 'स्थान — ऊपर एक कोर्स खोजें';

  @override
  String get scorecardImportNoCoursesFound => 'कोई गोल्फ कोर्स नहीं मिला';

  @override
  String get scorecardImportButton => 'आयात करें';

  @override
  String get scorecardImportConditions => 'राउंड की स्थितियां';

  @override
  String get scorecardImportAvgTemp => 'औसत तापमान';

  @override
  String get scorecardImportAvgWind => 'औसत हवा';

  @override
  String get scorecardImportConditionsLabel => 'स्थितियां';

  @override
  String get scorecardImportWeatherUnavailable => 'मौसम उपलब्ध नहीं';

  @override
  String get scorecardImportToday => 'आज';

  @override
  String get scorecardImportHowToAdd =>
      'आप अपना स्कोरकार्ड कैसे जोड़ना चाहेंगे?';

  @override
  String get scorecardImportTakePhoto => 'फोटो लें';

  @override
  String get scorecardImportPhotoDesc => 'अपने कागज़ी स्कोरकार्ड की फोटो लें';

  @override
  String get scorecardImportFromLibrary => 'लाइब्रेरी से चुनें';

  @override
  String get scorecardImportLibraryDesc => 'एक मौजूदा फोटो चुनें';

  @override
  String get scorecardImportReading => 'आपका स्कोरकार्ड पढ़ा जा रहा है…';

  @override
  String get scorecardImportAnalyzing =>
      'AI से विश्लेषण हो रहा है — इसमें कुछ सेकंड लगते हैं';

  @override
  String get scorecardImportUnableRead => 'स्कोरकार्ड पढ़ने में असमर्थ';

  @override
  String get scorecardImportConnectionError =>
      'AI सेवा तक नहीं पहुंचा जा सका। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get notifPersonalBestTitle => '🏆 नया व्यक्तिगत सर्वश्रेष्ठ!';

  @override
  String notifPersonalBestMsg(String score) {
    return 'आपने $score स्कोर किया — अब तक का आपका सर्वश्रेष्ठ राउंड। इसी तरह जारी रखें!';
  }

  @override
  String get notifTeeTime1HourTitle => '⛳ 1 घंटे में टी टाइम!';

  @override
  String notifTeeTime1HourMsg(String courseName) {
    return '$courseName पर अपने राउंड के लिए तैयार हो जाएं।';
  }

  @override
  String get notifTeeTime15MinTitle => '⛳ 15 मिनट में टी टाइम!';

  @override
  String notifTeeTime15MinMsg(String courseName) {
    return '$courseName पर पहले टी की ओर जाएं।';
  }

  @override
  String get notifStreakTitle => '⛳ कोर्स पर जाने का समय!';

  @override
  String get notifStreakMsg =>
      'आपके पिछले राउंड के बाद काफी समय हो गया है। निकल पड़ें!';

  @override
  String get noNotificationsTitle => 'अभी तक कोई सूचना नहीं';

  @override
  String get noNotificationsDesc =>
      'AI-व्यक्तिगत अलर्ट अनलॉक करने के लिए\nअधिक राउंड खेलें';

  @override
  String get widgetLeaderboardTitle => 'लाइव लीडरबोर्ड';

  @override
  String get widgetLeaderboardUpdates => 'प्रत्येक होल के बाद अपडेट';

  @override
  String get widgetLeaderboardPos => 'स्थान';

  @override
  String get widgetLeaderboardPlayer => 'खिलाड़ी';

  @override
  String get widgetLeaderboardThru => 'थ्रू';

  @override
  String get widgetLeaderboardScore => 'स्कोर';

  @override
  String widgetLeaderboardThruHoles(String holes) {
    return 'थ्रू $holes';
  }

  @override
  String get widgetLeaderboardTeeOff => 'टी ऑफ';

  @override
  String get widgetLeaderboardFinished => 'F';

  @override
  String get widgetLeaderboardInvited => 'आमंत्रित';

  @override
  String get widgetLeaderboardDeclined => 'अस्वीकृत';

  @override
  String get widgetUnfinishedRound => 'अधूरा राउंड';

  @override
  String widgetHolesPlayed(int played, int total) {
    return '$played / $total होल खेले';
  }

  @override
  String get widgetResumeRound => 'राउंड फिर शुरू करें';

  @override
  String get widgetDiscardTitle => 'राउंड छोड़ें?';

  @override
  String widgetDiscardMsg(String courseName) {
    return '\"$courseName\" पर सभी प्रगति स्थायी रूप से खो जाएगी।';
  }

  @override
  String get widgetKeep => 'रखें';

  @override
  String get widgetDiscard => 'छोड़ें';

  @override
  String get widgetClubsHint =>
      'प्रत्येक शॉट ट्रैक करने के लिए नीचे क्लब टैप करें';

  @override
  String widgetClubsSelected(int count, int max) {
    return '$max में से $count क्लब चुने गए';
  }

  @override
  String get widgetGolfDNA => 'गोल्फ DNA';

  @override
  String get widgetProAnalysis => 'प्रो विश्लेषण';

  @override
  String get widgetPower => 'शक्ति';

  @override
  String get widgetAccuracy => 'सटीकता';

  @override
  String get widgetPutting => 'पटिंग';

  @override
  String get widgetStrengthsWeaknesses => 'ताकत और कमज़ोरियां';

  @override
  String get widgetPerformanceTrends => 'प्रदर्शन रुझान';

  @override
  String get widgetTraitAnalysis => 'विशेषता विश्लेषण';

  @override
  String get widgetDrivingPower => 'ड्राइविंग शक्ति';

  @override
  String get widgetConsistency => 'निरंतरता';

  @override
  String get widgetRiskLevel => 'जोखिम स्तर';

  @override
  String get widgetStamina => 'सहनशक्ति';

  @override
  String get widgetAIRoundSummary => 'AI राउंड सारांश';

  @override
  String get widgetAnalyzingRound => 'आपके राउंड का विश्लेषण हो रहा है…';

  @override
  String get widgetGemini => 'Gemini';

  @override
  String get widgetStrength => 'ताकत';

  @override
  String get widgetWeakness => 'कमज़ोरी';

  @override
  String get widgetFocusArea => 'फोकस क्षेत्र';

  @override
  String get widgetPlayStyle => 'प्ले स्टाइल';

  @override
  String get widgetAIPowered => 'AI संचालित';

  @override
  String widgetUpdated(String date) {
    return '$date को अपडेट किया गया';
  }

  @override
  String get widgetUpdatedToday => 'आज';

  @override
  String get widgetUpdatedYesterday => 'कल';

  @override
  String widgetUpdatedDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String get timeJustNow => 'अभी-अभी';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String get nearbyTitle => 'पास में';

  @override
  String get nearbyCheckInTitle => 'पास के गोल्फर खोजें';

  @override
  String get nearbyCheckInBody =>
      'अपने कोर्स पर चेक-इन करें और ग्रुप खोज रहे खिलाड़ियों को देखें';

  @override
  String get nearbyCheckIn => 'चेक-इन';

  @override
  String get nearbyCheckedIn => 'आप चेक-इन हैं';

  @override
  String get nearbyLookingForGroup => 'ग्रुप की तलाश में';

  @override
  String get nearbyLeave => 'छोड़ें';

  @override
  String get nearbyNoOneNearby => 'अभी कोई गोल्फर ग्रुप नहीं खोज रहा';

  @override
  String get nearbyTogglePrompt =>
      'पास के गोल्फर देखने के लिए ऊपर \'ग्रुप की तलाश में\' चालू करें';

  @override
  String get nearbyRequestJoin => 'जुड़ने का अनुरोध';

  @override
  String get nearbyRequestSent => 'भेजा गया';

  @override
  String get nearbyNotAtCourse =>
      '1 किमी के भीतर कोई गोल्फ कोर्स नहीं मिला। किसी कोर्स के पास जाएं।';

  @override
  String nearbyHcp(String value) {
    return 'HCP: $value';
  }
}
