// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'TeeStats';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get done => 'Terminé';

  @override
  String get search => 'Rechercher';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get skip => 'Passer';

  @override
  String get close => 'Fermer';

  @override
  String get edit => 'Modifier';

  @override
  String get view => 'Voir';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get home => 'Accueil';

  @override
  String get rounds => 'Parties';

  @override
  String get stats => 'Statistiques';

  @override
  String get profile => 'Profil';

  @override
  String get friends => 'Amis';

  @override
  String get loginWelcomeBack => 'Bon retour';

  @override
  String get loginSignInToContinue => 'Connectez-vous pour continuer';

  @override
  String get loginEmail => 'E-mail';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginSignIn => 'Se connecter';

  @override
  String get loginDontHaveAccount => 'Pas encore de compte ?';

  @override
  String get loginSignUp => 'S\'inscrire';

  @override
  String get loginTagline => 'Jouer  ·  Suivre  ·  Progresser';

  @override
  String get loginResetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get loginResetPasswordSubtitle =>
      'Nous enverrons un lien de réinitialisation à votre e-mail';

  @override
  String get loginEnterYourEmail => 'Saisissez votre e-mail';

  @override
  String get loginEnterValidEmail => 'Saisissez un e-mail valide';

  @override
  String get loginSendResetLink => 'Envoyer le lien de réinitialisation';

  @override
  String get loginResetLinkSent => 'Lien de réinitialisation envoyé !';

  @override
  String loginCheckInboxFor(String email) {
    return 'Consultez votre boîte de réception pour $email';
  }

  @override
  String get loginErrorNoAccount => 'Aucun compte trouvé avec cet e-mail.';

  @override
  String get loginErrorInvalidEmail => 'Veuillez saisir un e-mail valide.';

  @override
  String get loginErrorSomethingWrong =>
      'Une erreur s\'est produite. Réessayez.';

  @override
  String get loginErrorIncorrectCredentials =>
      'E-mail ou mot de passe incorrect.';

  @override
  String get loginErrorAccountDisabled => 'Ce compte a été désactivé.';

  @override
  String get loginErrorTooManyAttempts =>
      'Trop de tentatives. Réessayez plus tard.';

  @override
  String get loginErrorTryAgain =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get signupCreateAccount => 'Créer un compte';

  @override
  String get signupJoinToday => 'Rejoignez TeeStats aujourd\'hui';

  @override
  String get signupFullName => 'Nom complet';

  @override
  String get signupEnterYourName => 'Saisissez votre nom';

  @override
  String get signupEmail => 'E-mail';

  @override
  String get signupPassword => 'Mot de passe';

  @override
  String get signupConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get signupEnterPassword => 'Créez un mot de passe';

  @override
  String get signupMinimumChars => 'Minimum 6 caractères';

  @override
  String get signupConfirmYourPassword => 'Confirmez votre mot de passe';

  @override
  String get signupPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String signupPasswordStrength(String label) {
    return 'Force du mot de passe : $label';
  }

  @override
  String get signupPasswordWeak => 'Faible';

  @override
  String get signupPasswordFair => 'Moyen';

  @override
  String get signupPasswordGood => 'Bon';

  @override
  String get signupPasswordStrong => 'Fort';

  @override
  String get signupAlreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get signupErrorAccountExists =>
      'Un compte avec cet e-mail existe déjà.';

  @override
  String get signupErrorInvalidEmail =>
      'Veuillez saisir une adresse e-mail valide.';

  @override
  String get signupErrorWeakPassword =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get signupErrorNotEnabled =>
      'L\'inscription par e-mail n\'est pas activée.';

  @override
  String get onboardingTagline => 'Swinguez. Suivez. Gagnez.';

  @override
  String get onboardingScoreTrackingTag => 'SUIVI DES SCORES';

  @override
  String get onboardingTrackEveryRoundTitle => 'Suivez Chaque\nPartie';

  @override
  String get onboardingScoreTrackingBody =>
      'Scores GPS pour chaque trou. Tout l\'historique de vos parties, toujours dans votre poche.';

  @override
  String get onboardingPerformanceTag => 'PERFORMANCE';

  @override
  String get onboardingGolfDNATitle => 'Connaissez Votre\nADN de Golf';

  @override
  String get onboardingPerformanceBody =>
      'Fairways touchés, VER, putts par partie, tendances du handicap — identifiez exactement où vous améliorer.';

  @override
  String get onboardingMultiplayerTag => 'MULTIJOUEUR';

  @override
  String get onboardingPlayTogetherTitle => 'Jouez\nEnsemble';

  @override
  String get onboardingMultiplayerBody =>
      'Invitez des amis pour une partie en groupe en direct. Classement en temps réel, sans saisie supplémentaire.';

  @override
  String get onboardingSocialTag => 'SOCIAL';

  @override
  String get onboardingFriendsLeaderboardTitle => 'Amis &\nClassement';

  @override
  String get onboardingSocialBody =>
      'Connectez-vous avec votre groupe de golf. Voyez qui est en bonne forme et défiez-les de faire mieux.';

  @override
  String get onboardingAITag => 'IA INTÉGRÉE';

  @override
  String get onboardingPersonalCaddieTitle => 'Votre Caddie\nPersonnel';

  @override
  String get onboardingAIBody =>
      'Après chaque partie, Gemini IA analyse vos statistiques et fournit des conseils d\'entraînement — points forts, points faibles et un axe d\'amélioration pour la prochaine fois.';

  @override
  String get onboardingPoweredByGemini => 'Propulsé par Google Gemini';

  @override
  String get homeReadyToPlay => '⛳  Prêt à jouer ?';

  @override
  String get homeStartRound => 'Démarrer une partie';

  @override
  String get homeTapToTeeOff => 'Appuyez pour partir';

  @override
  String get homeGolfNews => 'Actualités golf';

  @override
  String get homeSeeAll => 'Voir tout';

  @override
  String get homeRecentRounds => 'Parties récentes';

  @override
  String get homeViewAll => 'Tout afficher';

  @override
  String get homeNoRoundsYet => 'Aucune partie — commencez votre première !';

  @override
  String get homeInProgress => 'En cours';

  @override
  String get homeActive => 'Actif';

  @override
  String get homeNoLocation => 'Aucun emplacement';

  @override
  String get homePerformance => 'Performance';

  @override
  String get homeCompleteRoundsForStats =>
      'Complétez des parties pour voir votre handicap et vos statistiques de performance.';

  @override
  String get homeHandicapIndex => 'Index de handicap';

  @override
  String homeRoundsNeeded(int n) {
    return '$n/20 parties';
  }

  @override
  String homeMoreRoundsToUnlock(int n) {
    return '$n parties supplémentaires pour débloquer votre index de handicap';
  }

  @override
  String get homeFairwaysHit => 'Fairways touchés';

  @override
  String get homePar4And5 => 'Trous par 4 et 5';

  @override
  String get homeGIR => 'VER';

  @override
  String get homeAllHoles => 'Tous les trous';

  @override
  String get homeAvgPutts => 'Moy. putts';

  @override
  String get homePerHole => 'Par trou';

  @override
  String get homeBirdies => 'Birdies';

  @override
  String get homeAllRounds => 'Toutes les parties';

  @override
  String get homeToday => 'Aujourd\'hui';

  @override
  String get homeYesterday => 'Hier';

  @override
  String homeDaysAgo(int n) {
    return 'Il y a $n jours';
  }

  @override
  String get homeWeekAgo => 'Il y a 1 semaine';

  @override
  String get homeTwoWeeksAgo => 'Il y a 2 semaines';

  @override
  String get homeThreeWeeksAgo => 'Il y a 3 semaines';

  @override
  String homeMonthsAgo(int n) {
    return 'Il y a $n mois';
  }

  @override
  String homeInvitedToPlay(String name) {
    return '$name vous a invité à jouer';
  }

  @override
  String get homeChangeLocation => 'Changer d\'emplacement';

  @override
  String get homeSearchCityOrArea => 'Rechercher une ville ou une zone';

  @override
  String get homeLocationHint => 'ex. Dubaï, Paris, Montréal…';

  @override
  String get homeSearchLocation => 'Rechercher un emplacement';

  @override
  String get homeLocationNotFound =>
      'Emplacement introuvable. Essayez un autre nom de ville.';

  @override
  String get homeUseCurrentLocation => 'Utiliser ma position actuelle';

  @override
  String get homeWelcomeTour => 'Bienvenue sur TeeStats';

  @override
  String get homeWelcomeTourBody =>
      'Voici votre accueil — consultez d\'un coup d\'œil vos parties récentes, vos performances et les parcours à proximité.';

  @override
  String get homeFriendsAndLeaderboard => 'Amis & Classement';

  @override
  String get homeFriendsAndLeaderboardBody =>
      'Ajoutez des partenaires de golf, acceptez des demandes d\'amis et comparez les scores sur le classement. Un point vert apparaît lorsque vous avez une demande en attente.';

  @override
  String get homeStartARound => 'Démarrer une partie';

  @override
  String get homeStartARoundBody =>
      'Appuyez sur le bouton vert à tout moment pour commencer une nouvelle partie sur n\'importe quel parcours.';

  @override
  String get homeYourActiveRound => 'Votre partie en cours';

  @override
  String get homeResumeRoundBody =>
      'Si vous quittez en cours de partie, elle est sauvegardée ici. Appuyez sur Reprendre pour reprendre là où vous vous étiez arrêté.';

  @override
  String get homeRoundHistory => 'Historique des parties';

  @override
  String get homeRoundHistoryBody =>
      'Toutes vos parties terminées se trouvent ici. Appuyez sur une partie pour un bilan complet trou par trou.';

  @override
  String get homeYourStats => 'Vos statistiques';

  @override
  String get homeYourStatsBody =>
      'Suivez la tendance de votre handicap, les schémas de score, VER, fairways et coups gagnés dans le temps.';

  @override
  String get homeYourProfile => 'Votre profil';

  @override
  String get homeYourProfileBody =>
      'Définissez votre objectif de handicap, choisissez un avatar et consultez votre ADN de golf et votre style de jeu.';

  @override
  String get homeQuickStats => 'Statistiques rapides';

  @override
  String get homeQuickStatsBody =>
      'Moyennes en direct sur toutes vos parties — fairways, VER, putts et birdies par partie.';

  @override
  String get homeNearbyCourses => 'Parcours à proximité';

  @override
  String get homeNearbyCoursesBody =>
      'Parcours de golf près de votre emplacement. Appuyez sur un parcours pour démarrer une partie immédiatement.';

  @override
  String get roundsMyRounds => 'Mes parties';

  @override
  String get roundsRoundsTab => 'Parties';

  @override
  String get roundsPracticeTab => 'Entraînement';

  @override
  String get roundsTournamentsTab => 'Tournois';

  @override
  String get roundsHistoryTitle => 'Votre historique de parties';

  @override
  String get roundsHistorySubtitle =>
      'Toutes les parties terminées sont ici. Appuyez sur une partie pour un bilan complet trou par trou et les statistiques.';

  @override
  String get roundsInProgress => 'Partie en cours';

  @override
  String roundsHolesProgress(int played, int total) {
    return '$played/$total trous';
  }

  @override
  String get roundsNoRoundsYet => 'Aucune partie pour l\'instant';

  @override
  String get roundsStartFirst =>
      'Démarrez votre première partie depuis l\'onglet Accueil';

  @override
  String get roundsOrScanScorecard => 'ou scannez une carte de score papier';

  @override
  String get roundsDeleteTitle => 'Supprimer la partie ?';

  @override
  String roundsDeleteConfirm(String courseName) {
    return 'Supprimer définitivement votre partie à $courseName ?';
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
  String get roundSummaryComplete => 'Partie terminée !';

  @override
  String get roundSummaryScore => 'Score';

  @override
  String get roundSummaryVsPar => 'vs par';

  @override
  String get roundSummaryHoles => 'Trous';

  @override
  String get roundSummaryBackToHome => 'Retour à l\'accueil';

  @override
  String get roundSummaryEven => 'Égal';

  @override
  String get roundDetailScorecard => 'Carte de score';

  @override
  String get roundDetailShotTrails => 'Traces de coups';

  @override
  String get roundDetailHole => 'Trou';

  @override
  String get roundDetailPar => 'Par';

  @override
  String get roundDetailGIR => 'VER';

  @override
  String get roundDetailTotal => 'TOT';

  @override
  String get roundDetailShare => 'Partager la carte de score';

  @override
  String get roundDetailDelete => 'Supprimer la partie';

  @override
  String get roundDetailDeleteTitle => 'Supprimer la partie ?';

  @override
  String roundDetailDeleteConfirm(String courseName) {
    return 'Cela supprimera définitivement votre partie à $courseName.';
  }

  @override
  String get startRoundPickCourse => '📍  Choisissez votre parcours';

  @override
  String get startRoundWherePlaying => 'Où\njouez-vous ?';

  @override
  String get startRoundSearchHint =>
      'Rechercher un parcours de golf à proximité';

  @override
  String get startRoundCourseName => 'Nom du parcours';

  @override
  String get startRoundEnterCourseName => 'Saisissez le nom du parcours';

  @override
  String get startRoundFetchingTeeData => 'Récupération des données de départ…';

  @override
  String get startRoundSelectTee => 'SÉLECTIONNER LE DÉPART';

  @override
  String get startRoundCourseRating => 'ÉVALUATION DU PARCOURS (FACULTATIF)';

  @override
  String get startRoundRatingForHandicap =>
      'Pour un index de handicap USGA précis';

  @override
  String get startRoundCourseRatingLabel => 'Évaluation du parcours';

  @override
  String get startRoundCourseRatingHint => 'ex. 72.5';

  @override
  String get startRoundSlopeRatingLabel => 'Évaluation du slope';

  @override
  String get startRoundSlopeRatingHint => 'ex. 113';

  @override
  String get startRoundSlopeError => '55–155';

  @override
  String get startRoundNumberOfHoles => 'NOMBRE DE TROUS';

  @override
  String get startRoundHoles => 'Trous';

  @override
  String get startRoundInviteFriends => 'INVITER DES AMIS (MAX 3)';

  @override
  String get startRoundSearchFriends => 'Rechercher des amis…';

  @override
  String get startRoundNoFriends => 'Aucun ami pour l\'instant.';

  @override
  String get startRoundNoMatches => 'Aucun résultat.';

  @override
  String startRoundFriendsInvited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amis seront invités',
      one: '1 ami sera invité',
    );
    return '$_temp0';
  }

  @override
  String get startRoundTeeOff => 'Partez !';

  @override
  String get startRoundNoCoursesFound =>
      'Aucun parcours de golf trouvé à proximité';

  @override
  String get startRoundNoHoleData =>
      'Aucune donnée de trou trouvée pour ce parcours.';

  @override
  String get startRoundUploadScorecard => 'Importer une carte de score';

  @override
  String startRoundError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get scorecardScoringARound => 'Saisie d\'une partie';

  @override
  String get scorecardInstructions =>
      'Saisissez votre score, putts, fairway et VER pour chaque trou. Appuyez sur la crosse pour suivre votre sélection de club.';

  @override
  String get scorecardHole => 'Trou';

  @override
  String get scorecardPlayingWithFriends => 'Jouer avec des amis';

  @override
  String get scorecardScore => 'SCORE';

  @override
  String get scorecardPutts => 'PUTTS';

  @override
  String get scorecardFairwayHit => 'FAIRWAY TOUCHÉ';

  @override
  String get scorecardGIR => 'VERT EN RÉGLEMENTATION';

  @override
  String get scorecardTrackShots => 'Suivre les coups';

  @override
  String get scorecardTeeSet => 'Départ sélectionné';

  @override
  String scorecardShotsTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coups suivis',
      one: '1 coup suivi',
    );
    return '$_temp0';
  }

  @override
  String get scorecardClub => 'CLUB';

  @override
  String get scorecardScorecardLabel => 'CARTE DE SCORE';

  @override
  String get scorecardLeaveTitle => 'Quitter la partie ?';

  @override
  String get scorecardLeaveBody =>
      'Votre progression est sauvegardée automatiquement.\nVous pouvez reprendre cette partie depuis l\'écran d\'accueil.';

  @override
  String get scorecardSaveAndExit => 'Sauvegarder et quitter';

  @override
  String get scorecardKeepPlaying => 'Continuer à jouer';

  @override
  String get scorecardAbandon => 'Abandonner';

  @override
  String get scorecardNextHole => 'Trou suivant';

  @override
  String get scorecardFinishRound => 'Terminer la partie';

  @override
  String get scorecardAICaddy => 'CADDIE IA';

  @override
  String get scorecardTipPar3 =>
      'Par 3 : engagez-vous sur un seul club et faites confiance au swing.';

  @override
  String get scorecardTipInsightsUnlock =>
      'Jouez votre jeu — les conseils se débloquent après 3 trous.';

  @override
  String scorecardTipAvgPutts(String avgPutts) {
    return 'Moyenne de $avgPutts putts — concentrez-vous sur le putt de distance.';
  }

  @override
  String scorecardTipFairways(String fwhitPercent) {
    return 'Seulement $fwhitPercent% de fairways touchés — envisagez un bois 3 au départ.';
  }

  @override
  String get scorecardTipApproach =>
      'Les approches sont difficiles — visez le centre du green aujourd\'hui.';

  @override
  String get scorecardTipSolid =>
      'Bonne partie jusqu\'ici — gardez le même rythme et le même tempo.';

  @override
  String get scorecardYds => 'YDS';

  @override
  String scorecardPlaysLike(String distance) {
    return 'JOUE COMME $distance YDS';
  }

  @override
  String get scorecardEagle => 'Eagle';

  @override
  String get scorecardAlbatross => 'Albatros';

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
    return 'Modifier le trou $hole';
  }

  @override
  String scorecardErrorSaving(String error) {
    return 'Erreur lors de la sauvegarde : $error';
  }

  @override
  String get scorecardOn => 'OUI';

  @override
  String get scorecardOff => 'NON';

  @override
  String get statsHub => 'Votre tableau de bord';

  @override
  String get statsPlayMoreRounds =>
      'Jouez davantage de parties pour débloquer les graphiques de tendance, les coups gagnés et l\'analyse de distribution des scores.';

  @override
  String get statsHandicapIndex => 'Index de handicap';

  @override
  String statsBasedOnRounds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Basé sur $n parties',
      one: 'Basé sur 1 partie',
    );
    return '$_temp0';
  }

  @override
  String get statsCompleteToCalculate => 'Terminez des parties pour calculer';

  @override
  String get statsAvgScore => 'Score moyen';

  @override
  String get statsBestRound => 'Meilleure partie';

  @override
  String get statsTotalRounds => 'Total des parties';

  @override
  String get statsTotalBirdies => 'Total des birdies';

  @override
  String get statsScoreDistribution => 'Distribution des scores';

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
    return 'Score vs par (dernières $n parties)';
  }

  @override
  String get statsOldestToRecent => 'Plus ancien → Plus récent';

  @override
  String get statsHandicapTrend => 'Tendance du handicap';

  @override
  String statsGoal(String n) {
    return 'Objectif : $n';
  }

  @override
  String statsLatest(String n) {
    return 'Dernier : $n';
  }

  @override
  String get statsFairwaysHit => 'Fairways touchés';

  @override
  String get statsGIR => 'Verts en réglementation';

  @override
  String get statsAvgPuttsPerHole => 'Moy. putts / trou';

  @override
  String get statsClubStats => 'Statistiques par club';

  @override
  String get statsClubStatsSubtitle => 'Score vs par et moy. putts par club';

  @override
  String get statsClub => 'Club';

  @override
  String get statsHoles => 'Trous';

  @override
  String get statsAvgPlusMinus => 'Moy. ±par';

  @override
  String get statsAvgPutts => 'Moy. putts';

  @override
  String get statsStrokesGained => 'Coups gagnés';

  @override
  String get statsVsScratch => 'vs un golfeur scratch de référence';

  @override
  String get statsOffTheTee => 'Au départ';

  @override
  String get statsApproach => 'Approche';

  @override
  String get statsAroundGreen => 'Autour du green';

  @override
  String get statsPutting => 'Putting';

  @override
  String get statsBetterThanAvg => 'Meilleur\nque la moyenne';

  @override
  String get statsPressureScore => 'Score de Pression';

  @override
  String get statsPressureResilience => 'Résilience';

  @override
  String statsPressureUnlockHint(int count) {
    return 'Jouez $count partie(s) de plus pour débloquer votre profil mental';
  }

  @override
  String get statsPressureOpeningHole => '1er Trou';

  @override
  String get statsPressureBirdieHangover => 'Gueule de Bois Birdie';

  @override
  String get statsPressureBackNine => 'Déclin Retour 9';

  @override
  String get statsPressureFinishingStretch => 'Derniers Trous';

  @override
  String get statsPressureThreePutt => 'Timing 3 Putts';

  @override
  String get statsPressureTopDrill => 'Exercice Clé';

  @override
  String get statsPressureInsufficientData => 'Données insuffisantes';

  @override
  String get tournamentNoTournaments => 'Aucun tournoi pour l\'instant';

  @override
  String get tournamentCreateInstructions =>
      'Appuyez sur \"Nouveau tournoi\" pour en créer un,\npuis démarrez des parties pour scorer dans le tournoi.';

  @override
  String get tournamentNew => 'Nouveau tournoi';

  @override
  String get tournamentStartInstructions =>
      'Créez d\'abord un tournoi, puis utilisez le ＋ FAB sur l\'écran d\'accueil pour démarrer une partie de tournoi.';

  @override
  String get tournamentDeleteTitle => 'Supprimer le tournoi ?';

  @override
  String tournamentDeleteConfirm(String name) {
    return 'Supprimer \"$name\" ? Les parties elles-mêmes ne seront pas supprimées.';
  }

  @override
  String get tournamentRoundByRound => 'Partie par partie';

  @override
  String get tournamentVsPar => 'vs par';

  @override
  String get tournamentRoundsLabel => 'Parties';

  @override
  String get tournamentNameLabel => 'Nom du tournoi';

  @override
  String get tournamentNameHint => 'ex. Championnat du club 2026';

  @override
  String get tournamentCreate => 'Créer le tournoi';

  @override
  String tournamentRoundsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n parties',
      one: '1 partie',
    );
    return '$_temp0';
  }

  @override
  String get tournamentRunning => 'en cours';

  @override
  String get practiceNoSessions =>
      'Aucune séance d\'entraînement pour l\'instant';

  @override
  String get practiceStartInstructions =>
      'Démarrez une partie pour scorer des trous,\nou enregistrez des séances au practice et de petit jeu.';

  @override
  String get practiceLogSession => 'Enregistrer une séance';

  @override
  String get practiceScoredRound => 'Partie scorée';

  @override
  String get practiceDeleteTitle => 'Supprimer la séance ?';

  @override
  String get practiceDeleteConfirm =>
      'Cette séance d\'entraînement sera définitivement supprimée.';

  @override
  String get practiceLogTitle => 'Enregistrer une séance d\'entraînement';

  @override
  String get practiceType => 'Type';

  @override
  String get practiceBallsHit => 'Balles frappées';

  @override
  String get practiceDuration => 'Durée (min)';

  @override
  String get practiceNotes => 'Notes (facultatif)';

  @override
  String get practiceNotesHint => 'Sur quoi avez-vous travaillé ?';

  @override
  String get practiceSave => 'Sauvegarder la séance';

  @override
  String get friendsTitle => 'Amis';

  @override
  String get friendsLeaderboard => 'Classement';

  @override
  String get friendsNoFriendsYet => 'Aucun ami pour l\'instant';

  @override
  String get friendsEnterEmail =>
      'Saisissez l\'e-mail d\'un ami ci-dessus pour l\'ajouter';

  @override
  String get friendsSearchHint => 'Rechercher par adresse e-mail…';

  @override
  String get friendsPendingRequests => 'Demandes en attente';

  @override
  String get friendsWantsToBeF => 'Veut être ami';

  @override
  String get friendsRequestSent => 'Demande envoyée';

  @override
  String get friendsAcceptRequest => 'Accepter la demande';

  @override
  String get friendsAlreadyFriends => 'Déjà amis';

  @override
  String get friendsAddFriend => 'Ajouter un ami';

  @override
  String get friendsNoLeaderboard => 'Pas encore de classement';

  @override
  String get friendsAddToCompare => 'Ajoutez des amis pour comparer les scores';

  @override
  String get friendsHandicap => 'Handicap';

  @override
  String get friendsAvgScore => 'Score moyen';

  @override
  String get friendsYou => 'Vous';

  @override
  String get notifPrefsTitle => 'Notifications intelligentes';

  @override
  String get notifPrefsSubtitle => 'Alertes IA pour votre jeu';

  @override
  String get notifPrefsSectionTitle => 'TYPES DE NOTIFICATIONS';

  @override
  String get notifPrefsPracticeReminders => 'Rappels d\'entraînement';

  @override
  String get notifPrefsPracticeDesc =>
      'Exercices personnalisés par l\'IA pour vos points faibles';

  @override
  String get notifPrefsResumeRound => 'Reprendre la partie';

  @override
  String get notifPrefsResumeDesc =>
      'Rappels pour terminer les parties laissées en suspens';

  @override
  String get notifPrefsPerformance => 'Aperçus de performance';

  @override
  String get notifPrefsPerformanceDesc =>
      'Célébrez vos séries d\'améliorations et tendances';

  @override
  String get notifPrefsTeeTime => 'Rappels de départ';

  @override
  String get notifPrefsTeeTimeDesc => 'Alertes avant vos prochains départs';

  @override
  String get notifPrefsSaved => 'Préférences sauvegardées';

  @override
  String get notifPrefsPersonalised =>
      'Les notifications sont personnalisées en fonction de\nvos parties récentes et de vos tendances de performance.';

  @override
  String get notifPrefsAIDriven => '✨ Alertes pilotées par IA';

  @override
  String get notifPrefsSmartDesc =>
      'Notifications intelligentes\nadaptées à votre jeu de golf';

  @override
  String get notifPrefsExplanation =>
      'TeeStats analyse vos parties, vos habitudes d\'entraînement et vos tendances de performance pour envoyer des notifications qui améliorent réellement votre jeu.';

  @override
  String get notifPrefsSave => 'Sauvegarder les préférences';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSubtitle => 'Personnalisez-le';

  @override
  String get profileDescription =>
      'Définissez votre objectif de handicap, choisissez un avatar et explorez votre ADN de golf et votre style de jeu.';

  @override
  String get profileGolfer => 'Golfeur';

  @override
  String get profileGolfPlaces => 'Lieux de golf';

  @override
  String get profileEditProfile => 'Modifier le profil';

  @override
  String get profileSmartNotifications => 'Notifications intelligentes';

  @override
  String get profileAchievementsSection => 'RÉUSSITES';

  @override
  String get profileRounds => 'Parties';

  @override
  String get profileHandicap => 'Handicap';

  @override
  String get profileBirdies => 'Birdies';

  @override
  String get profileAccount => 'Compte';

  @override
  String get profileSignOut => 'Se déconnecter';

  @override
  String get profileDeleteAccount => 'Supprimer le compte';

  @override
  String profileVersion(String version) {
    return 'TeeStats v$version';
  }

  @override
  String profileCopyright(String year) {
    return '© $year TeeStats. Tous droits réservés.';
  }

  @override
  String get profileHandicapGoal => 'Objectif de handicap';

  @override
  String get profileHandicapGoalDesc =>
      'Définissez un index de handicap cible à suivre sur votre graphique de tendance.';

  @override
  String profileTargetPrefix(String value) {
    return 'Cible : $value';
  }

  @override
  String get profileNotSet => 'Non défini — appuyez pour définir';

  @override
  String get profileClear => 'Effacer';

  @override
  String get profileSaveGoal => 'Sauvegarder l\'objectif';

  @override
  String get profileSignOutTitle => 'Se déconnecter ?';

  @override
  String get profileSignOutBody =>
      'Vous serez redirigé vers l\'écran de connexion.';

  @override
  String get profileDeleteTitle => 'Supprimer le compte ?';

  @override
  String get profileDeleteBody =>
      'Cela supprimera définitivement votre compte et toutes vos données de golf, y compris les parties, les statistiques et les réussites.';

  @override
  String get profileDeleteAreYouSure => 'Êtes-vous absolument sûr ?';

  @override
  String get profileDeleteRoundsItem => 'Toutes vos parties et cartes de score';

  @override
  String get profileDeleteStatsItem =>
      'Statistiques, historique du handicap et réussites';

  @override
  String get profileDeleteProfileItem => 'Votre profil et vos préférences';

  @override
  String get profileDeleteNotificationsItem =>
      'Notifications intelligentes et heures de départ';

  @override
  String get profileDeleteCannotUndo => 'Cette action est irréversible.';

  @override
  String get profileDeleteButton => 'Supprimer mon compte';

  @override
  String get profileKeepButton => 'Conserver mon compte';

  @override
  String get profileDeletingAccount => 'Suppression du compte…';

  @override
  String get profileReauthRequired =>
      'Veuillez vous déconnecter et vous reconnecter avant de supprimer votre compte.';

  @override
  String get profileSomethingWrong =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get profileContinue => 'Continuer';

  @override
  String get profileDisplayName => 'Nom d\'affichage';

  @override
  String get profileSaveChanges => 'Sauvegarder les modifications';

  @override
  String get profileChooseAvatar => 'Choisir un avatar';

  @override
  String get profileSelectPresetAvatar => 'Sélectionner un avatar prédéfini';

  @override
  String get profileRemoveAvatar => 'Supprimer l\'avatar';

  @override
  String get profileSaveAvatar => 'Sauvegarder l\'avatar';

  @override
  String get shotTrackerTapToMark =>
      'Appuyez sur la carte pour marquer le départ';

  @override
  String get shotTrackerTeeMarked =>
      'Départ marqué · appuyez pour suivre les coups';

  @override
  String shotTrackerShotsFromTee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coups depuis le départ',
      one: '1 coup depuis le départ',
    );
    return '$_temp0';
  }

  @override
  String get shotTrackerAcquiringGPS => 'Acquisition du GPS…';

  @override
  String shotTrackerDistToPin(String distance) {
    return '$distance yds jusqu\'au drapeau';
  }

  @override
  String shotTrackerLastShot(String distance) {
    return 'Dernier coup : $distance yds';
  }

  @override
  String get shotTrackerUndo => 'Annuler';

  @override
  String get shotTrackerFinishHole => 'Terminer le trou';

  @override
  String shotTrackerFinishHoleWithCount(int count) {
    return 'Terminer le trou  ($count coups)';
  }

  @override
  String get shotTrackerNiceApproach => 'Belle approche !';

  @override
  String shotTrackerOnGreen(String shotCount, int holeNumber) {
    return 'Vous êtes sur le green — ${shotCount}Prêt à enregistrer les putts pour le trou $holeNumber ?';
  }

  @override
  String get shotTrackerNotYet => 'Pas encore';

  @override
  String shotTrackerLogPutts(int holeNumber) {
    return 'Enregistrer les putts pour le trou $holeNumber';
  }

  @override
  String get swingAnalyzerTitle => 'Analyseur de swing';

  @override
  String get swingAnalyzerSaveToGallery => 'Enregistrer dans la galerie';

  @override
  String get swingAnalyzerShare => 'Partager';

  @override
  String get swingAnalyzerLoadingVideo => 'Chargement de la vidéo…';

  @override
  String get swingAnalyzerUploading => 'Envoi de la vidéo…';

  @override
  String get swingAnalyzerAnalyzing => 'Analyse de la trajectoire…';

  @override
  String get swingAnalyzerPreviewUnavailable =>
      'Aperçu indisponible — appuyez là où se trouve la balle';

  @override
  String get swingAnalyzerTapBall => 'Appuyez sur la balle de golf';

  @override
  String get swingAnalyzerReposition => 'Appuyez pour repositionner';

  @override
  String get swingAnalyzerSkip => 'Passer';

  @override
  String get swingAnalyzerAnalyze => 'Analyser';

  @override
  String get swingAnalyzerAITracerTitle => 'Traceur de swing IA';

  @override
  String get swingAnalyzerAITracerDesc =>
      'Enregistrez ou importez une vidéo de swing de golf.\nGemini IA suivra la balle et superposera un traceur en direct.';

  @override
  String get swingAnalyzerButton => 'Analyser le swing';

  @override
  String get swingAnalyzerComingSoon => 'Bientôt disponible';

  @override
  String get swingAnalyzerComingSoonMsg =>
      'Le traceur de swing IA est en cours de développement. Restez à l\'affût de la mise à jour !';

  @override
  String get swingAnalyzerGotIt => 'Compris';

  @override
  String get swingAnalyzerFailed => 'Analyse échouée';

  @override
  String get swingAnalyzerFailedMsg =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get swingAnalyzerTryAgain => 'Réessayer';

  @override
  String get swingAnalyzerRecording => 'REC';

  @override
  String get swingAnalyzerBallNotDetected => 'Balle non détectée dans la vidéo';

  @override
  String get swingAnalyzerNoVideoFile => 'Aucun fichier vidéo à sauvegarder';

  @override
  String get swingAnalyzerVideoSaved => 'Vidéo enregistrée dans la galerie';

  @override
  String swingAnalyzerCouldNotSave(String error) {
    return 'Impossible de sauvegarder la vidéo : $error';
  }

  @override
  String get swingAnalyzerShareText =>
      'Regardez ma trace de swing depuis TeeStats ! 🏌️';

  @override
  String get swingAnalyzerShotAnalysis => 'Analyse du coup';

  @override
  String get swingAnalyzerCarry => 'Portée';

  @override
  String get swingAnalyzerHeight => 'Hauteur';

  @override
  String get swingAnalyzerLaunch => 'Angle de départ';

  @override
  String get swingAnalyzerPathNotDetected =>
      'Trajectoire non détectée. Essayez avec un meilleur éclairage ou un angle plus proche.';

  @override
  String get swingAnalyzerAnotherSwing => 'Analyser un autre swing';

  @override
  String get scorecardUploadTitle => 'Scanner votre carte de score';

  @override
  String get scorecardUploadDesc =>
      'L\'IA extraira les données trou par trou, y compris le par, le yardage et le handicap.';

  @override
  String get scorecardUploadChooseSource => 'CHOISIR LA SOURCE';

  @override
  String get scorecardUploadTakePhoto => 'Prendre une photo';

  @override
  String get scorecardUploadFromGallery => 'Choisir dans la galerie';

  @override
  String get scorecardUploadAnalyzing => 'Analyse de la carte de score…';

  @override
  String get scorecardUploadAnalyzingNote =>
      'Cela prend généralement quelques secondes';

  @override
  String get scorecardUploadReviewTitle => 'Vérifier la carte de score';

  @override
  String get scorecardUploadUploadTitle => 'Importer la carte de score';

  @override
  String get scorecardUploadCourseName => 'NOM DU PARCOURS';

  @override
  String get scorecardUploadCourseNameHint => 'Saisissez le nom du parcours';

  @override
  String get scorecardUploadCityState => 'Ville, Région';

  @override
  String get scorecardUploadSelectTee => 'SÉLECTIONNER LE DÉPART';

  @override
  String get scorecardUploadRetake => 'Reprendre';

  @override
  String get scorecardUploadSaveUse => 'Sauvegarder et utiliser';

  @override
  String get scorecardUploadNoTeeData =>
      'Aucune donnée de départ extraite. Essayez une photo plus nette.';

  @override
  String scorecardUploadFailed(String error) {
    return 'Extraction échouée. Essayez une photo plus nette.\n$error';
  }

  @override
  String get scorecardUploadRating => 'Évaluation';

  @override
  String get scorecardUploadSlope => 'Slope';

  @override
  String get scorecardUploadHoleHeader => 'TROU';

  @override
  String get scorecardUploadParHeader => 'PAR';

  @override
  String get scorecardUploadYdsHeader => 'YDS';

  @override
  String get scorecardUploadHcpHeader => 'HCP';

  @override
  String scorecardUploadRatingFooter(String rating) {
    return 'Évaluation $rating';
  }

  @override
  String scorecardUploadSlopeFooter(String slope) {
    return 'Slope $slope';
  }

  @override
  String get scorecardUploadValidation => 'Veuillez saisir le nom du parcours.';

  @override
  String get scorecardUploadMissingScores => 'Certains scores manquants';

  @override
  String get scorecardUploadMissingMsg =>
      'Quelques trous affichent encore 0. Ils seront sauvegardés avec 0 coup — vous pouvez les modifier après l\'import.';

  @override
  String get scorecardUploadImportAnyway => 'Importer quand même';

  @override
  String get scorecardUploadFixFirst => 'Corriger d\'abord';

  @override
  String get scorecardImportCourse => 'Parcours';

  @override
  String get scorecardImportCourseNameHint => 'Nom du parcours';

  @override
  String get scorecardImportLocationHint =>
      'Emplacement — recherchez un parcours ci-dessus';

  @override
  String get scorecardImportNoCoursesFound => 'Aucun parcours de golf trouvé';

  @override
  String get scorecardImportButton => 'Importer';

  @override
  String get scorecardImportConditions => 'Conditions de la partie';

  @override
  String get scorecardImportAvgTemp => 'Temp. moy.';

  @override
  String get scorecardImportAvgWind => 'Vent moy.';

  @override
  String get scorecardImportConditionsLabel => 'Conditions';

  @override
  String get scorecardImportWeatherUnavailable => 'Météo indisponible';

  @override
  String get scorecardImportToday => 'Aujourd\'hui';

  @override
  String get scorecardImportHowToAdd =>
      'Comment souhaitez-vous ajouter votre carte de score ?';

  @override
  String get scorecardImportTakePhoto => 'Prendre une photo';

  @override
  String get scorecardImportPhotoDesc =>
      'Photographiez votre carte de score papier';

  @override
  String get scorecardImportFromLibrary => 'Choisir dans la bibliothèque';

  @override
  String get scorecardImportLibraryDesc => 'Sélectionner une photo existante';

  @override
  String get scorecardImportReading => 'Lecture de votre carte de score…';

  @override
  String get scorecardImportAnalyzing =>
      'Analyse par IA — cela prend quelques secondes';

  @override
  String get scorecardImportUnableRead =>
      'Impossible de lire la carte de score';

  @override
  String get scorecardImportConnectionError =>
      'Impossible de joindre le service IA. Vérifiez votre connexion et réessayez.';

  @override
  String get notifPersonalBestTitle => '🏆 Nouveau record personnel !';

  @override
  String notifPersonalBestMsg(String score) {
    return 'Vous avez scoré $score — votre meilleure partie à ce jour. Continuez ainsi !';
  }

  @override
  String get notifTeeTime1HourTitle => '⛳ Départ dans 1 heure !';

  @override
  String notifTeeTime1HourMsg(String courseName) {
    return 'Préparez-vous pour votre partie à $courseName.';
  }

  @override
  String get notifTeeTime15MinTitle => '⛳ Départ dans 15 minutes !';

  @override
  String notifTeeTime15MinMsg(String courseName) {
    return 'Dirigez-vous vers le premier départ à $courseName.';
  }

  @override
  String get notifStreakTitle => '⛳ Il est temps d\'aller sur le parcours !';

  @override
  String get notifStreakMsg =>
      'Cela fait un moment depuis votre dernière partie. Allez-y !';

  @override
  String get noNotificationsTitle => 'Aucune notification pour l\'instant';

  @override
  String get noNotificationsDesc =>
      'Jouez davantage de parties pour débloquer\ndes alertes personnalisées par IA';

  @override
  String get widgetLeaderboardTitle => 'Classement en direct';

  @override
  String get widgetLeaderboardUpdates => 'Mise à jour après chaque trou';

  @override
  String get widgetLeaderboardPos => 'POS';

  @override
  String get widgetLeaderboardPlayer => 'JOUEUR';

  @override
  String get widgetLeaderboardThru => 'JOUÉ';

  @override
  String get widgetLeaderboardScore => 'SCORE';

  @override
  String widgetLeaderboardThruHoles(String holes) {
    return 'Joué $holes';
  }

  @override
  String get widgetLeaderboardTeeOff => 'Départ';

  @override
  String get widgetLeaderboardFinished => 'F';

  @override
  String get widgetLeaderboardInvited => 'Invité';

  @override
  String get widgetLeaderboardDeclined => 'Refusé';

  @override
  String get widgetUnfinishedRound => 'Partie inachevée';

  @override
  String widgetHolesPlayed(int played, int total) {
    return '$played / $total trous joués';
  }

  @override
  String get widgetResumeRound => 'Reprendre la partie';

  @override
  String get widgetDiscardTitle => 'Abandonner la partie ?';

  @override
  String widgetDiscardMsg(String courseName) {
    return 'Toute la progression sur \"$courseName\" sera définitivement perdue.';
  }

  @override
  String get widgetKeep => 'Conserver';

  @override
  String get widgetDiscard => 'Abandonner';

  @override
  String get widgetClubsHint =>
      'Appuyez sur les clubs ci-dessous pour suivre chaque coup';

  @override
  String widgetClubsSelected(int count, int max) {
    return '$count sur $max clubs sélectionnés';
  }

  @override
  String get widgetGolfDNA => 'ADN DE GOLF';

  @override
  String get widgetProAnalysis => 'ANALYSE PRO';

  @override
  String get widgetPower => 'Puissance';

  @override
  String get widgetAccuracy => 'Précision';

  @override
  String get widgetPutting => 'Putting';

  @override
  String get widgetStrengthsWeaknesses => 'Points forts & Points faibles';

  @override
  String get widgetPerformanceTrends => 'Tendances de performance';

  @override
  String get widgetTraitAnalysis => 'Analyse des traits';

  @override
  String get widgetDrivingPower => 'Puissance de drive';

  @override
  String get widgetConsistency => 'Régularité';

  @override
  String get widgetRiskLevel => 'Niveau de risque';

  @override
  String get widgetStamina => 'Endurance';

  @override
  String get widgetAIRoundSummary => 'Résumé de partie par IA';

  @override
  String get widgetAnalyzingRound => 'Analyse de votre partie…';

  @override
  String get widgetGemini => 'Gemini';

  @override
  String get widgetStrength => 'Point fort';

  @override
  String get widgetWeakness => 'Point faible';

  @override
  String get widgetFocusArea => 'Axe de travail';

  @override
  String get widgetPlayStyle => 'STYLE DE JEU';

  @override
  String get widgetAIPowered => 'Propulsé par IA';

  @override
  String widgetUpdated(String date) {
    return 'Mis à jour $date';
  }

  @override
  String get widgetUpdatedToday => 'aujourd\'hui';

  @override
  String get widgetUpdatedYesterday => 'hier';

  @override
  String widgetUpdatedDaysAgo(int days) {
    return 'il y a ${days}j';
  }

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int minutes) {
    return 'il y a ${minutes}min';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'il y a ${hours}h';
  }

  @override
  String timeDaysAgo(int days) {
    return 'il y a ${days}j';
  }
}
