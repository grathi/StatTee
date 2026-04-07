// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'TeeStats';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get done => 'Listo';

  @override
  String get search => 'Buscar';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Volver';

  @override
  String get skip => 'Omitir';

  @override
  String get close => 'Cerrar';

  @override
  String get edit => 'Editar';

  @override
  String get view => 'Ver';

  @override
  String get accept => 'Aceptar';

  @override
  String get decline => 'Rechazar';

  @override
  String get home => 'Inicio';

  @override
  String get rounds => 'Rondas';

  @override
  String get stats => 'Estadísticas';

  @override
  String get profile => 'Perfil';

  @override
  String get friends => 'Amigos';

  @override
  String get loginWelcomeBack => 'Bienvenido de nuevo';

  @override
  String get loginSignInToContinue => 'Inicia sesión para continuar';

  @override
  String get loginEmail => 'Correo electrónico';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginSignIn => 'Iniciar sesión';

  @override
  String get loginDontHaveAccount => '¿No tienes una cuenta?';

  @override
  String get loginSignUp => 'Registrarse';

  @override
  String get loginTagline => 'Juega  ·  Registra  ·  Mejora';

  @override
  String get loginResetPasswordTitle => 'Restablecer contraseña';

  @override
  String get loginResetPasswordSubtitle =>
      'Te enviaremos un enlace de restablecimiento a tu correo';

  @override
  String get loginEnterYourEmail => 'Introduce tu correo electrónico';

  @override
  String get loginEnterValidEmail => 'Introduce un correo electrónico válido';

  @override
  String get loginSendResetLink => 'Enviar enlace de restablecimiento';

  @override
  String get loginResetLinkSent => '¡Enlace de restablecimiento enviado!';

  @override
  String loginCheckInboxFor(String email) {
    return 'Revisa tu bandeja de entrada para $email';
  }

  @override
  String get loginErrorNoAccount =>
      'No se encontró ninguna cuenta con este correo.';

  @override
  String get loginErrorInvalidEmail =>
      'Por favor introduce un correo electrónico válido.';

  @override
  String get loginErrorSomethingWrong => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get loginErrorIncorrectCredentials =>
      'Correo electrónico o contraseña incorrectos.';

  @override
  String get loginErrorAccountDisabled => 'Esta cuenta ha sido desactivada.';

  @override
  String get loginErrorTooManyAttempts =>
      'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get loginErrorTryAgain =>
      'Algo salió mal. Por favor inténtalo de nuevo.';

  @override
  String get signupCreateAccount => 'Crear cuenta';

  @override
  String get signupJoinToday => 'Únete a TeeStats hoy';

  @override
  String get signupFullName => 'Nombre completo';

  @override
  String get signupEnterYourName => 'Introduce tu nombre';

  @override
  String get signupEmail => 'Correo electrónico';

  @override
  String get signupPassword => 'Contraseña';

  @override
  String get signupConfirmPassword => 'Confirmar contraseña';

  @override
  String get signupEnterPassword => 'Introduce una contraseña';

  @override
  String get signupMinimumChars => 'Mínimo 6 caracteres';

  @override
  String get signupConfirmYourPassword => 'Confirma tu contraseña';

  @override
  String get signupPasswordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String signupPasswordStrength(String label) {
    return 'Seguridad de la contraseña: $label';
  }

  @override
  String get signupPasswordWeak => 'Débil';

  @override
  String get signupPasswordFair => 'Regular';

  @override
  String get signupPasswordGood => 'Buena';

  @override
  String get signupPasswordStrong => 'Fuerte';

  @override
  String get signupAlreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get signupErrorAccountExists =>
      'Ya existe una cuenta con este correo electrónico.';

  @override
  String get signupErrorInvalidEmail =>
      'Por favor introduce una dirección de correo electrónico válida.';

  @override
  String get signupErrorWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get signupErrorNotEnabled =>
      'El registro por correo electrónico no está habilitado.';

  @override
  String get onboardingTagline => 'Golpea. Registra. Gana.';

  @override
  String get onboardingScoreTrackingTag => 'REGISTRO DE PUNTUACIÓN';

  @override
  String get onboardingTrackEveryRoundTitle => 'Registra cada\nronda';

  @override
  String get onboardingScoreTrackingBody =>
      'Puntuación con GPS para cada hoyo. Tu historial completo de rondas, siempre en tu bolsillo.';

  @override
  String get onboardingPerformanceTag => 'RENDIMIENTO';

  @override
  String get onboardingGolfDNATitle => 'Conoce tu\nADN golfístico';

  @override
  String get onboardingPerformanceBody =>
      'Calles acertadas, GIR, putts por ronda, tendencias de hándicap — identifica exactamente dónde mejorar.';

  @override
  String get onboardingMultiplayerTag => 'MULTIJUGADOR';

  @override
  String get onboardingPlayTogetherTitle => 'Juega\njunto';

  @override
  String get onboardingMultiplayerBody =>
      'Invita a amigos a una ronda grupal en vivo. Marcador en tiempo real, sin registro extra de puntuación.';

  @override
  String get onboardingSocialTag => 'SOCIAL';

  @override
  String get onboardingFriendsLeaderboardTitle => 'Amigos y\nMarcador';

  @override
  String get onboardingSocialBody =>
      'Conecta con tu grupo de golf. Mira quién está en racha y desafíalos a superarte.';

  @override
  String get onboardingAITag => 'CON IA';

  @override
  String get onboardingPersonalCaddieTitle => 'Tu caddie\npersonal';

  @override
  String get onboardingAIBody =>
      'Después de cada ronda, la IA Gemini analiza tus estadísticas y ofrece consejos de entrenamiento — fortalezas, debilidades y un área de enfoque para mejorar la próxima vez.';

  @override
  String get onboardingPoweredByGemini => 'Impulsado por Google Gemini';

  @override
  String get homeReadyToPlay => '⛳  ¿Listo para jugar?';

  @override
  String get homeStartRound => 'Iniciar ronda';

  @override
  String get homeTapToTeeOff => 'Toca para empezar';

  @override
  String get homeGolfNews => 'Noticias de golf';

  @override
  String get homeSeeAll => 'Ver todo';

  @override
  String get homeRecentRounds => 'Rondas recientes';

  @override
  String get homeViewAll => 'Ver todas';

  @override
  String get homeNoRoundsYet => 'Sin rondas aún — ¡empieza la primera!';

  @override
  String get homeInProgress => 'En progreso';

  @override
  String get homeActive => 'Activa';

  @override
  String get homeNoLocation => 'Sin ubicación';

  @override
  String get homePerformance => 'Rendimiento';

  @override
  String get homeCompleteRoundsForStats =>
      'Completa rondas para ver tu hándicap y estadísticas de rendimiento.';

  @override
  String get homeHandicapIndex => 'Índice de hándicap';

  @override
  String homeRoundsNeeded(int n) {
    return '$n/20 rondas';
  }

  @override
  String homeMoreRoundsToUnlock(int n) {
    return '$n rondas más para desbloquear tu Índice de hándicap';
  }

  @override
  String get homeFairwaysHit => 'Calles acertadas';

  @override
  String get homePar4And5 => 'Hoyos par 4 y 5';

  @override
  String get homeGIR => 'Greens en reg.';

  @override
  String get homeAllHoles => 'Todos los hoyos';

  @override
  String get homeAvgPutts => 'Putts prom.';

  @override
  String get homePerHole => 'Por hoyo';

  @override
  String get homeBirdies => 'Birdies';

  @override
  String get homeAllRounds => 'Todas las rondas';

  @override
  String get homeToday => 'Hoy';

  @override
  String get homeYesterday => 'Ayer';

  @override
  String homeDaysAgo(int n) {
    return 'Hace $n días';
  }

  @override
  String get homeWeekAgo => 'Hace 1 semana';

  @override
  String get homeTwoWeeksAgo => 'Hace 2 semanas';

  @override
  String get homeThreeWeeksAgo => 'Hace 3 semanas';

  @override
  String homeMonthsAgo(int n) {
    return 'Hace $n meses';
  }

  @override
  String homeInvitedToPlay(String name) {
    return '$name te invitó a jugar';
  }

  @override
  String get homeChangeLocation => 'Cambiar ubicación';

  @override
  String get homeSearchCityOrArea => 'Busca una ciudad o zona';

  @override
  String get homeLocationHint => 'p.ej. Dubai, Londres, Nueva York…';

  @override
  String get homeSearchLocation => 'Buscar ubicación';

  @override
  String get homeLocationNotFound =>
      'Ubicación no encontrada. Prueba con otro nombre de ciudad.';

  @override
  String get homeUseCurrentLocation => 'Usar mi ubicación actual';

  @override
  String get homeWelcomeTour => 'Bienvenido a TeeStats';

  @override
  String get homeWelcomeTourBody =>
      'Este es tu inicio — consulta rondas recientes, rendimiento y campos cercanos de un vistazo.';

  @override
  String get homeFriendsAndLeaderboard => 'Amigos y marcador';

  @override
  String get homeFriendsAndLeaderboardBody =>
      'Agrega compañeros de golf, acepta solicitudes de amistad y compara puntuaciones en el marcador. Un punto verde aparece cuando tienes una solicitud pendiente.';

  @override
  String get homeStartARound => 'Iniciar una ronda';

  @override
  String get homeStartARoundBody =>
      'Toca el botón verde en cualquier momento para comenzar a puntuar una nueva ronda en cualquier campo.';

  @override
  String get homeYourActiveRound => 'Tu ronda activa';

  @override
  String get homeResumeRoundBody =>
      'Si sales a mitad de ronda, se guarda aquí. Toca Reanudar para continuar donde lo dejaste.';

  @override
  String get homeRoundHistory => 'Historial de rondas';

  @override
  String get homeRoundHistoryBody =>
      'Todas tus rondas completadas están aquí. Toca cualquier ronda para ver el desglose hoyo por hoyo.';

  @override
  String get homeYourStats => 'Tus estadísticas';

  @override
  String get homeYourStatsBody =>
      'Sigue la tendencia de tu hándicap, patrones de puntuación, GIR, calles y golpes ganados a lo largo del tiempo.';

  @override
  String get homeYourProfile => 'Tu perfil';

  @override
  String get homeYourProfileBody =>
      'Establece tu objetivo de hándicap, elige un avatar y ve tu ADN golfístico e identidad de estilo de juego.';

  @override
  String get homeQuickStats => 'Estadísticas rápidas';

  @override
  String get homeQuickStatsBody =>
      'Promedios en vivo de todas tus rondas — calles, GIR, putts y birdies por ronda.';

  @override
  String get homeNearbyCourses => 'Campos cercanos';

  @override
  String get homeNearbyCoursesBody =>
      'Campos de golf cerca de tu ubicación. Toca cualquier campo para iniciar una ronda allí al instante.';

  @override
  String get roundsMyRounds => 'Mis rondas';

  @override
  String get roundsRoundsTab => 'Rondas';

  @override
  String get roundsPracticeTab => 'Práctica';

  @override
  String get roundsTournamentsTab => 'Torneos';

  @override
  String get roundsHistoryTitle => 'Tu historial de rondas';

  @override
  String get roundsHistorySubtitle =>
      'Todas las rondas completadas están aquí. Toca cualquier ronda para ver el desglose hoyo por hoyo y estadísticas.';

  @override
  String get roundsInProgress => 'Ronda en progreso';

  @override
  String roundsHolesProgress(int played, int total) {
    return '$played/$total hoyos';
  }

  @override
  String get roundsNoRoundsYet => 'Sin rondas aún';

  @override
  String get roundsStartFirst =>
      'Empieza tu primera ronda desde la pestaña Inicio';

  @override
  String get roundsOrScanScorecard =>
      'o escanea una tarjeta de puntuación en papel';

  @override
  String get roundsDeleteTitle => '¿Eliminar ronda?';

  @override
  String roundsDeleteConfirm(String courseName) {
    return '¿Eliminar permanentemente tu ronda en $courseName?';
  }

  @override
  String get roundsBirdies => 'Birdies';

  @override
  String get roundsPars => 'Pares';

  @override
  String get roundsBogeys => 'Bogeys';

  @override
  String get roundsPutts => 'Putts';

  @override
  String get roundsFIR => 'FIR';

  @override
  String get roundSummaryComplete => '¡Ronda completada!';

  @override
  String get roundSummaryScore => 'Puntuación';

  @override
  String get roundSummaryVsPar => 'vs Par';

  @override
  String get roundSummaryHoles => 'Hoyos';

  @override
  String get roundSummaryBackToHome => 'Volver al inicio';

  @override
  String get roundSummaryEven => 'Par';

  @override
  String get roundDetailScorecard => 'Tarjeta de puntuación';

  @override
  String get roundDetailShotTrails => 'Trayectorias de golpes';

  @override
  String get roundDetailHole => 'Hoyo';

  @override
  String get roundDetailPar => 'Par';

  @override
  String get roundDetailGIR => 'GIR';

  @override
  String get roundDetailTotal => 'TOT';

  @override
  String get roundDetailShare => 'Compartir tarjeta de puntuación';

  @override
  String get roundDetailDelete => 'Eliminar ronda';

  @override
  String get roundDetailDeleteTitle => '¿Eliminar ronda?';

  @override
  String roundDetailDeleteConfirm(String courseName) {
    return 'Esto eliminará permanentemente tu ronda en $courseName.';
  }

  @override
  String get startRoundPickCourse => '📍  Elige tu campo';

  @override
  String get startRoundWherePlaying => '¿Dónde vas\na jugar?';

  @override
  String get startRoundSearchHint => 'Busca un campo de golf cercano';

  @override
  String get startRoundCourseName => 'Nombre del campo';

  @override
  String get startRoundEnterCourseName => 'Introduce el nombre del campo';

  @override
  String get startRoundFetchingTeeData => 'Obteniendo datos de tee…';

  @override
  String get startRoundSelectTee => 'SELECCIONAR TEE';

  @override
  String get startRoundCourseRating => 'RATING DEL CAMPO (OPCIONAL)';

  @override
  String get startRoundRatingForHandicap =>
      'Para un Índice de hándicap USGA preciso';

  @override
  String get startRoundCourseRatingLabel => 'Rating del campo';

  @override
  String get startRoundCourseRatingHint => 'p.ej. 72.5';

  @override
  String get startRoundSlopeRatingLabel => 'Rating de slope';

  @override
  String get startRoundSlopeRatingHint => 'p.ej. 113';

  @override
  String get startRoundSlopeError => '55–155';

  @override
  String get startRoundNumberOfHoles => 'NÚMERO DE HOYOS';

  @override
  String get startRoundHoles => 'Hoyos';

  @override
  String get startRoundInviteFriends => 'INVITAR AMIGOS (MÁX. 3)';

  @override
  String get startRoundSearchFriends => 'Buscar amigos…';

  @override
  String get startRoundNoFriends => 'Sin amigos aún.';

  @override
  String get startRoundNoMatches => 'Sin resultados.';

  @override
  String startRoundFriendsInvited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos serán invitados',
      one: '1 amigo será invitado',
    );
    return '$_temp0';
  }

  @override
  String get startRoundTeeOff => '¡Salida!';

  @override
  String get startRoundNoCoursesFound =>
      'No se encontraron campos de golf cercanos';

  @override
  String get startRoundNoHoleData =>
      'No se encontraron datos de hoyos para este campo.';

  @override
  String get startRoundUploadScorecard => 'Subir tarjeta de puntuación';

  @override
  String startRoundError(String error) {
    return 'Error: $error';
  }

  @override
  String get scorecardScoringARound => 'Puntuando una ronda';

  @override
  String get scorecardInstructions =>
      'Introduce tu puntuación, putts, calle y GIR para cada hoyo. Toca el palo para registrar la selección de palo.';

  @override
  String get scorecardHole => 'Hoyo';

  @override
  String get scorecardPlayingWithFriends => 'Jugando con amigos';

  @override
  String get scorecardScore => 'PUNTUACIÓN';

  @override
  String get scorecardPutts => 'PUTTS';

  @override
  String get scorecardFairwayHit => 'CALLE ACERTADA';

  @override
  String get scorecardGIR => 'GREEN EN REGULACIÓN';

  @override
  String get scorecardTrackShots => 'Registrar golpes';

  @override
  String get scorecardTeeSet => 'Set de tee';

  @override
  String scorecardShotsTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count golpes registrados',
      one: '1 golpe registrado',
    );
    return '$_temp0';
  }

  @override
  String get scorecardClub => 'PALO';

  @override
  String get scorecardScorecardLabel => 'TARJETA DE PUNTUACIÓN';

  @override
  String get scorecardLeaveTitle => '¿Salir de la ronda?';

  @override
  String get scorecardLeaveBody =>
      'Tu progreso se guarda automáticamente.\nPuedes reanudar esta ronda desde la pantalla de inicio.';

  @override
  String get scorecardSaveAndExit => 'Guardar y salir';

  @override
  String get scorecardKeepPlaying => 'Seguir jugando';

  @override
  String get scorecardAbandon => 'Abandonar';

  @override
  String get scorecardNextHole => 'Siguiente hoyo';

  @override
  String get scorecardFinishRound => 'Terminar ronda';

  @override
  String get scorecardAICaddy => 'CADDIE IA';

  @override
  String get scorecardTipPar3 =>
      'Par 3: comprométete con un palo y confía en el swing.';

  @override
  String get scorecardTipInsightsUnlock =>
      'Juega tu juego — los análisis se desbloquean tras 3 hoyos.';

  @override
  String scorecardTipAvgPutts(String avgPutts) {
    return 'Promediando $avgPutts putts — enfócate en el putt de control desde lejos.';
  }

  @override
  String scorecardTipFairways(String fwhitPercent) {
    return 'Solo $fwhitPercent% de calles acertadas — considera un 3-madera desde el tee.';
  }

  @override
  String get scorecardTipApproach =>
      'Los golpes de aproximación están fallando — apunta al centro del green hoy.';

  @override
  String get scorecardTipSolid =>
      'Buena ronda hasta ahora — mantén el mismo ritmo y tempo.';

  @override
  String get scorecardYds => 'YDS';

  @override
  String scorecardPlaysLike(String distance) {
    return 'JUEGA COMO $distance YDS';
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
  String get scorecardDouble => 'Doble';

  @override
  String scorecardEditHole(int hole) {
    return 'Editar hoyo $hole';
  }

  @override
  String scorecardErrorSaving(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get scorecardOn => 'SÍ';

  @override
  String get scorecardOff => 'NO';

  @override
  String get statsHub => 'Tu centro de estadísticas';

  @override
  String get statsPlayMoreRounds =>
      'Juega más rondas para desbloquear gráficos de tendencias, golpes ganados y análisis de distribución de puntuación.';

  @override
  String get statsHandicapIndex => 'Índice de hándicap';

  @override
  String statsBasedOnRounds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Basado en $n rondas',
      one: 'Basado en 1 ronda',
    );
    return '$_temp0';
  }

  @override
  String get statsCompleteToCalculate => 'Completa rondas para calcular';

  @override
  String get statsAvgScore => 'Puntuación prom.';

  @override
  String get statsBestRound => 'Mejor ronda';

  @override
  String get statsTotalRounds => 'Total de rondas';

  @override
  String get statsTotalBirdies => 'Total de birdies';

  @override
  String get statsScoreDistribution => 'Distribución de puntuación';

  @override
  String get statsEagles => 'Eagles';

  @override
  String get statsBirdies => 'Birdies';

  @override
  String get statsPars => 'Pares';

  @override
  String get statsBogeys => 'Bogeys';

  @override
  String get statsDoublePlus => 'Doble+';

  @override
  String statsScoreVsPar(int n) {
    return 'Puntuación vs Par (Últimas $n rondas)';
  }

  @override
  String get statsOldestToRecent => 'Más antiguo → Más reciente';

  @override
  String get statsHandicapTrend => 'Tendencia de hándicap';

  @override
  String statsGoal(String n) {
    return 'Objetivo: $n';
  }

  @override
  String statsLatest(String n) {
    return 'Último: $n';
  }

  @override
  String get statsFairwaysHit => 'Calles acertadas';

  @override
  String get statsGIR => 'Greens en regulación';

  @override
  String get statsAvgPuttsPerHole => 'Putts prom. / Hoyo';

  @override
  String get statsClubStats => 'Estadísticas de palos';

  @override
  String get statsClubStatsSubtitle =>
      'Puntuación vs par y putts prom. por palo';

  @override
  String get statsClub => 'Palo';

  @override
  String get statsHoles => 'Hoyos';

  @override
  String get statsAvgPlusMinus => 'Prom. ±Par';

  @override
  String get statsAvgPutts => 'Putts prom.';

  @override
  String get statsStrokesGained => 'Golpes ganados';

  @override
  String get statsVsScratch => 'vs referencia de golfista scratch';

  @override
  String get statsOffTheTee => 'Desde el tee';

  @override
  String get statsApproach => 'Aproximación';

  @override
  String get statsAroundGreen => 'Alrededor del green';

  @override
  String get statsPutting => 'Putting';

  @override
  String get statsBetterThanAvg => 'Mejor que\nel promedio';

  @override
  String get statsPressureScore => 'Puntuación de Presión';

  @override
  String get statsPressureResilience => 'Resiliencia';

  @override
  String statsPressureUnlockHint(int count) {
    return 'Juega $count ronda(s) más para desbloquear tu perfil mental';
  }

  @override
  String get statsPressureOpeningHole => 'Hoyo Inicial';

  @override
  String get statsPressureBirdieHangover => 'Resaca del Birdie';

  @override
  String get statsPressureBackNine => 'Caída en el 10-18';

  @override
  String get statsPressureFinishingStretch => 'Tramo Final';

  @override
  String get statsPressureThreePutt => 'Three-Putt en Presión';

  @override
  String get statsPressureTopDrill => 'Ejercicio Clave';

  @override
  String get statsPressureInsufficientData => 'Datos insuficientes';

  @override
  String get tournamentNoTournaments => 'Sin torneos aún';

  @override
  String get tournamentCreateInstructions =>
      'Toca \"Nuevo torneo\" para crear uno,\nluego empieza rondas para puntuar en el torneo.';

  @override
  String get tournamentNew => 'Nuevo torneo';

  @override
  String get tournamentStartInstructions =>
      'Crea un torneo primero, luego usa el ＋ FAB en la pantalla de inicio para empezar una ronda de torneo.';

  @override
  String get tournamentDeleteTitle => '¿Eliminar torneo?';

  @override
  String tournamentDeleteConfirm(String name) {
    return '¿Eliminar \"$name\"? Las rondas en sí no serán eliminadas.';
  }

  @override
  String get tournamentRoundByRound => 'Ronda por ronda';

  @override
  String get tournamentVsPar => 'vs Par';

  @override
  String get tournamentRoundsLabel => 'Rondas';

  @override
  String get tournamentNameLabel => 'Nombre del torneo';

  @override
  String get tournamentNameHint => 'p.ej. Campeonato del club 2026';

  @override
  String get tournamentCreate => 'Crear torneo';

  @override
  String tournamentRoundsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rondas',
      one: '1 ronda',
    );
    return '$_temp0';
  }

  @override
  String get tournamentRunning => 'en curso';

  @override
  String get practiceNoSessions => 'Sin sesiones de práctica aún';

  @override
  String get practiceStartInstructions =>
      'Empieza una ronda para puntuar hoyos,\no registra sesiones de campo de prácticas y juego corto.';

  @override
  String get practiceLogSession => 'Registrar sesión';

  @override
  String get practiceScoredRound => 'Ronda puntuada';

  @override
  String get practiceDeleteTitle => '¿Eliminar sesión?';

  @override
  String get practiceDeleteConfirm =>
      'Esta sesión de práctica será eliminada permanentemente.';

  @override
  String get practiceLogTitle => 'Registrar sesión de práctica';

  @override
  String get practiceType => 'Tipo';

  @override
  String get practiceBallsHit => 'Pelotas golpeadas';

  @override
  String get practiceDuration => 'Duración (min)';

  @override
  String get practiceNotes => 'Notas (opcional)';

  @override
  String get practiceNotesHint => '¿En qué trabajaste?';

  @override
  String get practiceSave => 'Guardar sesión';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsLeaderboard => 'Marcador';

  @override
  String get friendsNoFriendsYet => 'Sin amigos aún';

  @override
  String get friendsEnterEmail =>
      'Introduce el correo de un amigo arriba para agregarlo';

  @override
  String get friendsSearchHint => 'Buscar por correo electrónico…';

  @override
  String get friendsPendingRequests => 'Solicitudes pendientes';

  @override
  String get friendsWantsToBeF => 'Quiere ser amigo';

  @override
  String get friendsRequestSent => 'Solicitud enviada';

  @override
  String get friendsAcceptRequest => 'Aceptar solicitud';

  @override
  String get friendsAlreadyFriends => 'Ya son amigos';

  @override
  String get friendsAddFriend => 'Agregar amigo';

  @override
  String get friendsNoLeaderboard => 'Sin marcador aún';

  @override
  String get friendsAddToCompare => 'Agrega amigos para comparar puntuaciones';

  @override
  String get friendsHandicap => 'Hándicap';

  @override
  String get friendsAvgScore => 'Puntuación prom.';

  @override
  String get friendsYou => 'Tú';

  @override
  String get notifPrefsTitle => 'Notificaciones inteligentes';

  @override
  String get notifPrefsSubtitle => 'Alertas con IA para tu juego';

  @override
  String get notifPrefsSectionTitle => 'TIPOS DE NOTIFICACIÓN';

  @override
  String get notifPrefsPracticeReminders => 'Recordatorios de práctica';

  @override
  String get notifPrefsPracticeDesc =>
      'Ejercicios adaptados por IA para tus áreas más débiles';

  @override
  String get notifPrefsResumeRound => 'Reanudar ronda';

  @override
  String get notifPrefsResumeDesc =>
      'Avisos para completar rondas que dejaste sin terminar';

  @override
  String get notifPrefsPerformance => 'Análisis de rendimiento';

  @override
  String get notifPrefsPerformanceDesc =>
      'Celebra rachas de mejora y tendencias';

  @override
  String get notifPrefsTeeTime => 'Recordatorios de hora de salida';

  @override
  String get notifPrefsTeeTimeDesc =>
      'Alertas antes de tus próximas horas de salida';

  @override
  String get notifPrefsSaved => 'Preferencias guardadas';

  @override
  String get notifPrefsPersonalised =>
      'Las notificaciones se personalizan en función de tus\nrondas recientes y tendencias de rendimiento.';

  @override
  String get notifPrefsAIDriven => '✨ Alertas impulsadas por IA';

  @override
  String get notifPrefsSmartDesc =>
      'Notificaciones inteligentes\nadaptadas a tu juego de golf';

  @override
  String get notifPrefsExplanation =>
      'TeeStats analiza tus rondas, hábitos de práctica y tendencias de rendimiento para enviarte notificaciones que realmente ayuden a tu juego.';

  @override
  String get notifPrefsSave => 'Guardar preferencias';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSubtitle => 'Hazlo tuyo';

  @override
  String get profileDescription =>
      'Establece tu objetivo de hándicap, elige un avatar y explora tu ADN golfístico y estilo de juego.';

  @override
  String get profileGolfer => 'Golfista';

  @override
  String get profileGolfPlaces => 'Lugares de golf';

  @override
  String get profileEditProfile => 'Editar perfil';

  @override
  String get profileSmartNotifications => 'Notificaciones inteligentes';

  @override
  String get profileAchievementsSection => 'LOGROS';

  @override
  String get profileRounds => 'Rondas';

  @override
  String get profileHandicap => 'Hándicap';

  @override
  String get profileBirdies => 'Birdies';

  @override
  String get profileAccount => 'Cuenta';

  @override
  String get profileSignOut => 'Cerrar sesión';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String profileVersion(String version) {
    return 'TeeStats v$version';
  }

  @override
  String profileCopyright(String year) {
    return '© $year TeeStats. Todos los derechos reservados.';
  }

  @override
  String get profileHandicapGoal => 'Objetivo de hándicap';

  @override
  String get profileHandicapGoalDesc =>
      'Establece un índice de hándicap objetivo para seguirlo en tu gráfico de tendencias.';

  @override
  String profileTargetPrefix(String value) {
    return 'Objetivo: $value';
  }

  @override
  String get profileNotSet => 'Sin definir — toca para establecer';

  @override
  String get profileClear => 'Borrar';

  @override
  String get profileSaveGoal => 'Guardar objetivo';

  @override
  String get profileSignOutTitle => '¿Cerrar sesión?';

  @override
  String get profileSignOutBody =>
      'Serás redirigido a la pantalla de inicio de sesión.';

  @override
  String get profileDeleteTitle => '¿Eliminar cuenta?';

  @override
  String get profileDeleteBody =>
      'Esto eliminará permanentemente tu cuenta y todos tus datos de golf, incluyendo rondas, estadísticas y logros.';

  @override
  String get profileDeleteAreYouSure => '¿Estás absolutamente seguro?';

  @override
  String get profileDeleteRoundsItem =>
      'Todas tus rondas y tarjetas de puntuación';

  @override
  String get profileDeleteStatsItem =>
      'Estadísticas, historial de hándicap y logros';

  @override
  String get profileDeleteProfileItem => 'Tu perfil y preferencias';

  @override
  String get profileDeleteNotificationsItem =>
      'Notificaciones inteligentes y horas de salida';

  @override
  String get profileDeleteCannotUndo => 'Esta acción no se puede deshacer.';

  @override
  String get profileDeleteButton => 'Eliminar mi cuenta';

  @override
  String get profileKeepButton => 'Conservar mi cuenta';

  @override
  String get profileDeletingAccount => 'Eliminando cuenta…';

  @override
  String get profileReauthRequired =>
      'Por favor cierra sesión y vuelve a iniciar sesión antes de eliminar tu cuenta.';

  @override
  String get profileSomethingWrong =>
      'Algo salió mal. Por favor inténtalo de nuevo.';

  @override
  String get profileContinue => 'Continuar';

  @override
  String get profileDisplayName => 'Nombre de usuario';

  @override
  String get profileSaveChanges => 'Guardar cambios';

  @override
  String get profileChooseAvatar => 'Elegir avatar';

  @override
  String get profileSelectPresetAvatar => 'Selecciona un avatar predefinido';

  @override
  String get profileRemoveAvatar => 'Eliminar avatar';

  @override
  String get profileSaveAvatar => 'Guardar avatar';

  @override
  String get shotTrackerTapToMark => 'Toca el mapa para marcar el tee';

  @override
  String get shotTrackerTeeMarked => 'Tee marcado · toca para registrar golpes';

  @override
  String shotTrackerShotsFromTee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count golpes desde el tee',
      one: '1 golpe desde el tee',
    );
    return '$_temp0';
  }

  @override
  String get shotTrackerAcquiringGPS => 'Obteniendo GPS…';

  @override
  String shotTrackerDistToPin(String distance) {
    return '$distance yds al pin';
  }

  @override
  String shotTrackerLastShot(String distance) {
    return 'Último golpe: $distance yds';
  }

  @override
  String get shotTrackerUndo => 'Deshacer';

  @override
  String get shotTrackerFinishHole => 'Terminar hoyo';

  @override
  String shotTrackerFinishHoleWithCount(int count) {
    return 'Terminar hoyo  ($count golpes)';
  }

  @override
  String get shotTrackerNiceApproach => '¡Buena aproximación!';

  @override
  String shotTrackerOnGreen(String shotCount, int holeNumber) {
    return 'Estás en el green — $shotCount¿Listo para registrar los putts del hoyo $holeNumber?';
  }

  @override
  String get shotTrackerNotYet => 'Aún no';

  @override
  String shotTrackerLogPutts(int holeNumber) {
    return 'Registrar putts del hoyo $holeNumber';
  }

  @override
  String get swingAnalyzerTitle => 'Analizador de swing';

  @override
  String get swingAnalyzerSaveToGallery => 'Guardar en galería';

  @override
  String get swingAnalyzerShare => 'Compartir';

  @override
  String get swingAnalyzerLoadingVideo => 'Cargando video…';

  @override
  String get swingAnalyzerUploading => 'Subiendo video…';

  @override
  String get swingAnalyzerAnalyzing => 'Analizando trayectoria de la pelota…';

  @override
  String get swingAnalyzerPreviewUnavailable =>
      'Vista previa no disponible — toca donde está la pelota';

  @override
  String get swingAnalyzerTapBall => 'Toca la pelota de golf';

  @override
  String get swingAnalyzerReposition => 'Toca para reposicionar';

  @override
  String get swingAnalyzerSkip => 'Omitir';

  @override
  String get swingAnalyzerAnalyze => 'Analizar';

  @override
  String get swingAnalyzerAITracerTitle => 'Trazador de swing con IA';

  @override
  String get swingAnalyzerAITracerDesc =>
      'Graba o sube un video de tu swing.\nGemini AI rastreará la pelota y superpondrá un trazador en vivo.';

  @override
  String get swingAnalyzerButton => 'Analizar swing';

  @override
  String get swingAnalyzerComingSoon => 'Próximamente';

  @override
  String get swingAnalyzerComingSoonMsg =>
      'El Trazador de swing con IA está actualmente en desarrollo. ¡Espera la actualización!';

  @override
  String get swingAnalyzerGotIt => 'Entendido';

  @override
  String get swingAnalyzerFailed => 'Análisis fallido';

  @override
  String get swingAnalyzerFailedMsg =>
      'Algo salió mal. Por favor inténtalo de nuevo.';

  @override
  String get swingAnalyzerTryAgain => 'Intentar de nuevo';

  @override
  String get swingAnalyzerRecording => 'REC';

  @override
  String get swingAnalyzerBallNotDetected => 'Pelota no detectada en el video';

  @override
  String get swingAnalyzerNoVideoFile => 'No hay archivo de video para guardar';

  @override
  String get swingAnalyzerVideoSaved => 'Video guardado en la galería';

  @override
  String swingAnalyzerCouldNotSave(String error) {
    return 'No se pudo guardar el video: $error';
  }

  @override
  String get swingAnalyzerShareText =>
      '¡Mira el trazado de mi swing en TeeStats! 🏌️';

  @override
  String get swingAnalyzerShotAnalysis => 'Análisis del golpe';

  @override
  String get swingAnalyzerCarry => 'Carry';

  @override
  String get swingAnalyzerHeight => 'Altura';

  @override
  String get swingAnalyzerLaunch => 'Lanzamiento';

  @override
  String get swingAnalyzerPathNotDetected =>
      'Trayectoria de la pelota no detectada. Prueba con mejor iluminación o un ángulo más cercano.';

  @override
  String get swingAnalyzerAnotherSwing => 'Analizar otro swing';

  @override
  String get scorecardUploadTitle => 'Escanear tu tarjeta de puntuación';

  @override
  String get scorecardUploadDesc =>
      'La IA extraerá los datos hoyo por hoyo, incluyendo par, yardaje y hándicap.';

  @override
  String get scorecardUploadChooseSource => 'ELEGIR FUENTE';

  @override
  String get scorecardUploadTakePhoto => 'Tomar foto';

  @override
  String get scorecardUploadFromGallery => 'Elegir de la galería';

  @override
  String get scorecardUploadAnalyzing => 'Analizando tarjeta de puntuación…';

  @override
  String get scorecardUploadAnalyzingNote => 'Esto suele tardar unos segundos';

  @override
  String get scorecardUploadReviewTitle => 'Revisar tarjeta de puntuación';

  @override
  String get scorecardUploadUploadTitle => 'Subir tarjeta de puntuación';

  @override
  String get scorecardUploadCourseName => 'NOMBRE DEL CAMPO';

  @override
  String get scorecardUploadCourseNameHint => 'Introduce el nombre del campo';

  @override
  String get scorecardUploadCityState => 'Ciudad, Estado';

  @override
  String get scorecardUploadSelectTee => 'SELECCIONAR TEE';

  @override
  String get scorecardUploadRetake => 'Volver a tomar';

  @override
  String get scorecardUploadSaveUse => 'Guardar y usar';

  @override
  String get scorecardUploadNoTeeData =>
      'No se extrajeron datos de tee. Prueba con una foto más clara.';

  @override
  String scorecardUploadFailed(String error) {
    return 'Extracción fallida. Prueba con una foto más clara.\n$error';
  }

  @override
  String get scorecardUploadRating => 'Rating';

  @override
  String get scorecardUploadSlope => 'Slope';

  @override
  String get scorecardUploadHoleHeader => 'HOYO';

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
  String get scorecardUploadValidation =>
      'Por favor introduce el nombre del campo.';

  @override
  String get scorecardUploadMissingScores => 'Faltan algunas puntuaciones';

  @override
  String get scorecardUploadMissingMsg =>
      'Algunos hoyos aún muestran 0. Se guardarán como 0 golpes — puedes editarlos después de importar.';

  @override
  String get scorecardUploadImportAnyway => 'Importar de todas formas';

  @override
  String get scorecardUploadFixFirst => 'Corregir primero';

  @override
  String get scorecardImportCourse => 'Campo';

  @override
  String get scorecardImportCourseNameHint => 'Nombre del campo';

  @override
  String get scorecardImportLocationHint => 'Ubicación — busca un campo arriba';

  @override
  String get scorecardImportNoCoursesFound =>
      'No se encontraron campos de golf';

  @override
  String get scorecardImportButton => 'Importar';

  @override
  String get scorecardImportConditions => 'Condiciones de la ronda';

  @override
  String get scorecardImportAvgTemp => 'Temp. prom.';

  @override
  String get scorecardImportAvgWind => 'Viento prom.';

  @override
  String get scorecardImportConditionsLabel => 'Condiciones';

  @override
  String get scorecardImportWeatherUnavailable => 'Tiempo no disponible';

  @override
  String get scorecardImportToday => 'Hoy';

  @override
  String get scorecardImportHowToAdd =>
      '¿Cómo quieres agregar tu tarjeta de puntuación?';

  @override
  String get scorecardImportTakePhoto => 'Tomar una foto';

  @override
  String get scorecardImportPhotoDesc =>
      'Fotografía tu tarjeta de puntuación en papel';

  @override
  String get scorecardImportFromLibrary => 'Elegir de la biblioteca';

  @override
  String get scorecardImportLibraryDesc => 'Selecciona una foto existente';

  @override
  String get scorecardImportReading => 'Leyendo tu tarjeta de puntuación…';

  @override
  String get scorecardImportAnalyzing =>
      'Analizando con IA — esto tarda unos segundos';

  @override
  String get scorecardImportUnableRead =>
      'No se puede leer la tarjeta de puntuación';

  @override
  String get scorecardImportConnectionError =>
      'No se pudo conectar al servicio de IA. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get notifPersonalBestTitle => '🏆 ¡Nuevo récord personal!';

  @override
  String notifPersonalBestMsg(String score) {
    return 'Puntuaste $score — tu mejor ronda hasta ahora. ¡Sigue así!';
  }

  @override
  String get notifTeeTime1HourTitle => '⛳ ¡Hora de salida en 1 hora!';

  @override
  String notifTeeTime1HourMsg(String courseName) {
    return 'Prepárate para tu ronda en $courseName.';
  }

  @override
  String get notifTeeTime15MinTitle => '⛳ ¡Hora de salida en 15 minutos!';

  @override
  String notifTeeTime15MinMsg(String courseName) {
    return 'Dirígete al primer tee en $courseName.';
  }

  @override
  String get notifStreakTitle => '⛳ ¡Es hora de salir al campo!';

  @override
  String get notifStreakMsg =>
      'Ha pasado un tiempo desde tu última ronda. ¡Sal a jugar!';

  @override
  String get noNotificationsTitle => 'Sin notificaciones aún';

  @override
  String get noNotificationsDesc =>
      'Juega más rondas para desbloquear\nalertas personalizadas con IA';

  @override
  String get widgetLeaderboardTitle => 'Marcador en vivo';

  @override
  String get widgetLeaderboardUpdates => 'Se actualiza después de cada hoyo';

  @override
  String get widgetLeaderboardPos => 'POS';

  @override
  String get widgetLeaderboardPlayer => 'JUGADOR';

  @override
  String get widgetLeaderboardThru => 'HASTA';

  @override
  String get widgetLeaderboardScore => 'PUNTUACIÓN';

  @override
  String widgetLeaderboardThruHoles(String holes) {
    return 'Hasta $holes';
  }

  @override
  String get widgetLeaderboardTeeOff => 'Salida';

  @override
  String get widgetLeaderboardFinished => 'F';

  @override
  String get widgetLeaderboardInvited => 'Invitado';

  @override
  String get widgetLeaderboardDeclined => 'Rechazado';

  @override
  String get widgetUnfinishedRound => 'Ronda sin terminar';

  @override
  String widgetHolesPlayed(int played, int total) {
    return '$played / $total hoyos jugados';
  }

  @override
  String get widgetResumeRound => 'Reanudar ronda';

  @override
  String get widgetDiscardTitle => '¿Descartar ronda?';

  @override
  String widgetDiscardMsg(String courseName) {
    return 'Todo el progreso en \"$courseName\" se perderá permanentemente.';
  }

  @override
  String get widgetKeep => 'Conservar';

  @override
  String get widgetDiscard => 'Descartar';

  @override
  String get widgetClubsHint =>
      'Toca los palos de abajo para registrar cada golpe';

  @override
  String widgetClubsSelected(int count, int max) {
    return '$count de $max palos seleccionados';
  }

  @override
  String get widgetGolfDNA => 'ADN GOLFÍSTICO';

  @override
  String get widgetProAnalysis => 'ANÁLISIS PRO';

  @override
  String get widgetPower => 'Potencia';

  @override
  String get widgetAccuracy => 'Precisión';

  @override
  String get widgetPutting => 'Putting';

  @override
  String get widgetStrengthsWeaknesses => 'Fortalezas y debilidades';

  @override
  String get widgetPerformanceTrends => 'Tendencias de rendimiento';

  @override
  String get widgetTraitAnalysis => 'Análisis de características';

  @override
  String get widgetDrivingPower => 'Potencia de drive';

  @override
  String get widgetConsistency => 'Consistencia';

  @override
  String get widgetRiskLevel => 'Nivel de riesgo';

  @override
  String get widgetStamina => 'Resistencia';

  @override
  String get widgetAIRoundSummary => 'Resumen de ronda con IA';

  @override
  String get widgetAnalyzingRound => 'Analizando tu ronda…';

  @override
  String get widgetGemini => 'Gemini';

  @override
  String get widgetStrength => 'Fortaleza';

  @override
  String get widgetWeakness => 'Debilidad';

  @override
  String get widgetFocusArea => 'Área de enfoque';

  @override
  String get widgetPlayStyle => 'ESTILO DE JUEGO';

  @override
  String get widgetAIPowered => 'Con IA';

  @override
  String widgetUpdated(String date) {
    return 'Actualizado $date';
  }

  @override
  String get widgetUpdatedToday => 'hoy';

  @override
  String get widgetUpdatedYesterday => 'ayer';

  @override
  String widgetUpdatedDaysAgo(int days) {
    return 'hace ${days}d';
  }

  @override
  String get timeJustNow => 'ahora mismo';

  @override
  String timeMinutesAgo(int minutes) {
    return 'hace ${minutes}m';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'hace ${hours}h';
  }

  @override
  String timeDaysAgo(int days) {
    return 'hace ${days}d';
  }
}
