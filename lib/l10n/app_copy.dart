import '../models/ux_prefs.dart';

abstract final class AppCopy {
  static const _en = {
    'home': 'Home',
    'map': 'Map',
    'community': 'Community',
    'appointments': 'Appointments',
    'profile': 'Profile',
    'morning': 'Good Morning',
    'afternoon': 'Good Afternoon',
    'evening': 'Good Evening',
    'help': 'How can we help you today?',
    'helpSimple': 'What do you want to do?',
    'askAi': 'Ask AI Assistant',
    'askAiSimple': 'Ask for help',
    'searchHint': 'Search for places, services, doctors...',
    'searchHintSimple': 'Search places or help',
    'tagline': 'Empowering Abilities. Connecting Lives.',
    'captionsOn': 'Captions on. Spoken words will show here.',
    'captionsSession': 'Live captions',
    'menu': 'Open menu',
    'notifications': 'Notifications',
    'openProfile': 'Open profile',
    'accessSettings': 'Access & language',
    'accessSubtitle':
        'Text size, contrast, captions, simple language, and app language.',
    'accessSubtitleSimple': 'Make the app easier to see, hear, and read.',
    'wcagTitle': 'Access checklist',
    'seeded': 'Your Passport access settings are on for this device.',
  };

  static const _fr = {
    'home': 'Accueil',
    'map': 'Carte',
    'community': 'Communauté',
    'appointments': 'Rendez-vous',
    'profile': 'Profil',
    'morning': 'Bonjour',
    'afternoon': 'Bon après-midi',
    'evening': 'Bonsoir',
    'help': 'Comment pouvons-nous vous aider ?',
    'helpSimple': 'Que voulez-vous faire ?',
    'askAi': 'Demander à l’IA',
    'askAiSimple': 'Demander de l’aide',
    'searchHint': 'Rechercher des lieux, services, médecins...',
    'searchHintSimple': 'Chercher un lieu ou de l’aide',
    'tagline': 'Renforcer les capacités. Relier les vies.',
    'captionsOn': 'Sous-titres activés. Les paroles s’affichent ici.',
    'captionsSession': 'Sous-titres en direct',
    'menu': 'Ouvrir le menu',
    'notifications': 'Notifications',
    'openProfile': 'Ouvrir le profil',
    'accessSettings': 'Accès et langue',
    'accessSubtitle':
        'Taille du texte, contraste, sous-titres, langage simple et langue.',
    'accessSubtitleSimple':
        'Rendre l’app plus facile à voir, entendre et lire.',
    'wcagTitle': 'Liste d’accès',
    'seeded': 'Vos réglages d’accès du Passeport sont actifs.',
  };

  static const _es = {
    'home': 'Inicio',
    'map': 'Mapa',
    'community': 'Comunidad',
    'appointments': 'Citas',
    'profile': 'Perfil',
    'morning': 'Buenos días',
    'afternoon': 'Buenas tardes',
    'evening': 'Buenas noches',
    'help': '¿Cómo podemos ayudarte hoy?',
    'helpSimple': '¿Qué quieres hacer?',
    'askAi': 'Preguntar a la IA',
    'askAiSimple': 'Pedir ayuda',
    'searchHint': 'Buscar lugares, servicios, médicos...',
    'searchHintSimple': 'Buscar lugares o ayuda',
    'tagline': 'Potenciar habilidades. Conectar vidas.',
    'captionsOn': 'Subtítulos activos. El habla aparecerá aquí.',
    'captionsSession': 'Subtítulos en vivo',
    'menu': 'Abrir menú',
    'notifications': 'Notificaciones',
    'openProfile': 'Abrir perfil',
    'accessSettings': 'Acceso e idioma',
    'accessSubtitle':
        'Tamaño de texto, contraste, subtítulos, lenguaje sencillo e idioma.',
    'accessSubtitleSimple': 'Haz la app más fácil de ver, oír y leer.',
    'wcagTitle': 'Lista de acceso',
    'seeded': 'Los ajustes de acceso de tu Pasaporte están activos.',
  };

  static const _ar = {
    'home': 'الرئيسية',
    'map': 'الخريطة',
    'community': 'المجتمع',
    'appointments': 'المواعيد',
    'profile': 'الملف',
    'morning': 'صباح الخير',
    'afternoon': 'مساء الخير',
    'evening': 'مساء الخير',
    'help': 'كيف يمكننا مساعدتك اليوم؟',
    'helpSimple': 'ماذا تريد أن تفعل؟',
    'askAi': 'اسأل المساعد',
    'askAiSimple': 'اطلب مساعدة',
    'searchHint': 'ابحث عن أماكن أو خدمات أو أطباء...',
    'searchHintSimple': 'ابحث عن مكان أو مساعدة',
    'tagline': 'تمكين القدرات. ربط الحياة.',
    'captionsOn': 'الترجمة مفعّلة. سيظهر الكلام هنا.',
    'captionsSession': 'ترجمة مباشرة',
    'menu': 'فتح القائمة',
    'notifications': 'الإشعارات',
    'openProfile': 'فتح الملف',
    'accessSettings': 'الوصول واللغة',
    'accessSubtitle': 'حجم النص والتباين والترجمة واللغة البسيطة ولغة التطبيق.',
    'accessSubtitleSimple': 'اجعل التطبيق أسهل للرؤية والسمع والقراءة.',
    'wcagTitle': 'قائمة الوصول',
    'seeded': 'إعدادات الوصول من جوازك مفعّلة على هذا الجهاز.',
  };

  static Map<String, String> _table(String language) => switch (language) {
    'French' => _fr,
    'Spanish' => _es,
    'Arabic' => _ar,
    _ => _en,
  };

  static String t(UxPrefs prefs, String key) {
    final table = _table(prefs.language);
    final simpleKey = '${key}Simple';
    if (prefs.simpleLanguage && table.containsKey(simpleKey)) {
      return table[simpleKey]!;
    }
    return table[key] ?? _en[key] ?? key;
  }
}
