import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkerLanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('worker_language_code') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('worker_language_code', code);
    notifyListeners();
  }

  String translate(String key) {
    final code = _locale.languageCode;
    if (code == 'ta') {
      return _tamilStrings[key] ?? _englishStrings[key] ?? key;
    } else if (code == 'hi') {
      return _hindiStrings[key] ?? _englishStrings[key] ?? key;
    } else if (code == 'ml') {
      return _malayalamStrings[key] ?? _englishStrings[key] ?? key;
    } else if (code == 'kn') {
      return _kannadaStrings[key] ?? _englishStrings[key] ?? key;
    }
    return _englishStrings[key] ?? key;
  }

  static const Map<String, String> _englishStrings = {
    'app_name': 'Technician Partner',
    'dashboard': 'Dashboard',
    'online': 'ONLINE',
    'offline': 'OFFLINE',
    'today_earnings': "Today's Net Payout",
    'jobs_completed': 'Completed Jobs',
    'total_wallet': 'Total Wallet Balance',
    'active_jobs': 'Active & Assigned Jobs',
    'no_active_jobs': 'No active jobs assigned currently.',
    'job_details': 'Job Details',
    'accept_job': 'Accept Job',
    'reject_job': 'Reject Job',
    'start_service': 'Start Service',
    'complete_service': 'Complete Service',
    'earnings_payouts': 'Earnings & Payouts',
    'work_history': 'Work History',
    'profile': 'Profile & KYC',
    'settings': 'Settings',
    'language': 'Language / மொழி',
    'select_language': 'Select Language',
    'english': 'English',
    'tamil': 'தமிழ் (Tamil)',
    'hindi': 'हिन्दी (Hindi)',
    'malayalam': 'മലയാളം (Malayalam)',
    'kannada': 'ಕನ್ನಡ (Kannada)',
    'logout': 'Logout',
    'status_accepted': 'Accepted',
    'status_on_the_way': 'On The Way',
    'status_started': 'Started',
    'status_completed': 'Completed',
    'status_cancelled': 'Cancelled',
    'net_payout': 'Net Payout (90%)',
    'settlement_status': 'Settlement Status',
    'paid': 'PAID',
    'pending': 'PENDING',
  };

  static const Map<String, String> _tamilStrings = {
    'app_name': 'தொழிலாளி பார்ட்னர்',
    'dashboard': 'முகப்பு',
    'online': 'ஆன்லைன்',
    'offline': 'ஆஃப்லைன்',
    'today_earnings': 'இன்றைய நிகர வருமானம்',
    'jobs_completed': 'முடிந்த சேவைகள்',
    'total_wallet': 'மொத்த வாலட் இருப்பு',
    'active_jobs': 'செயலில் உள்ள சேவைகள்',
    'no_active_jobs': 'தற்போது எந்த சேவையும் ஒதுக்கப்படவில்லை.',
    'job_details': 'சேவை விவரங்கள்',
    'accept_job': 'சேவையை ஏற்றுக்கொள்',
    'reject_job': 'சேவையை நிராகரி',
    'start_service': 'சேவையைத் தொடங்கு',
    'complete_service': 'சேவையை முடி',
    'earnings_payouts': 'வருமானம் & செட்டில்மென்ட்',
    'work_history': 'பணி வரலாறு',
    'profile': 'சுயவிவரம் & KYC',
    'settings': 'அமைப்புகள்',
    'language': 'Language / மொழி',
    'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
    'english': 'English',
    'tamil': 'தமிழ் (Tamil)',
    'hindi': 'हिन्दी (Hindi)',
    'malayalam': 'മലയാളം (Malayalam)',
    'kannada': '<ctrl42>ಕನ್ನಡ (Kannada)',
    'logout': 'வெளியேறு',
    'status_accepted': 'ஏற்றுக்கொள்ளப்பட்டது',
    'status_on_the_way': 'சென்று கொண்டிருக்கிறது',
    'status_started': 'தொடங்கப்பட்டது',
    'status_completed': 'முடிந்தது',
    'status_cancelled': 'ரத்து செய்யப்பட்டது',
    'net_payout': 'நிகர ஊதியம் (90%)',
    'settlement_status': 'செட்டில்மென்ட் நிலை',
    'paid': 'செலுத்தப்பட்டது',
    'pending': 'நிலுவையில்',
  };

  static const Map<String, String> _hindiStrings = {
    'app_name': 'तकनीशियन पार्टनर',
    'dashboard': 'डैशबोर्ड',
    'online': 'ऑनलाइन',
    'offline': 'ऑफलाइन',
    'today_earnings': 'आज की शुद्ध कमाई',
    'jobs_completed': 'पूरे किए गए कार्य',
    'total_wallet': 'कुल वॉलेट बैलेंस',
    'active_jobs': 'सक्रिय कार्य',
    'no_active_jobs': 'वर्तमान में कोई कार्य असाइन नहीं है।',
    'job_details': 'कार्य विवरण',
    'accept_job': 'स्वीकार करें',
    'reject_job': 'अस्वीकार करें',
    'start_service': 'सेवा शुरू करें',
    'complete_service': 'सेवा पूरी करें',
    'earnings_payouts': 'कमाई और भुगतान',
    'work_history': 'कार्य इतिहास',
    'profile': 'प्रोफ़ाइल और केवाईसी',
    'settings': 'सेटिंग्स',
    'language': 'भाषा / Language',
    'select_language': 'भाषा चुनें',
    'english': 'English',
    'tamil': 'தமிழ் (Tamil)',
    'hindi': 'हिन्दी (Hindi)',
    'malayalam': 'മലയാളം (Malayalam)',
    'kannada': 'ಕನ್ನಡ (Kannada)',
    'logout': 'लॉग आउट',
    'status_accepted': 'स्वीकृत',
    'status_on_the_way': 'रास्ते में',
    'status_started': 'शुरू हुआ',
    'status_completed': 'पूरा हुआ',
    'status_cancelled': 'रद्द',
    'net_payout': 'शुद्ध भुगतान (90%)',
    'settlement_status': 'भुगतान की स्थिति',
    'paid': 'भुगतान किया गया',
    'pending': 'लंबित',
  };

  static const Map<String, String> _malayalamStrings = {
    'app_name': 'ടെക്നീഷ്യൻ പാർട്ണർ',
    'dashboard': 'ഡാഷ്‌ബോർഡ്',
    'online': 'ഓൺലൈൻ',
    'offline': 'ഓഫ്‌ലൈൻ',
    'today_earnings': 'ഇന്നത്തെ വരുമാനം',
    'jobs_completed': 'പൂർത്തിയാക്കിയ ജോലികൾ',
    'total_wallet': 'വാലറ്റ് ബാലൻസ്',
    'active_jobs': 'നിലവിലെ ജോലികൾ',
    'no_active_jobs': 'നിലവിൽ ജോലികൾ ഒന്നുമില്ല.',
    'job_details': 'ജോലി വിവരങ്ങൾ',
    'accept_job': 'സ്വീകരിക്കുക',
    'reject_job': 'നിരസിക്കുക',
    'start_service': 'ആരംഭിക്കുക',
    'complete_service': 'പൂർത്തിയാക്കുക',
    'earnings_payouts': 'വരുമാനവും പേഔട്ടും',
    'work_history': 'ജോലി ചരിത്രം',
    'profile': 'പ്രൊഫൈൽ & KYC',
    'settings': 'ക്രമീകരണങ്ങൾ',
    'language': 'ഭാഷ / Language',
    'select_language': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
    'english': 'English',
    'tamil': 'தமிழ் (Tamil)',
    'hindi': 'हिन्दी (Hindi)',
    'malayalam': 'മലയാളം (Malayalam)',
    'kannada': 'കന്നഡ (Kannada)',
    'logout': 'ലോഗ് ഔട്ട്',
    'status_accepted': 'സ്വീകരിച്ചു',
    'status_on_the_way': 'വഴിയിലാണ്',
    'status_started': 'ആരംഭിച്ചു',
    'status_completed': 'പൂർത്തിയായി',
    'status_cancelled': 'ക്യാൻസൽ ചെയ്തു',
    'net_payout': 'വരുമാനം (90%)',
    'settlement_status': 'പേഔട്ട് സ്റ്റാറ്റസ്',
    'paid': 'നൽകി',
    'pending': 'പെൻഡിംഗ്',
  };

  static const Map<String, String> _kannadaStrings = {
    'app_name': 'ತಂತ್ರಜ್ಞ ಸಂಗಾತಿ',
    'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
    'online': 'ಆನ್‌ಲೈನ್',
    'offline': 'ಆಫ್‌ಲೈನ್',
    'today_earnings': 'ಇಂದಿನ ಗಳಿಕೆ',
    'jobs_completed': 'ಪೂರ್ಣಗೊಂಡ ಕೆಲಸಗಳು',
    'total_wallet': 'ಒಟ್ಟು ಬ್ಯಾಲೆನ್ಸ್',
    'active_jobs': 'ಸಕ್ರಿಯ ಕೆಲಸಗಳು',
    'no_active_jobs': 'ಪ್ರಸ್ತುತ ಯಾವುದೇ ಕೆಲಸ ನಿಯೋಜಿಸಲಾಗಿಲ್ಲ.',
    'job_details': 'ಕೆಲಸದ ವಿವರಗಳು',
    'accept_job': 'ಒಪ್ಪಿಕೊಳ್ಳಿ',
    'reject_job': 'ತಿರಸ್ಕರಿಸಿ',
    'start_service': 'ಪ್ರಾರಂಭಿಸಿ',
    'complete_service': 'ಪೂರ್ಣಗೊಳಿಸಿ',
    'earnings_payouts': 'ಗಳಿಕೆ ಮತ್ತು ಪಾವತಿ',
    'work_history': 'ಕೆಲಸದ ಇತಿಹಾಸ',
    'profile': 'ಪ್ರೊಫೈಲ್ ಮತ್ತು KYC',
    'settings': 'ಸಂಯೋಜನೆಗಳು',
    'language': 'ಭಾಷೆ / Language',
    'select_language': 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    'english': 'English',
    'tamil': 'தமிழ் (Tamil)',
    'hindi': 'ಹಿन्दी (Hindi)',
    'malayalam': 'മലയാളം (Malayalam)',
    'kannada': 'ಕನ್ನಡ (Kannada)',
    'logout': 'ಲಾಗ್ ಔಟ್',
    'status_accepted': 'ಅಂಗೀಕರಿಸಲಾಗಿದೆ',
    'status_on_the_way': 'ದಾರಿಯಲ್ಲಿದ್ದಾರೆ',
    'status_started': 'ಪ್ರಾರಂಭಿಸಲಾಗಿದೆ',
    'status_completed': 'ಪೂರ್ಣಗೊಂಡಿದೆ',
    'status_cancelled': 'ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ',
    'net_payout': 'ಗಳಿಕೆ (90%)',
    'settlement_status': 'ಪಾವತಿ ಸ್ಥಿತಿ',
    'paid': 'ಪಾವತಿಸಲಾಗಿದೆ',
    'pending': 'ಬಾಕಿ ಇದೆ',
  };
}

extension WorkerTranslationExtension on BuildContext {
  String translate(String key) {
    try {
      return Provider.of<WorkerLanguageProvider>(this).translate(key);
    } catch (_) {
      return key;
    }
  }
}
