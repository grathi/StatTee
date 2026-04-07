// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TeeStats';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get search => 'Search';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get view => 'View';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get home => 'Home';

  @override
  String get rounds => 'Rounds';

  @override
  String get stats => 'Stats';

  @override
  String get profile => 'Profile';

  @override
  String get friends => 'Friends';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSignInToContinue => 'Sign in to continue';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginSignIn => 'Sign In';

  @override
  String get loginDontHaveAccount => 'Don\'t have an account?';

  @override
  String get loginSignUp => 'Sign Up';

  @override
  String get loginTagline => 'Play  ·  Track  ·  Improve';

  @override
  String get loginResetPasswordTitle => 'Reset Password';

  @override
  String get loginResetPasswordSubtitle =>
      'We\'ll send a reset link to your email';

  @override
  String get loginEnterYourEmail => 'Enter your email';

  @override
  String get loginEnterValidEmail => 'Enter a valid email';

  @override
  String get loginSendResetLink => 'Send Reset Link';

  @override
  String get loginResetLinkSent => 'Reset link sent!';

  @override
  String loginCheckInboxFor(String email) {
    return 'Check your inbox for $email';
  }

  @override
  String get loginErrorNoAccount => 'No account found with this email.';

  @override
  String get loginErrorInvalidEmail => 'Please enter a valid email.';

  @override
  String get loginErrorSomethingWrong => 'Something went wrong. Try again.';

  @override
  String get loginErrorIncorrectCredentials => 'Incorrect email or password.';

  @override
  String get loginErrorAccountDisabled => 'This account has been disabled.';

  @override
  String get loginErrorTooManyAttempts => 'Too many attempts. Try again later.';

  @override
  String get loginErrorTryAgain => 'Something went wrong. Please try again.';

  @override
  String get signupCreateAccount => 'Create Account';

  @override
  String get signupJoinToday => 'Join TeeStats today';

  @override
  String get signupFullName => 'Full Name';

  @override
  String get signupEnterYourName => 'Enter your name';

  @override
  String get signupEmail => 'Email';

  @override
  String get signupPassword => 'Password';

  @override
  String get signupConfirmPassword => 'Confirm Password';

  @override
  String get signupEnterPassword => 'Enter a password';

  @override
  String get signupMinimumChars => 'Minimum 6 characters';

  @override
  String get signupConfirmYourPassword => 'Confirm your password';

  @override
  String get signupPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String signupPasswordStrength(String label) {
    return 'Password strength: $label';
  }

  @override
  String get signupPasswordWeak => 'Weak';

  @override
  String get signupPasswordFair => 'Fair';

  @override
  String get signupPasswordGood => 'Good';

  @override
  String get signupPasswordStrong => 'Strong';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account?';

  @override
  String get signupErrorAccountExists =>
      'An account with this email already exists.';

  @override
  String get signupErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get signupErrorWeakPassword =>
      'Password must be at least 6 characters.';

  @override
  String get signupErrorNotEnabled => 'Email sign-up is not enabled.';

  @override
  String get onboardingTagline => 'Swing. Track. Win.';

  @override
  String get onboardingScoreTrackingTag => 'SCORE TRACKING';

  @override
  String get onboardingTrackEveryRoundTitle => 'Track Every\nRound';

  @override
  String get onboardingScoreTrackingBody =>
      'GPS-powered scoring for every hole. Your complete round history, always in your pocket.';

  @override
  String get onboardingPerformanceTag => 'PERFORMANCE';

  @override
  String get onboardingGolfDNATitle => 'Know Your\nGolf DNA';

  @override
  String get onboardingPerformanceBody =>
      'Fairways hit, GIR, putts per round, handicap trends — pinpoint exactly where to improve.';

  @override
  String get onboardingMultiplayerTag => 'MULTIPLAYER';

  @override
  String get onboardingPlayTogetherTitle => 'Play\nTogether';

  @override
  String get onboardingMultiplayerBody =>
      'Invite friends to a live group round. Real-time leaderboard, zero extra scorekeeping.';

  @override
  String get onboardingSocialTag => 'SOCIAL';

  @override
  String get onboardingFriendsLeaderboardTitle => 'Friends &\nLeaderboard';

  @override
  String get onboardingSocialBody =>
      'Connect with your golf crew. See who\'s on a hot streak and challenge them to beat you.';

  @override
  String get onboardingAITag => 'AI POWERED';

  @override
  String get onboardingPersonalCaddieTitle => 'Your Personal\nCaddie';

  @override
  String get onboardingAIBody =>
      'After every round, Gemini AI analyses your stats and delivers coaching insights — strengths, weaknesses and a focus area to sharpen next time.';

  @override
  String get onboardingPoweredByGemini => 'Powered by Google Gemini';

  @override
  String get homeReadyToPlay => '⛳  Ready to play?';

  @override
  String get homeStartRound => 'Start Round';

  @override
  String get homeTapToTeeOff => 'Tap to tee off';

  @override
  String get homeGolfNews => 'Golf News';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeRecentRounds => 'Recent Rounds';

  @override
  String get homeViewAll => 'View all';

  @override
  String get homeNoRoundsYet => 'No rounds yet — start your first!';

  @override
  String get homeInProgress => 'In Progress';

  @override
  String get homeActive => 'Active';

  @override
  String get homeNoLocation => 'No location';

  @override
  String get homePerformance => 'Performance';

  @override
  String get homeCompleteRoundsForStats =>
      'Complete rounds to see your handicap and performance stats.';

  @override
  String get homeHandicapIndex => 'Handicap Index';

  @override
  String homeRoundsNeeded(int n) {
    return '$n/20 rounds';
  }

  @override
  String homeMoreRoundsToUnlock(int n) {
    return '$n more rounds to unlock your Handicap Index';
  }

  @override
  String get homeFairwaysHit => 'Fairways Hit';

  @override
  String get homePar4And5 => 'Par 4 & 5 holes';

  @override
  String get homeGIR => 'Greens in Reg.';

  @override
  String get homeAllHoles => 'All holes';

  @override
  String get homeAvgPutts => 'Avg Putts';

  @override
  String get homePerHole => 'Per hole';

  @override
  String get homeBirdies => 'Birdies';

  @override
  String get homeAllRounds => 'All rounds';

  @override
  String get homeToday => 'Today';

  @override
  String get homeYesterday => 'Yesterday';

  @override
  String homeDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String get homeWeekAgo => '1 week ago';

  @override
  String get homeTwoWeeksAgo => '2 weeks ago';

  @override
  String get homeThreeWeeksAgo => '3 weeks ago';

  @override
  String homeMonthsAgo(int n) {
    return '$n months ago';
  }

  @override
  String homeInvitedToPlay(String name) {
    return '$name invited you to play';
  }

  @override
  String get homeChangeLocation => 'Change Location';

  @override
  String get homeSearchCityOrArea => 'Search a city or area';

  @override
  String get homeLocationHint => 'e.g. Dubai, London, New York…';

  @override
  String get homeSearchLocation => 'Search Location';

  @override
  String get homeLocationNotFound =>
      'Location not found. Try a different city name.';

  @override
  String get homeUseCurrentLocation => 'Use my current location';

  @override
  String get homeWelcomeTour => 'Welcome to TeeStats';

  @override
  String get homeWelcomeTourBody =>
      'This is your home — see recent rounds, performance and nearby courses at a glance.';

  @override
  String get homeFriendsAndLeaderboard => 'Friends & Leaderboard';

  @override
  String get homeFriendsAndLeaderboardBody =>
      'Add golf buddies, accept friend requests, and compare scores on the leaderboard. A green dot appears when you have a pending request.';

  @override
  String get homeStartARound => 'Start a Round';

  @override
  String get homeStartARoundBody =>
      'Tap the green button anytime to start scoring a new round at any course.';

  @override
  String get homeYourActiveRound => 'Your Active Round';

  @override
  String get homeResumeRoundBody =>
      'If you leave mid-round, it\'s saved here. Tap Resume to pick up where you left off.';

  @override
  String get homeRoundHistory => 'Round History';

  @override
  String get homeRoundHistoryBody =>
      'All your completed rounds live here. Tap any round for a full hole-by-hole breakdown.';

  @override
  String get homeYourStats => 'Your Stats';

  @override
  String get homeYourStatsBody =>
      'Track your handicap trend, scoring patterns, GIR, fairways and strokes gained over time.';

  @override
  String get homeYourProfile => 'Your Profile';

  @override
  String get homeYourProfileBody =>
      'Set your handicap goal, pick an avatar, and view your Golf DNA and Play Style identity.';

  @override
  String get homeQuickStats => 'Quick Stats';

  @override
  String get homeQuickStatsBody =>
      'Live averages across all your rounds — fairways, GIR, putts and birdies per round.';

  @override
  String get homeNearbyCourses => 'Nearby Courses';

  @override
  String get homeNearbyCoursesBody =>
      'Golf courses near your location. Tap any course to start a round there instantly.';

  @override
  String get roundsMyRounds => 'My Rounds';

  @override
  String get roundsRoundsTab => 'Rounds';

  @override
  String get roundsPracticeTab => 'Practice';

  @override
  String get roundsTournamentsTab => 'Tournaments';

  @override
  String get roundsHistoryTitle => 'Your Round History';

  @override
  String get roundsHistorySubtitle =>
      'All completed rounds are here. Tap any round for a full hole-by-hole breakdown and stats.';

  @override
  String get roundsInProgress => 'Round in Progress';

  @override
  String roundsHolesProgress(int played, int total) {
    return '$played/$total holes';
  }

  @override
  String get roundsNoRoundsYet => 'No rounds yet';

  @override
  String get roundsStartFirst => 'Start your first round from the Home tab';

  @override
  String get roundsOrScanScorecard => 'or scan a paper scorecard';

  @override
  String get roundsDeleteTitle => 'Delete Round?';

  @override
  String roundsDeleteConfirm(String courseName) {
    return 'Permanently remove your round at $courseName?';
  }

  @override
  String get roundsBirdies => 'Birdies';

  @override
  String get roundsPars => 'Pars';

  @override
  String get roundsBogeys => 'Bogeys';

  @override
  String get roundsPutts => 'Putts';

  @override
  String get roundsFIR => 'FIR';

  @override
  String get roundSummaryComplete => 'Round Complete!';

  @override
  String get roundSummaryScore => 'Score';

  @override
  String get roundSummaryVsPar => 'vs Par';

  @override
  String get roundSummaryHoles => 'Holes';

  @override
  String get roundSummaryBackToHome => 'Back to Home';

  @override
  String get roundSummaryEven => 'Even';

  @override
  String get roundDetailScorecard => 'Scorecard';

  @override
  String get roundDetailShotTrails => 'Shot Trails';

  @override
  String get roundDetailHole => 'Hole';

  @override
  String get roundDetailPar => 'Par';

  @override
  String get roundDetailGIR => 'GIR';

  @override
  String get roundDetailTotal => 'TOT';

  @override
  String get roundDetailShare => 'Share scorecard';

  @override
  String get roundDetailDelete => 'Delete round';

  @override
  String get roundDetailDeleteTitle => 'Delete Round?';

  @override
  String roundDetailDeleteConfirm(String courseName) {
    return 'This will permanently remove your round at $courseName.';
  }

  @override
  String get startRoundPickCourse => '📍  Pick your course';

  @override
  String get startRoundWherePlaying => 'Where are\nyou playing?';

  @override
  String get startRoundSearchHint => 'Search for a nearby golf course';

  @override
  String get startRoundCourseName => 'Course Name';

  @override
  String get startRoundEnterCourseName => 'Enter course name';

  @override
  String get startRoundFetchingTeeData => 'Fetching tee data…';

  @override
  String get startRoundSelectTee => 'SELECT TEE';

  @override
  String get startRoundCourseRating => 'COURSE RATING (OPTIONAL)';

  @override
  String get startRoundRatingForHandicap =>
      'For an accurate USGA Handicap Index';

  @override
  String get startRoundCourseRatingLabel => 'Course Rating';

  @override
  String get startRoundCourseRatingHint => 'e.g. 72.5';

  @override
  String get startRoundSlopeRatingLabel => 'Slope Rating';

  @override
  String get startRoundSlopeRatingHint => 'e.g. 113';

  @override
  String get startRoundSlopeError => '55–155';

  @override
  String get startRoundNumberOfHoles => 'NUMBER OF HOLES';

  @override
  String get startRoundHoles => 'Holes';

  @override
  String get startRoundInviteFriends => 'INVITE FRIENDS (MAX 3)';

  @override
  String get startRoundSearchFriends => 'Search friends…';

  @override
  String get startRoundNoFriends => 'No friends yet.';

  @override
  String get startRoundNoMatches => 'No matches.';

  @override
  String startRoundFriendsInvited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends will be invited',
      one: '1 friend will be invited',
    );
    return '$_temp0';
  }

  @override
  String get startRoundTeeOff => 'Tee Off!';

  @override
  String get startRoundNoCoursesFound => 'No golf courses found nearby';

  @override
  String get startRoundNoHoleData => 'No hole data found for this course.';

  @override
  String get startRoundUploadScorecard => 'Upload Scorecard';

  @override
  String startRoundError(String error) {
    return 'Error: $error';
  }

  @override
  String get scorecardScoringARound => 'Scoring a Round';

  @override
  String get scorecardInstructions =>
      'Enter your score, putts, fairway and GIR for each hole. Tap the club to track your club selection.';

  @override
  String get scorecardHole => 'Hole';

  @override
  String get scorecardPlayingWithFriends => 'Playing with friends';

  @override
  String get scorecardScore => 'SCORE';

  @override
  String get scorecardPutts => 'PUTTS';

  @override
  String get scorecardFairwayHit => 'FAIRWAY HIT';

  @override
  String get scorecardGIR => 'GREEN IN REGULATION';

  @override
  String get scorecardTrackShots => 'Track shots';

  @override
  String get scorecardTeeSet => 'Tee set';

  @override
  String scorecardShotsTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shots tracked',
      one: '1 shot tracked',
    );
    return '$_temp0';
  }

  @override
  String get scorecardClub => 'CLUB';

  @override
  String get scorecardScorecardLabel => 'SCORECARD';

  @override
  String get scorecardLeaveTitle => 'Leave Round?';

  @override
  String get scorecardLeaveBody =>
      'Your progress is saved automatically.\nYou can resume this round from the home screen.';

  @override
  String get scorecardSaveAndExit => 'Save & Exit';

  @override
  String get scorecardKeepPlaying => 'Keep Playing';

  @override
  String get scorecardAbandon => 'Abandon';

  @override
  String get scorecardNextHole => 'Next Hole';

  @override
  String get scorecardFinishRound => 'Finish Round';

  @override
  String get scorecardAICaddy => 'AI CADDY';

  @override
  String get scorecardTipPar3 =>
      'Par 3: commit to one club and trust the swing.';

  @override
  String get scorecardTipInsightsUnlock =>
      'Play your game — insights unlock after 3 holes.';

  @override
  String scorecardTipAvgPutts(String avgPutts) {
    return 'Averaging $avgPutts putts — focus on lag putting from distance.';
  }

  @override
  String scorecardTipFairways(String fwhitPercent) {
    return 'Only $fwhitPercent% fairways hit — consider a 3-wood off the tee.';
  }

  @override
  String get scorecardTipApproach =>
      'Approaches struggling — aim for the fat of the green today.';

  @override
  String get scorecardTipSolid =>
      'Solid round so far — keep the same rhythm and tempo.';

  @override
  String get scorecardYds => 'YDS';

  @override
  String scorecardPlaysLike(String distance) {
    return 'PLAYS LIKE $distance YDS';
  }

  @override
  String get scorecardEagle => 'Eagle';

  @override
  String get scorecardAlbatross => 'Albatross';

  @override
  String get scorecardBirdie => 'Birdie';

  @override
  String get scorecardPar => 'Par';

  @override
  String get scorecardBogey => 'Bogey';

  @override
  String get scorecardDouble => 'Double';

  @override
  String scorecardEditHole(int hole) {
    return 'Edit Hole $hole';
  }

  @override
  String scorecardErrorSaving(String error) {
    return 'Error saving: $error';
  }

  @override
  String get scorecardOn => 'ON';

  @override
  String get scorecardOff => 'OFF';

  @override
  String get statsHub => 'Your Stats Hub';

  @override
  String get statsPlayMoreRounds =>
      'Play more rounds to unlock trend charts, strokes gained and score distribution analysis.';

  @override
  String get statsHandicapIndex => 'Handicap Index';

  @override
  String statsBasedOnRounds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Based on $n rounds',
      one: 'Based on 1 round',
    );
    return '$_temp0';
  }

  @override
  String get statsCompleteToCalculate => 'Complete rounds to calculate';

  @override
  String get statsAvgScore => 'Avg Score';

  @override
  String get statsBestRound => 'Best Round';

  @override
  String get statsTotalRounds => 'Total Rounds';

  @override
  String get statsTotalBirdies => 'Total Birdies';

  @override
  String get statsScoreDistribution => 'Score Distribution';

  @override
  String get statsEagles => 'Eagles';

  @override
  String get statsBirdies => 'Birdies';

  @override
  String get statsPars => 'Pars';

  @override
  String get statsBogeys => 'Bogeys';

  @override
  String get statsDoublePlus => 'Double+';

  @override
  String statsScoreVsPar(int n) {
    return 'Score vs Par (Last $n Rounds)';
  }

  @override
  String get statsOldestToRecent => 'Oldest → Most Recent';

  @override
  String get statsHandicapTrend => 'Handicap Trend';

  @override
  String statsGoal(String n) {
    return 'Goal: $n';
  }

  @override
  String statsLatest(String n) {
    return 'Latest: $n';
  }

  @override
  String get statsFairwaysHit => 'Fairways Hit';

  @override
  String get statsGIR => 'Greens in Regulation';

  @override
  String get statsAvgPuttsPerHole => 'Avg Putts / Hole';

  @override
  String get statsClubStats => 'Club Stats';

  @override
  String get statsClubStatsSubtitle => 'Score vs par & avg putts per club';

  @override
  String get statsClub => 'Club';

  @override
  String get statsHoles => 'Holes';

  @override
  String get statsAvgPlusMinus => 'Avg ±Par';

  @override
  String get statsAvgPutts => 'Avg Putts';

  @override
  String get statsStrokesGained => 'Strokes Gained';

  @override
  String get statsVsScratch => 'vs scratch golfer baseline';

  @override
  String get statsOffTheTee => 'Off the Tee';

  @override
  String get statsApproach => 'Approach';

  @override
  String get statsAroundGreen => 'Around Green';

  @override
  String get statsPutting => 'Putting';

  @override
  String get statsBetterThanAvg => 'Better\nthan avg';

  @override
  String get tournamentNoTournaments => 'No tournaments yet';

  @override
  String get tournamentCreateInstructions =>
      'Tap \"New Tournament\" to create one,\nthen start rounds to score for the tournament.';

  @override
  String get tournamentNew => 'New Tournament';

  @override
  String get tournamentStartInstructions =>
      'Create a tournament first, then use the ＋ FAB on the home screen to start a tournament round.';

  @override
  String get tournamentDeleteTitle => 'Delete Tournament?';

  @override
  String tournamentDeleteConfirm(String name) {
    return 'Remove \"$name\"? The rounds themselves will not be deleted.';
  }

  @override
  String get tournamentRoundByRound => 'Round by Round';

  @override
  String get tournamentVsPar => 'vs Par';

  @override
  String get tournamentRoundsLabel => 'Rounds';

  @override
  String get tournamentNameLabel => 'Tournament Name';

  @override
  String get tournamentNameHint => 'e.g. Club Championship 2026';

  @override
  String get tournamentCreate => 'Create Tournament';

  @override
  String tournamentRoundsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rounds',
      one: '1 round',
    );
    return '$_temp0';
  }

  @override
  String get tournamentRunning => 'running';

  @override
  String get practiceNoSessions => 'No practice sessions yet';

  @override
  String get practiceStartInstructions =>
      'Start a round to score holes,\nor log range and short-game sessions.';

  @override
  String get practiceLogSession => 'Log Session';

  @override
  String get practiceScoredRound => 'Scored Round';

  @override
  String get practiceDeleteTitle => 'Delete Session?';

  @override
  String get practiceDeleteConfirm =>
      'This practice session will be permanently removed.';

  @override
  String get practiceLogTitle => 'Log Practice Session';

  @override
  String get practiceType => 'Type';

  @override
  String get practiceBallsHit => 'Balls hit';

  @override
  String get practiceDuration => 'Duration (min)';

  @override
  String get practiceNotes => 'Notes (optional)';

  @override
  String get practiceNotesHint => 'What did you work on?';

  @override
  String get practiceSave => 'Save Session';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsLeaderboard => 'Leaderboard';

  @override
  String get friendsNoFriendsYet => 'No friends yet';

  @override
  String get friendsEnterEmail => 'Enter a friend\'s email above to add them';

  @override
  String get friendsSearchHint => 'Search by email address…';

  @override
  String get friendsPendingRequests => 'Pending Requests';

  @override
  String get friendsWantsToBeF => 'Wants to be friends';

  @override
  String get friendsRequestSent => 'Request Sent';

  @override
  String get friendsAcceptRequest => 'Accept Request';

  @override
  String get friendsAlreadyFriends => 'Already Friends';

  @override
  String get friendsAddFriend => 'Add Friend';

  @override
  String get friendsNoLeaderboard => 'No leaderboard yet';

  @override
  String get friendsAddToCompare => 'Add friends to compare scores';

  @override
  String get friendsHandicap => 'Handicap';

  @override
  String get friendsAvgScore => 'Avg Score';

  @override
  String get friendsYou => 'You';

  @override
  String get notifPrefsTitle => 'Smart Notifications';

  @override
  String get notifPrefsSubtitle => 'AI-powered alerts for your game';

  @override
  String get notifPrefsSectionTitle => 'NOTIFICATION TYPES';

  @override
  String get notifPrefsPracticeReminders => 'Practice Reminders';

  @override
  String get notifPrefsPracticeDesc =>
      'AI-tailored drills for your weakest areas';

  @override
  String get notifPrefsResumeRound => 'Resume Round';

  @override
  String get notifPrefsResumeDesc =>
      'Nudges to complete rounds you left unfinished';

  @override
  String get notifPrefsPerformance => 'Performance Insights';

  @override
  String get notifPrefsPerformanceDesc =>
      'Celebrate improvement streaks and trends';

  @override
  String get notifPrefsTeeTime => 'Tee Time Reminders';

  @override
  String get notifPrefsTeeTimeDesc => 'Alerts before upcoming tee times';

  @override
  String get notifPrefsSaved => 'Preferences saved';

  @override
  String get notifPrefsPersonalised =>
      'Notifications are personalised based on your\nrecent rounds and performance trends.';

  @override
  String get notifPrefsAIDriven => '✨ AI-Driven Alerts';

  @override
  String get notifPrefsSmartDesc =>
      'Smart notifications\ntailored to your golf game';

  @override
  String get notifPrefsExplanation =>
      'TeeStats analyses your rounds, practice habits, and performance trends to send notifications that actually help your game.';

  @override
  String get notifPrefsSave => 'Save Preferences';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSubtitle => 'Make It Yours';

  @override
  String get profileDescription =>
      'Set your handicap goal, pick an avatar, and explore your Golf DNA and Play Style.';

  @override
  String get profileGolfer => 'Golfer';

  @override
  String get profileGolfPlaces => 'Golf Places';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileSmartNotifications => 'Smart Notifications';

  @override
  String get profileAchievementsSection => 'ACHIEVEMENTS';

  @override
  String get profileRounds => 'Rounds';

  @override
  String get profileHandicap => 'Handicap';

  @override
  String get profileBirdies => 'Birdies';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String profileVersion(String version) {
    return 'TeeStats v$version';
  }

  @override
  String profileCopyright(String year) {
    return '© $year TeeStats. All rights reserved.';
  }

  @override
  String get profileHandicapGoal => 'Handicap Goal';

  @override
  String get profileHandicapGoalDesc =>
      'Set a target handicap index to track on your trend chart.';

  @override
  String profileTargetPrefix(String value) {
    return 'Target: $value';
  }

  @override
  String get profileNotSet => 'Not set — tap to set';

  @override
  String get profileClear => 'Clear';

  @override
  String get profileSaveGoal => 'Save Goal';

  @override
  String get profileSignOutTitle => 'Sign Out?';

  @override
  String get profileSignOutBody => 'You will be returned to the login screen.';

  @override
  String get profileDeleteTitle => 'Delete Account?';

  @override
  String get profileDeleteBody =>
      'This will permanently delete your account and all your golf data including rounds, stats, and achievements.';

  @override
  String get profileDeleteAreYouSure => 'Are you absolutely sure?';

  @override
  String get profileDeleteRoundsItem => 'All your rounds and scorecards';

  @override
  String get profileDeleteStatsItem =>
      'Stats, handicap history and achievements';

  @override
  String get profileDeleteProfileItem => 'Your profile and preferences';

  @override
  String get profileDeleteNotificationsItem =>
      'Smart notifications and tee times';

  @override
  String get profileDeleteCannotUndo => 'This action cannot be undone.';

  @override
  String get profileDeleteButton => 'Delete My Account';

  @override
  String get profileKeepButton => 'Keep My Account';

  @override
  String get profileDeletingAccount => 'Deleting account…';

  @override
  String get profileReauthRequired =>
      'Please sign out and sign back in before deleting your account.';

  @override
  String get profileSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get profileContinue => 'Continue';

  @override
  String get profileDisplayName => 'Display Name';

  @override
  String get profileSaveChanges => 'Save Changes';

  @override
  String get profileChooseAvatar => 'Choose Avatar';

  @override
  String get profileSelectPresetAvatar => 'Select a preset avatar';

  @override
  String get profileRemoveAvatar => 'Remove Avatar';

  @override
  String get profileSaveAvatar => 'Save Avatar';

  @override
  String get shotTrackerTapToMark => 'Tap the map to mark the tee';

  @override
  String get shotTrackerTeeMarked => 'Tee marked · tap to track shots';

  @override
  String shotTrackerShotsFromTee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shots from tee',
      one: '1 shot from tee',
    );
    return '$_temp0';
  }

  @override
  String get shotTrackerAcquiringGPS => 'Acquiring GPS…';

  @override
  String shotTrackerDistToPin(String distance) {
    return '$distance yds to pin';
  }

  @override
  String shotTrackerLastShot(String distance) {
    return 'Last shot: $distance yds';
  }

  @override
  String get shotTrackerUndo => 'Undo';

  @override
  String get shotTrackerFinishHole => 'Finish Hole';

  @override
  String shotTrackerFinishHoleWithCount(int count) {
    return 'Finish Hole  ($count shots)';
  }

  @override
  String get shotTrackerNiceApproach => 'Nice approach!';

  @override
  String shotTrackerOnGreen(String shotCount, int holeNumber) {
    return 'You\'re on the green — ${shotCount}Ready to log putts for Hole $holeNumber?';
  }

  @override
  String get shotTrackerNotYet => 'Not yet';

  @override
  String shotTrackerLogPutts(int holeNumber) {
    return 'Log putts for Hole $holeNumber';
  }

  @override
  String get swingAnalyzerTitle => 'Swing Analyzer';

  @override
  String get swingAnalyzerSaveToGallery => 'Save to gallery';

  @override
  String get swingAnalyzerShare => 'Share';

  @override
  String get swingAnalyzerLoadingVideo => 'Loading video…';

  @override
  String get swingAnalyzerUploading => 'Uploading video…';

  @override
  String get swingAnalyzerAnalyzing => 'Analyzing ball flight…';

  @override
  String get swingAnalyzerPreviewUnavailable =>
      'Preview unavailable — tap where the ball is';

  @override
  String get swingAnalyzerTapBall => 'Tap on the golf ball';

  @override
  String get swingAnalyzerReposition => 'Tap to reposition';

  @override
  String get swingAnalyzerSkip => 'Skip';

  @override
  String get swingAnalyzerAnalyze => 'Analyze';

  @override
  String get swingAnalyzerAITracerTitle => 'AI Swing Tracer';

  @override
  String get swingAnalyzerAITracerDesc =>
      'Record or upload a golf swing video.\nGemini AI will track the ball and overlay a live tracer.';

  @override
  String get swingAnalyzerButton => 'Analyze Swing';

  @override
  String get swingAnalyzerComingSoon => 'Coming Soon';

  @override
  String get swingAnalyzerComingSoonMsg =>
      'AI Swing Tracer is currently under development. Stay tuned for the update!';

  @override
  String get swingAnalyzerGotIt => 'Got it';

  @override
  String get swingAnalyzerFailed => 'Analysis Failed';

  @override
  String get swingAnalyzerFailedMsg =>
      'Something went wrong. Please try again.';

  @override
  String get swingAnalyzerTryAgain => 'Try Again';

  @override
  String get swingAnalyzerRecording => 'REC';

  @override
  String get swingAnalyzerBallNotDetected => 'Ball not detected in video';

  @override
  String get swingAnalyzerNoVideoFile => 'No video file to save';

  @override
  String get swingAnalyzerVideoSaved => 'Video saved to gallery';

  @override
  String swingAnalyzerCouldNotSave(String error) {
    return 'Could not save video: $error';
  }

  @override
  String get swingAnalyzerShareText =>
      'Check out my swing trace from TeeStats! 🏌️';

  @override
  String get swingAnalyzerShotAnalysis => 'Shot Analysis';

  @override
  String get swingAnalyzerCarry => 'Carry';

  @override
  String get swingAnalyzerHeight => 'Height';

  @override
  String get swingAnalyzerLaunch => 'Launch';

  @override
  String get swingAnalyzerPathNotDetected =>
      'Ball path not detected. Try better lighting or a closer angle.';

  @override
  String get swingAnalyzerAnotherSwing => 'Analyze Another Swing';

  @override
  String get scorecardUploadTitle => 'Scan Your Scorecard';

  @override
  String get scorecardUploadDesc =>
      'AI will extract hole-by-hole data including par, yardage, and handicap.';

  @override
  String get scorecardUploadChooseSource => 'CHOOSE SOURCE';

  @override
  String get scorecardUploadTakePhoto => 'Take Photo';

  @override
  String get scorecardUploadFromGallery => 'Choose from Gallery';

  @override
  String get scorecardUploadAnalyzing => 'Analyzing scorecard…';

  @override
  String get scorecardUploadAnalyzingNote => 'This usually takes a few seconds';

  @override
  String get scorecardUploadReviewTitle => 'Review Scorecard';

  @override
  String get scorecardUploadUploadTitle => 'Upload Scorecard';

  @override
  String get scorecardUploadCourseName => 'COURSE NAME';

  @override
  String get scorecardUploadCourseNameHint => 'Enter course name';

  @override
  String get scorecardUploadCityState => 'City, State';

  @override
  String get scorecardUploadSelectTee => 'SELECT TEE';

  @override
  String get scorecardUploadRetake => 'Retake';

  @override
  String get scorecardUploadSaveUse => 'Save & Use';

  @override
  String get scorecardUploadNoTeeData =>
      'No tee data was extracted. Try a clearer photo.';

  @override
  String scorecardUploadFailed(String error) {
    return 'Extraction failed. Try a clearer photo.\n$error';
  }

  @override
  String get scorecardUploadRating => 'Rating';

  @override
  String get scorecardUploadSlope => 'Slope';

  @override
  String get scorecardUploadHoleHeader => 'HOLE';

  @override
  String get scorecardUploadParHeader => 'PAR';

  @override
  String get scorecardUploadYdsHeader => 'YDS';

  @override
  String get scorecardUploadHcpHeader => 'HCP';

  @override
  String scorecardUploadRatingFooter(String rating) {
    return 'Rating $rating';
  }

  @override
  String scorecardUploadSlopeFooter(String slope) {
    return 'Slope $slope';
  }

  @override
  String get scorecardUploadValidation => 'Please enter the course name.';

  @override
  String get scorecardUploadMissingScores => 'Some Scores Missing';

  @override
  String get scorecardUploadMissingMsg =>
      'A few holes still show 0. They\'ll be saved as 0 strokes — you can edit them after import.';

  @override
  String get scorecardUploadImportAnyway => 'Import Anyway';

  @override
  String get scorecardUploadFixFirst => 'Fix First';

  @override
  String get scorecardImportCourse => 'Course';

  @override
  String get scorecardImportCourseNameHint => 'Course name';

  @override
  String get scorecardImportLocationHint => 'Location — search a course above';

  @override
  String get scorecardImportNoCoursesFound => 'No golf courses found';

  @override
  String get scorecardImportButton => 'Import';

  @override
  String get scorecardImportConditions => 'Round Conditions';

  @override
  String get scorecardImportAvgTemp => 'Avg Temp';

  @override
  String get scorecardImportAvgWind => 'Avg Wind';

  @override
  String get scorecardImportConditionsLabel => 'Conditions';

  @override
  String get scorecardImportWeatherUnavailable => 'Weather unavailable';

  @override
  String get scorecardImportToday => 'Today';

  @override
  String get scorecardImportHowToAdd =>
      'How would you like to add your scorecard?';

  @override
  String get scorecardImportTakePhoto => 'Take a Photo';

  @override
  String get scorecardImportPhotoDesc => 'Photograph your paper scorecard';

  @override
  String get scorecardImportFromLibrary => 'Choose from Library';

  @override
  String get scorecardImportLibraryDesc => 'Select an existing photo';

  @override
  String get scorecardImportReading => 'Reading your scorecard…';

  @override
  String get scorecardImportAnalyzing =>
      'Analysing with AI — this takes a few seconds';

  @override
  String get scorecardImportUnableRead => 'Unable to Read Scorecard';

  @override
  String get scorecardImportConnectionError =>
      'Couldn\'t reach the AI service. Check your connection and try again.';

  @override
  String get notifPersonalBestTitle => '🏆 New Personal Best!';

  @override
  String notifPersonalBestMsg(String score) {
    return 'You scored $score — your best round yet. Keep it up!';
  }

  @override
  String get notifTeeTime1HourTitle => '⛳ Tee time in 1 hour!';

  @override
  String notifTeeTime1HourMsg(String courseName) {
    return 'Get ready for your round at $courseName.';
  }

  @override
  String get notifTeeTime15MinTitle => '⛳ Tee time in 15 minutes!';

  @override
  String notifTeeTime15MinMsg(String courseName) {
    return 'Head to the first tee at $courseName.';
  }

  @override
  String get notifStreakTitle => '⛳ Time to hit the course!';

  @override
  String get notifStreakMsg =>
      'It\'s been a while since your last round. Get out there!';

  @override
  String get noNotificationsTitle => 'No notifications yet';

  @override
  String get noNotificationsDesc =>
      'Play more rounds to unlock\nAI-personalised alerts';

  @override
  String get widgetLeaderboardTitle => 'Live Leaderboard';

  @override
  String get widgetLeaderboardUpdates => 'Updates after each hole';

  @override
  String get widgetLeaderboardPos => 'POS';

  @override
  String get widgetLeaderboardPlayer => 'PLAYER';

  @override
  String get widgetLeaderboardThru => 'THRU';

  @override
  String get widgetLeaderboardScore => 'SCORE';

  @override
  String widgetLeaderboardThruHoles(String holes) {
    return 'Thru $holes';
  }

  @override
  String get widgetLeaderboardTeeOff => 'Tee Off';

  @override
  String get widgetLeaderboardFinished => 'F';

  @override
  String get widgetLeaderboardInvited => 'Invited';

  @override
  String get widgetLeaderboardDeclined => 'Declined';

  @override
  String get widgetUnfinishedRound => 'Unfinished Round';

  @override
  String widgetHolesPlayed(int played, int total) {
    return '$played / $total holes played';
  }

  @override
  String get widgetResumeRound => 'Resume Round';

  @override
  String get widgetDiscardTitle => 'Discard Round?';

  @override
  String widgetDiscardMsg(String courseName) {
    return 'All progress on \"$courseName\" will be permanently lost.';
  }

  @override
  String get widgetKeep => 'Keep';

  @override
  String get widgetDiscard => 'Discard';

  @override
  String get widgetClubsHint => 'Tap clubs below to track each shot';

  @override
  String widgetClubsSelected(int count, int max) {
    return '$count of $max clubs selected';
  }

  @override
  String get widgetGolfDNA => 'GOLF DNA';

  @override
  String get widgetProAnalysis => 'PRO ANALYSIS';

  @override
  String get widgetPower => 'Power';

  @override
  String get widgetAccuracy => 'Accuracy';

  @override
  String get widgetPutting => 'Putting';

  @override
  String get widgetStrengthsWeaknesses => 'Strengths & Weaknesses';

  @override
  String get widgetPerformanceTrends => 'Performance Trends';

  @override
  String get widgetTraitAnalysis => 'Trait Analysis';

  @override
  String get widgetDrivingPower => 'Driving Power';

  @override
  String get widgetConsistency => 'Consistency';

  @override
  String get widgetRiskLevel => 'Risk Level';

  @override
  String get widgetStamina => 'Stamina';

  @override
  String get widgetAIRoundSummary => 'AI Round Summary';

  @override
  String get widgetAnalyzingRound => 'Analyzing your round…';

  @override
  String get widgetGemini => 'Gemini';

  @override
  String get widgetStrength => 'Strength';

  @override
  String get widgetWeakness => 'Weakness';

  @override
  String get widgetFocusArea => 'Focus Area';

  @override
  String get widgetPlayStyle => 'PLAY STYLE';

  @override
  String get widgetAIPowered => 'AI Powered';

  @override
  String widgetUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get widgetUpdatedToday => 'today';

  @override
  String get widgetUpdatedYesterday => 'yesterday';

  @override
  String widgetUpdatedDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }
}
