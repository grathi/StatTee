// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'TeeStats';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get done => 'Fertig';

  @override
  String get search => 'Suchen';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get next => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get skip => 'Überspringen';

  @override
  String get close => 'Schließen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get view => 'Anzeigen';

  @override
  String get accept => 'Annehmen';

  @override
  String get decline => 'Ablehnen';

  @override
  String get home => 'Start';

  @override
  String get rounds => 'Runden';

  @override
  String get stats => 'Statistiken';

  @override
  String get profile => 'Profil';

  @override
  String get friends => 'Freunde';

  @override
  String get loginWelcomeBack => 'Willkommen zurück';

  @override
  String get loginSignInToContinue => 'Anmelden, um fortzufahren';

  @override
  String get loginEmail => 'E-Mail';

  @override
  String get loginPassword => 'Passwort';

  @override
  String get loginForgotPassword => 'Passwort vergessen?';

  @override
  String get loginSignIn => 'Anmelden';

  @override
  String get loginDontHaveAccount => 'Noch kein Konto?';

  @override
  String get loginSignUp => 'Registrieren';

  @override
  String get loginTagline => 'Spielen  ·  Verfolgen  ·  Verbessern';

  @override
  String get loginResetPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get loginResetPasswordSubtitle =>
      'Wir senden einen Reset-Link an deine E-Mail';

  @override
  String get loginEnterYourEmail => 'E-Mail-Adresse eingeben';

  @override
  String get loginEnterValidEmail => 'Gültige E-Mail-Adresse eingeben';

  @override
  String get loginSendResetLink => 'Reset-Link senden';

  @override
  String get loginResetLinkSent => 'Reset-Link gesendet!';

  @override
  String loginCheckInboxFor(String email) {
    return 'Posteingang für $email prüfen';
  }

  @override
  String get loginErrorNoAccount =>
      'Kein Konto mit dieser E-Mail-Adresse gefunden.';

  @override
  String get loginErrorInvalidEmail =>
      'Bitte eine gültige E-Mail-Adresse eingeben.';

  @override
  String get loginErrorSomethingWrong =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get loginErrorIncorrectCredentials => 'E-Mail oder Passwort falsch.';

  @override
  String get loginErrorAccountDisabled => 'Dieses Konto wurde deaktiviert.';

  @override
  String get loginErrorTooManyAttempts =>
      'Zu viele Versuche. Später erneut versuchen.';

  @override
  String get loginErrorTryAgain =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get signupCreateAccount => 'Konto erstellen';

  @override
  String get signupJoinToday => 'Noch heute TeeStats beitreten';

  @override
  String get signupFullName => 'Vollständiger Name';

  @override
  String get signupEnterYourName => 'Namen eingeben';

  @override
  String get signupEmail => 'E-Mail';

  @override
  String get signupPassword => 'Passwort';

  @override
  String get signupConfirmPassword => 'Passwort bestätigen';

  @override
  String get signupEnterPassword => 'Passwort eingeben';

  @override
  String get signupMinimumChars => 'Mindestens 6 Zeichen';

  @override
  String get signupConfirmYourPassword => 'Passwort bestätigen';

  @override
  String get signupPasswordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String signupPasswordStrength(String label) {
    return 'Passwortstärke: $label';
  }

  @override
  String get signupPasswordWeak => 'Schwach';

  @override
  String get signupPasswordFair => 'Ausreichend';

  @override
  String get signupPasswordGood => 'Gut';

  @override
  String get signupPasswordStrong => 'Stark';

  @override
  String get signupAlreadyHaveAccount => 'Bereits ein Konto?';

  @override
  String get signupErrorAccountExists =>
      'Ein Konto mit dieser E-Mail-Adresse existiert bereits.';

  @override
  String get signupErrorInvalidEmail =>
      'Bitte eine gültige E-Mail-Adresse eingeben.';

  @override
  String get signupErrorWeakPassword =>
      'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get signupErrorNotEnabled =>
      'E-Mail-Registrierung ist nicht aktiviert.';

  @override
  String get onboardingTagline => 'Schwingen. Verfolgen. Gewinnen.';

  @override
  String get onboardingScoreTrackingTag => 'SCORE-VERFOLGUNG';

  @override
  String get onboardingTrackEveryRoundTitle => 'Jede Runde\nVerfolgen';

  @override
  String get onboardingScoreTrackingBody =>
      'GPS-gestützte Bewertung für jedes Loch. Deine vollständige Rundenhistorie, immer in der Tasche.';

  @override
  String get onboardingPerformanceTag => 'LEISTUNG';

  @override
  String get onboardingGolfDNATitle => 'Deine Golf-\nDNA kennen';

  @override
  String get onboardingPerformanceBody =>
      'Getroffene Fairways, GIR, Putts pro Runde, Handicap-Trends — genau erkennen, wo du dich verbessern kannst.';

  @override
  String get onboardingMultiplayerTag => 'MEHRSPIELER';

  @override
  String get onboardingPlayTogetherTitle => 'Zusammen\nSpielen';

  @override
  String get onboardingMultiplayerBody =>
      'Lade Freunde zu einer Live-Gruppenrunde ein. Echtzeit-Rangliste, kein zusätzlicher Aufwand beim Scoring.';

  @override
  String get onboardingSocialTag => 'SOZIAL';

  @override
  String get onboardingFriendsLeaderboardTitle => 'Freunde &\nRangliste';

  @override
  String get onboardingSocialBody =>
      'Verbinde dich mit deiner Golf-Crew. Sieh, wer auf einem Lauf ist, und fordere ihn heraus.';

  @override
  String get onboardingAITag => 'KI-GESTÜTZT';

  @override
  String get onboardingPersonalCaddieTitle => 'Dein persönlicher\nCaddie';

  @override
  String get onboardingAIBody =>
      'Nach jeder Runde analysiert Gemini KI deine Statistiken und liefert Coaching-Erkenntnisse — Stärken, Schwächen und einen Fokusbereich für das nächste Mal.';

  @override
  String get onboardingPoweredByGemini => 'Unterstützt von Google Gemini';

  @override
  String get homeReadyToPlay => '⛳  Bereit zu spielen?';

  @override
  String get homeStartRound => 'Runde starten';

  @override
  String get homeTapToTeeOff => 'Tippen zum Abschlagen';

  @override
  String get homeGolfNews => 'Golf-News';

  @override
  String get homeSeeAll => 'Alle anzeigen';

  @override
  String get homeRecentRounds => 'Letzte Runden';

  @override
  String get homeViewAll => 'Alle anzeigen';

  @override
  String get homeNoRoundsYet => 'Noch keine Runden — starte deine erste!';

  @override
  String get homeInProgress => 'In Bearbeitung';

  @override
  String get homeActive => 'Aktiv';

  @override
  String get homeNoLocation => 'Kein Standort';

  @override
  String get homePerformance => 'Leistung';

  @override
  String get homeCompleteRoundsForStats =>
      'Schließe Runden ab, um dein Handicap und deine Leistungsstatistiken zu sehen.';

  @override
  String get homeHandicapIndex => 'Handicap-Index';

  @override
  String homeRoundsNeeded(int n) {
    return '$n/20 Runden';
  }

  @override
  String homeMoreRoundsToUnlock(int n) {
    return 'Noch $n Runden, um deinen Handicap-Index freizuschalten';
  }

  @override
  String get homeFairwaysHit => 'Getroffene Fairways';

  @override
  String get homePar4And5 => 'Par-4- & Par-5-Löcher';

  @override
  String get homeGIR => 'Grüns in der Vorgabe';

  @override
  String get homeAllHoles => 'Alle Löcher';

  @override
  String get homeAvgPutts => 'Ø Putts';

  @override
  String get homePerHole => 'Pro Loch';

  @override
  String get homeBirdies => 'Birdies';

  @override
  String get homeAllRounds => 'Alle Runden';

  @override
  String get homeToday => 'Heute';

  @override
  String get homeYesterday => 'Gestern';

  @override
  String homeDaysAgo(int n) {
    return 'Vor $n Tagen';
  }

  @override
  String get homeWeekAgo => 'Vor 1 Woche';

  @override
  String get homeTwoWeeksAgo => 'Vor 2 Wochen';

  @override
  String get homeThreeWeeksAgo => 'Vor 3 Wochen';

  @override
  String homeMonthsAgo(int n) {
    return 'Vor $n Monaten';
  }

  @override
  String homeInvitedToPlay(String name) {
    return '$name hat dich zum Spielen eingeladen';
  }

  @override
  String get homeChangeLocation => 'Standort ändern';

  @override
  String get homeSearchCityOrArea => 'Stadt oder Gebiet suchen';

  @override
  String get homeLocationHint => 'z. B. Dubai, London, New York…';

  @override
  String get homeSearchLocation => 'Standort suchen';

  @override
  String get homeLocationNotFound =>
      'Standort nicht gefunden. Versuche einen anderen Städtenamen.';

  @override
  String get homeUseCurrentLocation => 'Meinen aktuellen Standort verwenden';

  @override
  String get homeWelcomeTour => 'Willkommen bei TeeStats';

  @override
  String get homeWelcomeTourBody =>
      'Dies ist deine Startseite — sieh auf einen Blick letzte Runden, Leistung und nahegelegene Plätze.';

  @override
  String get homeFriendsAndLeaderboard => 'Freunde & Rangliste';

  @override
  String get homeFriendsAndLeaderboardBody =>
      'Füge Golf-Freunde hinzu, akzeptiere Freundschaftsanfragen und vergleiche Scores auf der Rangliste. Ein grüner Punkt erscheint, wenn eine ausstehende Anfrage vorliegt.';

  @override
  String get homeStartARound => 'Eine Runde starten';

  @override
  String get homeStartARoundBody =>
      'Tippe jederzeit auf den grünen Button, um eine neue Runde auf einem beliebigen Platz zu starten.';

  @override
  String get homeYourActiveRound => 'Deine aktive Runde';

  @override
  String get homeResumeRoundBody =>
      'Wenn du mittendrin aufhörst, wird sie hier gespeichert. Tippe auf Fortsetzen, um weiterzumachen.';

  @override
  String get homeRoundHistory => 'Rundenhistorie';

  @override
  String get homeRoundHistoryBody =>
      'Alle deine abgeschlossenen Runden findest du hier. Tippe auf eine Runde für eine detaillierte Loch-für-Loch-Auswertung.';

  @override
  String get homeYourStats => 'Deine Statistiken';

  @override
  String get homeYourStatsBody =>
      'Verfolge deinen Handicap-Trend, Scoring-Muster, GIR, Fairways und Strokes Gained im Zeitverlauf.';

  @override
  String get homeYourProfile => 'Dein Profil';

  @override
  String get homeYourProfileBody =>
      'Setze dein Handicap-Ziel, wähle einen Avatar und sieh deine Golf-DNA und deinen Spielstil.';

  @override
  String get homeQuickStats => 'Schnellstatistiken';

  @override
  String get homeQuickStatsBody =>
      'Live-Durchschnittswerte über alle deine Runden — Fairways, GIR, Putts und Birdies pro Runde.';

  @override
  String get homeNearbyCourses => 'Nahe gelegene Plätze';

  @override
  String get homeNearbyCoursesBody =>
      'Golfplätze in deiner Nähe. Tippe auf einen Platz, um sofort dort eine Runde zu starten.';

  @override
  String get roundsMyRounds => 'Meine Runden';

  @override
  String get roundsRoundsTab => 'Runden';

  @override
  String get roundsPracticeTab => 'Training';

  @override
  String get roundsTournamentsTab => 'Turniere';

  @override
  String get roundsHistoryTitle => 'Deine Rundenhistorie';

  @override
  String get roundsHistorySubtitle =>
      'Alle abgeschlossenen Runden findest du hier. Tippe auf eine Runde für eine detaillierte Loch-für-Loch-Auswertung und Statistiken.';

  @override
  String get roundsInProgress => 'Runde in Bearbeitung';

  @override
  String roundsHolesProgress(int played, int total) {
    return '$played/$total Löcher';
  }

  @override
  String get roundsNoRoundsYet => 'Noch keine Runden';

  @override
  String get roundsStartFirst => 'Starte deine erste Runde über die Startseite';

  @override
  String get roundsOrScanScorecard => 'oder scanne eine Papier-Scorekarte';

  @override
  String get roundsDeleteTitle => 'Runde löschen?';

  @override
  String roundsDeleteConfirm(String courseName) {
    return 'Deine Runde auf $courseName dauerhaft entfernen?';
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
  String get roundSummaryComplete => 'Runde abgeschlossen!';

  @override
  String get roundSummaryScore => 'Score';

  @override
  String get roundSummaryVsPar => 'vs Par';

  @override
  String get roundSummaryHoles => 'Löcher';

  @override
  String get roundSummaryBackToHome => 'Zurück zur Startseite';

  @override
  String get roundSummaryEven => 'Gleich';

  @override
  String get roundDetailScorecard => 'Scorekarte';

  @override
  String get roundDetailShotTrails => 'Schlagspuren';

  @override
  String get roundDetailHole => 'Loch';

  @override
  String get roundDetailPar => 'Par';

  @override
  String get roundDetailGIR => 'GIR';

  @override
  String get roundDetailTotal => 'GES';

  @override
  String get roundDetailShare => 'Scorekarte teilen';

  @override
  String get roundDetailDelete => 'Runde löschen';

  @override
  String get roundDetailDeleteTitle => 'Runde löschen?';

  @override
  String roundDetailDeleteConfirm(String courseName) {
    return 'Deine Runde auf $courseName wird dauerhaft entfernt.';
  }

  @override
  String get startRoundPickCourse => '📍  Platz auswählen';

  @override
  String get startRoundWherePlaying => 'Wo spielst\ndu heute?';

  @override
  String get startRoundSearchHint => 'Nahe gelegenen Golfplatz suchen';

  @override
  String get startRoundCourseName => 'Platzname';

  @override
  String get startRoundEnterCourseName => 'Platznamen eingeben';

  @override
  String get startRoundFetchingTeeData => 'Abschlagdaten werden geladen…';

  @override
  String get startRoundSelectTee => 'ABSCHLAG WÄHLEN';

  @override
  String get startRoundCourseRating => 'COURSE RATING (OPTIONAL)';

  @override
  String get startRoundRatingForHandicap =>
      'Für einen genauen USGA Handicap-Index';

  @override
  String get startRoundCourseRatingLabel => 'Course Rating';

  @override
  String get startRoundCourseRatingHint => 'z. B. 72.5';

  @override
  String get startRoundSlopeRatingLabel => 'Slope Rating';

  @override
  String get startRoundSlopeRatingHint => 'z. B. 113';

  @override
  String get startRoundSlopeError => '55–155';

  @override
  String get startRoundNumberOfHoles => 'ANZAHL DER LÖCHER';

  @override
  String get startRoundHoles => 'Löcher';

  @override
  String get startRoundInviteFriends => 'FREUNDE EINLADEN (MAX. 3)';

  @override
  String get startRoundSearchFriends => 'Freunde suchen…';

  @override
  String get startRoundNoFriends => 'Noch keine Freunde.';

  @override
  String get startRoundNoMatches => 'Keine Treffer.';

  @override
  String startRoundFriendsInvited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Freunde werden eingeladen',
      one: '1 Freund wird eingeladen',
    );
    return '$_temp0';
  }

  @override
  String get startRoundTeeOff => 'Abschlagen!';

  @override
  String get startRoundNoCoursesFound =>
      'Keine Golfplätze in der Nähe gefunden';

  @override
  String get startRoundNoHoleData =>
      'Keine Lochdaten für diesen Platz gefunden.';

  @override
  String get startRoundUploadScorecard => 'Scorekarte hochladen';

  @override
  String startRoundError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get scorecardScoringARound => 'Runde werten';

  @override
  String get scorecardInstructions =>
      'Gib Score, Putts, Fairway und GIR für jedes Loch ein. Tippe auf den Schläger, um deine Schlägerwahl zu verfolgen.';

  @override
  String get scorecardHole => 'Loch';

  @override
  String get scorecardPlayingWithFriends => 'Mit Freunden spielen';

  @override
  String get scorecardScore => 'SCORE';

  @override
  String get scorecardPutts => 'PUTTS';

  @override
  String get scorecardFairwayHit => 'FAIRWAY GETROFFEN';

  @override
  String get scorecardGIR => 'GRÜN IN DER VORGABE';

  @override
  String get scorecardTrackShots => 'Schläge verfolgen';

  @override
  String get scorecardTeeSet => 'Abschlag-Set';

  @override
  String scorecardShotsTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schläge verfolgt',
      one: '1 Schlag verfolgt',
    );
    return '$_temp0';
  }

  @override
  String get scorecardClub => 'SCHLÄGER';

  @override
  String get scorecardScorecardLabel => 'SCOREKARTE';

  @override
  String get scorecardLeaveTitle => 'Runde verlassen?';

  @override
  String get scorecardLeaveBody =>
      'Dein Fortschritt wird automatisch gespeichert.\nDu kannst diese Runde von der Startseite aus fortsetzen.';

  @override
  String get scorecardSaveAndExit => 'Speichern & Beenden';

  @override
  String get scorecardKeepPlaying => 'Weiterspielen';

  @override
  String get scorecardAbandon => 'Aufgeben';

  @override
  String get scorecardNextHole => 'Nächstes Loch';

  @override
  String get scorecardFinishRound => 'Runde beenden';

  @override
  String get scorecardAICaddy => 'KI-CADDY';

  @override
  String get scorecardTipPar3 =>
      'Par 3: Entscheide dich für einen Schläger und vertraue dem Schwung.';

  @override
  String get scorecardTipInsightsUnlock =>
      'Spiel dein Spiel — Erkenntnisse werden nach 3 Löchern freigeschaltet.';

  @override
  String scorecardTipAvgPutts(String avgPutts) {
    return 'Durchschnittlich $avgPutts Putts — beim Lagging aus der Distanz fokussieren.';
  }

  @override
  String scorecardTipFairways(String fwhitPercent) {
    return 'Nur $fwhitPercent% Fairways getroffen — erwäge ein 3-Holz vom Abschlag.';
  }

  @override
  String get scorecardTipApproach =>
      'Annäherungsschläge schwächeln — heute auf die Grünmitte zielen.';

  @override
  String get scorecardTipSolid =>
      'Bisher solide Runde — gleichen Rhythmus und Tempo beibehalten.';

  @override
  String get scorecardYds => 'YDS';

  @override
  String scorecardPlaysLike(String distance) {
    return 'SPIELT WIE $distance YDS';
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
  String get scorecardDouble => 'Doppel';

  @override
  String scorecardEditHole(int hole) {
    return 'Loch $hole bearbeiten';
  }

  @override
  String scorecardErrorSaving(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String get scorecardOn => 'AN';

  @override
  String get scorecardOff => 'AUS';

  @override
  String get statsHub => 'Dein Statistik-Hub';

  @override
  String get statsPlayMoreRounds =>
      'Spiele mehr Runden, um Trenddiagramme, Strokes Gained und Score-Verteilungsanalysen freizuschalten.';

  @override
  String get statsHandicapIndex => 'Handicap-Index';

  @override
  String statsBasedOnRounds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Basierend auf $n Runden',
      one: 'Basierend auf 1 Runde',
    );
    return '$_temp0';
  }

  @override
  String get statsCompleteToCalculate => 'Runden abschließen zum Berechnen';

  @override
  String get statsAvgScore => 'Ø Score';

  @override
  String get statsBestRound => 'Beste Runde';

  @override
  String get statsTotalRounds => 'Runden gesamt';

  @override
  String get statsTotalBirdies => 'Birdies gesamt';

  @override
  String get statsScoreDistribution => 'Score-Verteilung';

  @override
  String get statsEagles => 'Eagles';

  @override
  String get statsBirdies => 'Birdies';

  @override
  String get statsPars => 'Pars';

  @override
  String get statsBogeys => 'Bogeys';

  @override
  String get statsDoublePlus => 'Doppel+';

  @override
  String statsScoreVsPar(int n) {
    return 'Score vs Par (letzte $n Runden)';
  }

  @override
  String get statsOldestToRecent => 'Älteste → Neueste';

  @override
  String get statsHandicapTrend => 'Handicap-Trend';

  @override
  String statsGoal(String n) {
    return 'Ziel: $n';
  }

  @override
  String statsLatest(String n) {
    return 'Aktuell: $n';
  }

  @override
  String get statsFairwaysHit => 'Getroffene Fairways';

  @override
  String get statsGIR => 'Grüns in der Vorgabe';

  @override
  String get statsAvgPuttsPerHole => 'Ø Putts / Loch';

  @override
  String get statsClubStats => 'Schlägerstatistiken';

  @override
  String get statsClubStatsSubtitle => 'Score vs Par & Ø Putts pro Schläger';

  @override
  String get statsClub => 'Schläger';

  @override
  String get statsHoles => 'Löcher';

  @override
  String get statsAvgPlusMinus => 'Ø ±Par';

  @override
  String get statsAvgPutts => 'Ø Putts';

  @override
  String get statsStrokesGained => 'Strokes Gained';

  @override
  String get statsVsScratch => 'vs Scratch-Golfer-Baseline';

  @override
  String get statsOffTheTee => 'Vom Abschlag';

  @override
  String get statsApproach => 'Annäherung';

  @override
  String get statsAroundGreen => 'Rund ums Grün';

  @override
  String get statsPutting => 'Putten';

  @override
  String get statsBetterThanAvg => 'Besser als\ndurchschnittlich';

  @override
  String get statsPressureScore => 'Druck-Score';

  @override
  String get statsPressureResilience => 'Resilienz';

  @override
  String statsPressureUnlockHint(int count) {
    return 'Spiele $count weitere Runde(n), um dein mentales Spielerprofil freizuschalten';
  }

  @override
  String get statsPressureOpeningHole => 'Startloch';

  @override
  String get statsPressureBirdieHangover => 'Birdie-Kater';

  @override
  String get statsPressureBackNine => 'Rückseiten-Abfall';

  @override
  String get statsPressureFinishingStretch => 'Schlusslöcher';

  @override
  String get statsPressureThreePutt => 'Drei-Putt-Timing';

  @override
  String get statsPressureTopDrill => 'Top-Übung';

  @override
  String get statsPressureInsufficientData => 'Wenig Daten';

  @override
  String get tournamentNoTournaments => 'Noch keine Turniere';

  @override
  String get tournamentCreateInstructions =>
      'Tippe auf \"Neues Turnier\", um eines zu erstellen,\ndann Runden starten, um für das Turnier zu werten.';

  @override
  String get tournamentNew => 'Neues Turnier';

  @override
  String get tournamentStartInstructions =>
      'Erstelle zuerst ein Turnier, dann verwende den ＋ FAB auf der Startseite, um eine Turnierrunde zu starten.';

  @override
  String get tournamentDeleteTitle => 'Turnier löschen?';

  @override
  String tournamentDeleteConfirm(String name) {
    return '\"$name\" entfernen? Die Runden selbst werden nicht gelöscht.';
  }

  @override
  String get tournamentRoundByRound => 'Runde für Runde';

  @override
  String get tournamentVsPar => 'vs Par';

  @override
  String get tournamentRoundsLabel => 'Runden';

  @override
  String get tournamentNameLabel => 'Turniername';

  @override
  String get tournamentNameHint => 'z. B. Club-Meisterschaft 2026';

  @override
  String get tournamentCreate => 'Turnier erstellen';

  @override
  String tournamentRoundsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Runden',
      one: '1 Runde',
    );
    return '$_temp0';
  }

  @override
  String get tournamentRunning => 'läuft';

  @override
  String get practiceNoSessions => 'Noch keine Trainingseinheiten';

  @override
  String get practiceStartInstructions =>
      'Starte eine Runde, um Löcher zu werten,\noder protokolliere Range- und Short-Game-Einheiten.';

  @override
  String get practiceLogSession => 'Einheit protokollieren';

  @override
  String get practiceScoredRound => 'Gewertete Runde';

  @override
  String get practiceDeleteTitle => 'Einheit löschen?';

  @override
  String get practiceDeleteConfirm =>
      'Diese Trainingseinheit wird dauerhaft entfernt.';

  @override
  String get practiceLogTitle => 'Trainingseinheit protokollieren';

  @override
  String get practiceType => 'Typ';

  @override
  String get practiceBallsHit => 'Geschlagene Bälle';

  @override
  String get practiceDuration => 'Dauer (Min.)';

  @override
  String get practiceNotes => 'Notizen (optional)';

  @override
  String get practiceNotesHint => 'Woran hast du gearbeitet?';

  @override
  String get practiceSave => 'Einheit speichern';

  @override
  String get friendsTitle => 'Freunde';

  @override
  String get friendsLeaderboard => 'Rangliste';

  @override
  String get friendsNoFriendsYet => 'Noch keine Freunde';

  @override
  String get friendsEnterEmail =>
      'Gib oben die E-Mail eines Freundes ein, um ihn hinzuzufügen';

  @override
  String get friendsSearchHint => 'Nach E-Mail-Adresse suchen…';

  @override
  String get friendsPendingRequests => 'Ausstehende Anfragen';

  @override
  String get friendsWantsToBeF => 'Möchte befreundet sein';

  @override
  String get friendsRequestSent => 'Anfrage gesendet';

  @override
  String get friendsAcceptRequest => 'Anfrage annehmen';

  @override
  String get friendsAlreadyFriends => 'Bereits befreundet';

  @override
  String get friendsAddFriend => 'Freund hinzufügen';

  @override
  String get friendsNoLeaderboard => 'Noch keine Rangliste';

  @override
  String get friendsAddToCompare =>
      'Füge Freunde hinzu, um Scores zu vergleichen';

  @override
  String get friendsHandicap => 'Handicap';

  @override
  String get friendsAvgScore => 'Ø Score';

  @override
  String get friendsYou => 'Du';

  @override
  String get notifPrefsTitle => 'Smarte Benachrichtigungen';

  @override
  String get notifPrefsSubtitle =>
      'KI-gestützte Benachrichtigungen für dein Spiel';

  @override
  String get notifPrefsSectionTitle => 'BENACHRICHTIGUNGSTYPEN';

  @override
  String get notifPrefsPracticeReminders => 'Trainingserinnerungen';

  @override
  String get notifPrefsPracticeDesc =>
      'KI-angepasste Übungen für deine schwächsten Bereiche';

  @override
  String get notifPrefsResumeRound => 'Runde fortsetzen';

  @override
  String get notifPrefsResumeDesc =>
      'Erinnerungen zum Abschließen unvollendeter Runden';

  @override
  String get notifPrefsPerformance => 'Leistungseinblicke';

  @override
  String get notifPrefsPerformanceDesc =>
      'Verbesserungsserien und Trends feiern';

  @override
  String get notifPrefsTeeTime => 'Abschlagzeit-Erinnerungen';

  @override
  String get notifPrefsTeeTimeDesc =>
      'Benachrichtigungen vor bevorstehenden Abschlagzeiten';

  @override
  String get notifPrefsSaved => 'Einstellungen gespeichert';

  @override
  String get notifPrefsPersonalised =>
      'Benachrichtigungen werden basierend auf deinen\nletzten Runden und Leistungstrends personalisiert.';

  @override
  String get notifPrefsAIDriven => '✨ KI-gesteuerte Benachrichtigungen';

  @override
  String get notifPrefsSmartDesc =>
      'Smarte Benachrichtigungen\nangepasst an dein Golfspiel';

  @override
  String get notifPrefsExplanation =>
      'TeeStats analysiert deine Runden, Trainingsgewohnheiten und Leistungstrends, um Benachrichtigungen zu senden, die deinem Spiel wirklich helfen.';

  @override
  String get notifPrefsSave => 'Einstellungen speichern';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSubtitle => 'Mach es zu deinem';

  @override
  String get profileDescription =>
      'Setze dein Handicap-Ziel, wähle einen Avatar und entdecke deine Golf-DNA und deinen Spielstil.';

  @override
  String get profileGolfer => 'Golfer';

  @override
  String get profileGolfPlaces => 'Golf-Orte';

  @override
  String get profileEditProfile => 'Profil bearbeiten';

  @override
  String get profileSmartNotifications => 'Smarte Benachrichtigungen';

  @override
  String get profileAchievementsSection => 'ERFOLGE';

  @override
  String get profileRounds => 'Runden';

  @override
  String get profileHandicap => 'Handicap';

  @override
  String get profileBirdies => 'Birdies';

  @override
  String get profileAccount => 'Konto';

  @override
  String get profileSignOut => 'Abmelden';

  @override
  String get profileDeleteAccount => 'Konto löschen';

  @override
  String profileVersion(String version) {
    return 'TeeStats v$version';
  }

  @override
  String profileCopyright(String year) {
    return '© $year TeeStats. Alle Rechte vorbehalten.';
  }

  @override
  String get profileHandicapGoal => 'Handicap-Ziel';

  @override
  String get profileHandicapGoalDesc =>
      'Setze einen Ziel-Handicap-Index, der in deinem Trenddiagramm angezeigt wird.';

  @override
  String profileTargetPrefix(String value) {
    return 'Ziel: $value';
  }

  @override
  String get profileNotSet => 'Nicht gesetzt — tippen zum Festlegen';

  @override
  String get profileClear => 'Löschen';

  @override
  String get profileSaveGoal => 'Ziel speichern';

  @override
  String get profileSignOutTitle => 'Abmelden?';

  @override
  String get profileSignOutBody =>
      'Du wirst zum Anmeldebildschirm weitergeleitet.';

  @override
  String get profileDeleteTitle => 'Konto löschen?';

  @override
  String get profileDeleteBody =>
      'Dadurch werden dein Konto und alle Golf-Daten einschließlich Runden, Statistiken und Erfolge dauerhaft gelöscht.';

  @override
  String get profileDeleteAreYouSure => 'Bist du absolut sicher?';

  @override
  String get profileDeleteRoundsItem => 'Alle deine Runden und Scorekarten';

  @override
  String get profileDeleteStatsItem =>
      'Statistiken, Handicap-Verlauf und Erfolge';

  @override
  String get profileDeleteProfileItem => 'Dein Profil und deine Einstellungen';

  @override
  String get profileDeleteNotificationsItem =>
      'Smarte Benachrichtigungen und Abschlagzeiten';

  @override
  String get profileDeleteCannotUndo =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get profileDeleteButton => 'Mein Konto löschen';

  @override
  String get profileKeepButton => 'Konto behalten';

  @override
  String get profileDeletingAccount => 'Konto wird gelöscht…';

  @override
  String get profileReauthRequired =>
      'Bitte melde dich ab und wieder an, bevor du dein Konto löschst.';

  @override
  String get profileSomethingWrong =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get profileContinue => 'Weiter';

  @override
  String get profileDisplayName => 'Anzeigename';

  @override
  String get profileSaveChanges => 'Änderungen speichern';

  @override
  String get profileChooseAvatar => 'Avatar wählen';

  @override
  String get profileSelectPresetAvatar => 'Vordefinierten Avatar auswählen';

  @override
  String get profileRemoveAvatar => 'Avatar entfernen';

  @override
  String get profileSaveAvatar => 'Avatar speichern';

  @override
  String get shotTrackerTapToMark =>
      'Auf die Karte tippen, um den Abschlag zu markieren';

  @override
  String get shotTrackerTeeMarked =>
      'Abschlag markiert · tippen zum Verfolgen der Schläge';

  @override
  String shotTrackerShotsFromTee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schläge vom Abschlag',
      one: '1 Schlag vom Abschlag',
    );
    return '$_temp0';
  }

  @override
  String get shotTrackerAcquiringGPS => 'GPS wird ermittelt…';

  @override
  String shotTrackerDistToPin(String distance) {
    return '$distance yds zur Fahne';
  }

  @override
  String shotTrackerLastShot(String distance) {
    return 'Letzter Schlag: $distance yds';
  }

  @override
  String get shotTrackerUndo => 'Rückgängig';

  @override
  String get shotTrackerFinishHole => 'Loch beenden';

  @override
  String shotTrackerFinishHoleWithCount(int count) {
    return 'Loch beenden  ($count Schläge)';
  }

  @override
  String get shotTrackerNiceApproach => 'Schöner Annäherungsschlag!';

  @override
  String shotTrackerOnGreen(String shotCount, int holeNumber) {
    return 'Du bist auf dem Grün — ${shotCount}Bereit, Putts für Loch $holeNumber einzutragen?';
  }

  @override
  String get shotTrackerNotYet => 'Noch nicht';

  @override
  String shotTrackerLogPutts(int holeNumber) {
    return 'Putts für Loch $holeNumber eintragen';
  }

  @override
  String get swingAnalyzerTitle => 'Schwung-Analyzer';

  @override
  String get swingAnalyzerSaveToGallery => 'In Galerie speichern';

  @override
  String get swingAnalyzerShare => 'Teilen';

  @override
  String get swingAnalyzerLoadingVideo => 'Video wird geladen…';

  @override
  String get swingAnalyzerUploading => 'Video wird hochgeladen…';

  @override
  String get swingAnalyzerAnalyzing => 'Ballflug wird analysiert…';

  @override
  String get swingAnalyzerPreviewUnavailable =>
      'Vorschau nicht verfügbar — tippe auf den Ball';

  @override
  String get swingAnalyzerTapBall => 'Auf den Golfball tippen';

  @override
  String get swingAnalyzerReposition => 'Tippen zum Neupositionieren';

  @override
  String get swingAnalyzerSkip => 'Überspringen';

  @override
  String get swingAnalyzerAnalyze => 'Analysieren';

  @override
  String get swingAnalyzerAITracerTitle => 'KI-Schwung-Tracer';

  @override
  String get swingAnalyzerAITracerDesc =>
      'Nimm ein Golfschwung-Video auf oder lade eines hoch.\nGemini KI verfolgt den Ball und überlagert einen Live-Tracer.';

  @override
  String get swingAnalyzerButton => 'Schwung analysieren';

  @override
  String get swingAnalyzerComingSoon => 'Demnächst verfügbar';

  @override
  String get swingAnalyzerComingSoonMsg =>
      'Der KI-Schwung-Tracer befindet sich noch in der Entwicklung. Bleib gespannt auf das Update!';

  @override
  String get swingAnalyzerGotIt => 'Verstanden';

  @override
  String get swingAnalyzerFailed => 'Analyse fehlgeschlagen';

  @override
  String get swingAnalyzerFailedMsg =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get swingAnalyzerTryAgain => 'Erneut versuchen';

  @override
  String get swingAnalyzerRecording => 'REC';

  @override
  String get swingAnalyzerBallNotDetected => 'Ball im Video nicht erkannt';

  @override
  String get swingAnalyzerNoVideoFile => 'Keine Videodatei zum Speichern';

  @override
  String get swingAnalyzerVideoSaved => 'Video in Galerie gespeichert';

  @override
  String swingAnalyzerCouldNotSave(String error) {
    return 'Video konnte nicht gespeichert werden: $error';
  }

  @override
  String get swingAnalyzerShareText =>
      'Schau dir meine Schwungspur aus TeeStats an! 🏌️';

  @override
  String get swingAnalyzerShotAnalysis => 'Schlaganalyse';

  @override
  String get swingAnalyzerCarry => 'Carry';

  @override
  String get swingAnalyzerHeight => 'Höhe';

  @override
  String get swingAnalyzerLaunch => 'Abflugwinkel';

  @override
  String get swingAnalyzerPathNotDetected =>
      'Ballbahn nicht erkannt. Versuche bessere Beleuchtung oder einen näheren Winkel.';

  @override
  String get swingAnalyzerAnotherSwing => 'Weiteren Schwung analysieren';

  @override
  String get scorecardUploadTitle => 'Scorekarte scannen';

  @override
  String get scorecardUploadDesc =>
      'KI extrahiert Loch-für-Loch-Daten einschließlich Par, Entfernung und Handicap.';

  @override
  String get scorecardUploadChooseSource => 'QUELLE WÄHLEN';

  @override
  String get scorecardUploadTakePhoto => 'Foto aufnehmen';

  @override
  String get scorecardUploadFromGallery => 'Aus Galerie wählen';

  @override
  String get scorecardUploadAnalyzing => 'Scorekarte wird analysiert…';

  @override
  String get scorecardUploadAnalyzingNote =>
      'Dies dauert normalerweise ein paar Sekunden';

  @override
  String get scorecardUploadReviewTitle => 'Scorekarte überprüfen';

  @override
  String get scorecardUploadUploadTitle => 'Scorekarte hochladen';

  @override
  String get scorecardUploadCourseName => 'PLATZNAME';

  @override
  String get scorecardUploadCourseNameHint => 'Platznamen eingeben';

  @override
  String get scorecardUploadCityState => 'Stadt, Bundesland';

  @override
  String get scorecardUploadSelectTee => 'ABSCHLAG WÄHLEN';

  @override
  String get scorecardUploadRetake => 'Erneut aufnehmen';

  @override
  String get scorecardUploadSaveUse => 'Speichern & Verwenden';

  @override
  String get scorecardUploadNoTeeData =>
      'Keine Abschlagdaten extrahiert. Versuche ein klareres Foto.';

  @override
  String scorecardUploadFailed(String error) {
    return 'Extraktion fehlgeschlagen. Versuche ein klareres Foto.\n$error';
  }

  @override
  String get scorecardUploadRating => 'Rating';

  @override
  String get scorecardUploadSlope => 'Slope';

  @override
  String get scorecardUploadHoleHeader => 'LOCH';

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
  String get scorecardUploadValidation => 'Bitte den Platznamen eingeben.';

  @override
  String get scorecardUploadMissingScores => 'Einige Scores fehlen';

  @override
  String get scorecardUploadMissingMsg =>
      'Bei einigen Löchern steht noch 0. Sie werden als 0 Schläge gespeichert — du kannst sie nach dem Import bearbeiten.';

  @override
  String get scorecardUploadImportAnyway => 'Trotzdem importieren';

  @override
  String get scorecardUploadFixFirst => 'Zuerst korrigieren';

  @override
  String get scorecardImportCourse => 'Platz';

  @override
  String get scorecardImportCourseNameHint => 'Platzname';

  @override
  String get scorecardImportLocationHint =>
      'Standort — oben einen Platz suchen';

  @override
  String get scorecardImportNoCoursesFound => 'Keine Golfplätze gefunden';

  @override
  String get scorecardImportButton => 'Importieren';

  @override
  String get scorecardImportConditions => 'Rundenbedingungen';

  @override
  String get scorecardImportAvgTemp => 'Ø Temperatur';

  @override
  String get scorecardImportAvgWind => 'Ø Wind';

  @override
  String get scorecardImportConditionsLabel => 'Bedingungen';

  @override
  String get scorecardImportWeatherUnavailable => 'Wetter nicht verfügbar';

  @override
  String get scorecardImportToday => 'Heute';

  @override
  String get scorecardImportHowToAdd =>
      'Wie möchtest du deine Scorekarte hinzufügen?';

  @override
  String get scorecardImportTakePhoto => 'Foto aufnehmen';

  @override
  String get scorecardImportPhotoDesc => 'Fotografiere deine Papier-Scorekarte';

  @override
  String get scorecardImportFromLibrary => 'Aus Bibliothek wählen';

  @override
  String get scorecardImportLibraryDesc => 'Vorhandenes Foto auswählen';

  @override
  String get scorecardImportReading => 'Scorekarte wird gelesen…';

  @override
  String get scorecardImportAnalyzing =>
      'KI-Analyse läuft — das dauert ein paar Sekunden';

  @override
  String get scorecardImportUnableRead =>
      'Scorekarte konnte nicht gelesen werden';

  @override
  String get scorecardImportConnectionError =>
      'KI-Dienst nicht erreichbar. Verbindung prüfen und erneut versuchen.';

  @override
  String get notifPersonalBestTitle => '🏆 Neue persönliche Bestleistung!';

  @override
  String notifPersonalBestMsg(String score) {
    return 'Du hast $score gespielt — deine beste Runde bisher. Weiter so!';
  }

  @override
  String get notifTeeTime1HourTitle => '⛳ Abschlagzeit in 1 Stunde!';

  @override
  String notifTeeTime1HourMsg(String courseName) {
    return 'Mach dich bereit für deine Runde auf $courseName.';
  }

  @override
  String get notifTeeTime15MinTitle => '⛳ Abschlagzeit in 15 Minuten!';

  @override
  String notifTeeTime15MinMsg(String courseName) {
    return 'Geh zum ersten Abschlag auf $courseName.';
  }

  @override
  String get notifStreakTitle => '⛳ Zeit, auf den Platz zu gehen!';

  @override
  String get notifStreakMsg =>
      'Es ist schon eine Weile her seit deiner letzten Runde. Raus damit!';

  @override
  String get noNotificationsTitle => 'Noch keine Benachrichtigungen';

  @override
  String get noNotificationsDesc =>
      'Spiele mehr Runden, um\nKI-personalisierte Benachrichtigungen freizuschalten';

  @override
  String get widgetLeaderboardTitle => 'Live-Rangliste';

  @override
  String get widgetLeaderboardUpdates => 'Aktualisierung nach jedem Loch';

  @override
  String get widgetLeaderboardPos => 'POS';

  @override
  String get widgetLeaderboardPlayer => 'SPIELER';

  @override
  String get widgetLeaderboardThru => 'NACH';

  @override
  String get widgetLeaderboardScore => 'SCORE';

  @override
  String widgetLeaderboardThruHoles(String holes) {
    return 'Nach $holes';
  }

  @override
  String get widgetLeaderboardTeeOff => 'Abschlag';

  @override
  String get widgetLeaderboardFinished => 'F';

  @override
  String get widgetLeaderboardInvited => 'Eingeladen';

  @override
  String get widgetLeaderboardDeclined => 'Abgelehnt';

  @override
  String get widgetUnfinishedRound => 'Unvollendete Runde';

  @override
  String widgetHolesPlayed(int played, int total) {
    return '$played / $total Löcher gespielt';
  }

  @override
  String get widgetResumeRound => 'Runde fortsetzen';

  @override
  String get widgetDiscardTitle => 'Runde verwerfen?';

  @override
  String widgetDiscardMsg(String courseName) {
    return 'Aller Fortschritt auf \"$courseName\" geht dauerhaft verloren.';
  }

  @override
  String get widgetKeep => 'Behalten';

  @override
  String get widgetDiscard => 'Verwerfen';

  @override
  String get widgetClubsHint =>
      'Tippe unten auf Schläger, um jeden Schlag zu verfolgen';

  @override
  String widgetClubsSelected(int count, int max) {
    return '$count von $max Schlägern ausgewählt';
  }

  @override
  String get widgetGolfDNA => 'GOLF-DNA';

  @override
  String get widgetProAnalysis => 'PROFI-ANALYSE';

  @override
  String get widgetPower => 'Power';

  @override
  String get widgetAccuracy => 'Genauigkeit';

  @override
  String get widgetPutting => 'Putten';

  @override
  String get widgetStrengthsWeaknesses => 'Stärken & Schwächen';

  @override
  String get widgetPerformanceTrends => 'Leistungstrends';

  @override
  String get widgetTraitAnalysis => 'Eigenschaftsanalyse';

  @override
  String get widgetDrivingPower => 'Drive-Power';

  @override
  String get widgetConsistency => 'Konstanz';

  @override
  String get widgetRiskLevel => 'Risikoniveau';

  @override
  String get widgetStamina => 'Ausdauer';

  @override
  String get widgetAIRoundSummary => 'KI-Rundenzusammenfassung';

  @override
  String get widgetAnalyzingRound => 'Runde wird analysiert…';

  @override
  String get widgetGemini => 'Gemini';

  @override
  String get widgetStrength => 'Stärke';

  @override
  String get widgetWeakness => 'Schwäche';

  @override
  String get widgetFocusArea => 'Fokusbereich';

  @override
  String get widgetPlayStyle => 'SPIELSTIL';

  @override
  String get widgetAIPowered => 'KI-gestützt';

  @override
  String widgetUpdated(String date) {
    return 'Aktualisiert $date';
  }

  @override
  String get widgetUpdatedToday => 'heute';

  @override
  String get widgetUpdatedYesterday => 'gestern';

  @override
  String widgetUpdatedDaysAgo(int days) {
    return 'vor ${days}T';
  }

  @override
  String get timeJustNow => 'gerade eben';

  @override
  String timeMinutesAgo(int minutes) {
    return 'vor ${minutes}m';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'vor ${hours}h';
  }

  @override
  String timeDaysAgo(int days) {
    return 'vor ${days}T';
  }
}
