import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isTamil => _locale.languageCode == 'ta';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    notifyListeners();
  }

  String translate(String key) {
    if (isTamil) {
      return _tamilStrings[key] ?? _englishStrings[key] ?? key;
    }
    return _englishStrings[key] ?? key;
  }

  static const Map<String, String> _englishStrings = {
    'app_name': 'Urban Serve',
    'welcome_guest': 'Welcome Guest',
    'hey': 'Hey, ',
    'search_hint': 'Search services, plumbing, cleaning...',
    'detecting_location': 'Detecting location...',
    'gold_flash_sale': 'FLASH SALE',
    'gold_price_sub': '₹1 for 3 months',
    'renew_gold': 'Renew Gold now',
    'explore': 'Explore',
    'offers': 'OFFERS',
    
    // Categories
    'cat_all': 'All',
    'cat_cleaning': 'Cleaning',
    'cat_plumbing': 'Plumbing',
    'cat_electrical': 'Electrical',
    'cat_ac_service': 'AC Service',
    'cat_painting': 'Painting',
    'cat_carpentry': 'Carpentry',
    'cat_pest_control': 'Pest Control',

    // Filters
    'filters': 'Filters',
    'near_fast': 'Near & Fast',
    'top_rated': 'Top Rated',
    'price_low': 'Price ↑',
    
    // Booking Form
    'book_service': 'Book Service',
    'service_address': 'Service Address',
    'address_hint': 'Enter your full address',
    'address_required': 'Address is required',
    'preferred_date_time': 'Preferred Date & Time (optional)',
    'tap_to_select': 'Tap to select',
    'notes_optional': 'Notes (optional)',
    'notes_hint': 'Any special instructions...',
    'confirm_booking': 'Confirm Booking',
    'booking_placed': 'Booking placed! Proceeding to payment...',
    'booking_failed': 'Booking failed',
    'selected_pro': 'Selected Professional',

    // Bookings
    'my_bookings': 'My Bookings',
    'guest_mode': 'Guest Mode Active',
    'login_prompt': 'Log in to view your booked appointments and track service history.',
    'login_register': 'Log In / Register',
    'cancel_booking_title': 'Cancel Booking',
    'cancel_booking_confirm': 'Are you sure you want to cancel this booking?',
    'no': 'No',
    'yes_cancel': 'Yes, Cancel',
    'booking_cancelled': 'Booking cancelled',
    'failed_to_cancel': 'Failed to cancel booking',
    'rebook': 'Re-book',
    
    // Booking Status
    'status_pending': 'Pending',
    'status_confirmed': 'Confirmed',
    'status_completed': 'Completed',
    'status_cancelled': 'Cancelled',
    'status_in_progress': 'In Progress',

    // Menu / Profile
    'menu': 'Menu',
    'guest_user': 'Guest User',
    'sign_in_access': 'Sign in to access options',
    'account_settings': 'Account Settings',
    'edit_profile': 'Edit Profile',
    'manage_details': 'Manage your personal details',
    'general': 'General',
    'about_app': 'About App',
    'version_info': 'Version info and details',
    'help_support': 'Help & Support',
    'contact_us': 'Contact us for help',
    'logout': 'Logout',
    'logout_confirm': 'Are you sure you want to logout?',
    'cancel': 'Cancel',
    'language': 'Language / மொழி',
    'select_language': 'Select Language',
    'english': 'English',
    'tamil': 'தமிழ்',
    
    // Help Centre
    'help_centre': 'Help Centre',
    'faq_title': 'Frequently Asked Questions',
    'contact_support': 'Contact Support',
    'call_us': 'Call Us',
    'email_us': 'Email Us',
    'chat_whatsapp': 'Chat on WhatsApp',
    'faq_1_q': 'How do I book a service?',
    'faq_1_a': 'Select a service from the home screen, choose a subcategory, select a professional (optional), set date and time, enter your address, and pay via Razorpay.',
    'faq_2_q': 'Can I cancel a booking?',
    'faq_2_a': 'Yes, bookings can be cancelled anytime before the service starts. Go to "My Bookings" and tap "Cancel Booking".',
    'faq_3_q': 'How do I pay for services?',
    'faq_3_a': 'You can pay online securely using Razorpay, which supports UPI, Cards, Netbanking, and Wallets.',
    'faq_4_q': 'What is the Gold Membership?',
    'faq_4_a': 'Gold membership gives you access to premium professionals, zero platform fees, and exclusive discounts.',
  };

  static const Map<String, String> _tamilStrings = {
    'app_name': 'அர்பன் சர்வ்',
    'welcome_guest': 'வருக விருந்தினரே',
    'hey': 'வணக்கம், ',
    'search_hint': 'சேவைகள், குழாய் வேலைகள், கிளீனிங் தேடவும்...',
    'detecting_location': 'இருப்பிடத்தைக் கண்டறிகிறது...',
    'gold_flash_sale': 'மின்னல் விற்பனை',
    'gold_price_sub': '₹1 க்கு 3 மாதங்கள்',
    'renew_gold': 'கோல்ட் மெம்பர்ஷிப் புதுப்பிக்கவும்',
    'explore': 'கண்டறியுங்கள்',
    'offers': 'சலுகைகள்',
    
    // Categories
    'cat_all': 'அனைத்தும்',
    'cat_cleaning': 'சுத்தம் செய்தல்',
    'cat_plumbing': 'குழாய் வேலை',
    'cat_electrical': 'மின்சாரம்',
    'cat_ac_service': 'ஏசி சேவை',
    'cat_painting': 'வண்ணம் பூசுதல்',
    'cat_carpentry': 'தச்சு வேலை',
    'cat_pest_control': 'பூச்சி கட்டுப்பாடு',

    // Filters
    'filters': 'வடிகட்டிகள்',
    'near_fast': 'அருகில் & விரைவாக',
    'top_rated': 'சிறந்த மதிப்பீடு',
    'price_low': 'விலை ↑',
    
    // Booking Form
    'book_service': 'சேவை முன்பதிவு',
    'service_address': 'சேவை முகவரி',
    'address_hint': 'உங்கள் முழு முகவரியை உள்ளிடவும்',
    'address_required': 'முகவரி தேவை',
    'preferred_date_time': 'விரும்பிய தேதி & நேரம் (விரும்பினால்)',
    'tap_to_select': 'தேர்வு செய்ய தட்டவும்',
    'notes_optional': 'குறிப்புகள் (விரும்பினால்)',
    'notes_hint': 'ஏதேனும் சிறப்பு வழிமுறைகள்...',
    'confirm_booking': 'முன்பதிவை உறுதி செய்',
    'booking_placed': 'முன்பதிவு செய்யப்பட்டது! கட்டணப் பக்கத்திற்குச் செல்கிறது...',
    'booking_failed': 'முன்பதிவு தோல்வியடைந்தது',
    'selected_pro': 'தேர்ந்தெடுக்கப்பட்ட வல்லுநர்',

    // Bookings
    'my_bookings': 'எனது முன்பதிவுகள்',
    'guest_mode': 'விருந்தினர் பயன்முறை',
    'login_prompt': 'உங்கள் முன்பதிவுகளைக் காண மற்றும் சேவை வரலாற்றைக் கண்காணிக்க உள்நுழையவும்.',
    'login_register': 'உள்நுழைக / பதிவு செய்க',
    'cancel_booking_title': 'முன்பதிவு ரத்து',
    'cancel_booking_confirm': 'இந்த முன்பதிவை ரத்து செய்ய விரும்புகிறீர்களா?',
    'no': 'இல்லை',
    'yes_cancel': 'ஆம், ரத்து செய்',
    'booking_cancelled': 'முன்பதிவு ரத்து செய்யப்பட்டது',
    'failed_to_cancel': 'ரத்து செய்ய முடியவில்லை',
    'rebook': 'மீண்டும் முன்பதிவு',
    
    // Booking Status
    'status_pending': 'நிலுவையில்',
    'status_confirmed': 'உறுதி செய்யப்பட்டது',
    'status_completed': 'முடிந்தது',
    'status_cancelled': 'ரத்து செய்யப்பட்டது',
    'status_in_progress': 'செயலில் உள்ளது',

    // Menu / Profile
    'menu': 'பட்டி',
    'guest_user': 'விருந்தினர்',
    'sign_in_access': 'மெனுவை அணுக உள்நுழையவும்',
    'account_settings': 'கணக்கு அமைப்புகள்',
    'edit_profile': 'சுயவிவரம் திருத்து',
    'manage_details': 'உங்கள் தனிப்பட்ட விவரங்களை நிர்வகிக்கவும்',
    'general': 'பொதுவானவை',
    'about_app': 'செயலி பற்றி',
    'version_info': 'பதிப்பு விவரங்கள்',
    'help_support': 'உதவி & ஆதரவு',
    'contact_us': 'உதவிக்கு எங்களை தொடர்பு கொள்ளவும்',
    'logout': 'வெளியேறு',
    'logout_confirm': 'நிச்சயமாக வெளியேற விரும்புகிறீர்களா?',
    'cancel': 'ரத்து செய்',
    'language': 'Language / மொழி',
    'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
    'english': 'English',
    'tamil': 'தமிழ்',

    // Help Centre
    'help_centre': 'உதவி மையம்',
    'faq_title': 'அடிக்கடி கேட்கப்படும் கேள்விகள்',
    'contact_support': 'ஆதரவை தொடர்பு கொள்ளவும்',
    'call_us': 'அழைக்க',
    'email_us': 'மின்னஞ்சல் செய்ய',
    'chat_whatsapp': 'வாட்ஸ்அப்பில் பேச',
    'faq_1_q': 'ஒரு சேவையை எவ்வாறு முன்பதிவு செய்வது?',
    'faq_1_a': 'முகப்புத் திரையில் இருந்து ஒரு சேவையைத் தேர்ந்தெடுத்து, துணைப்பிரிவைத் தேர்ந்தெடுத்து, வல்லுநரைத் தேர்வுசெய்து (விரும்பினால்), தேதி மற்றும் நேரத்தை அமைத்து, உங்கள் முகவரியை உள்ளிட்டு, ரேஸர்பே மூலம் பணம் செலுத்துங்கள்.',
    'faq_2_q': 'முன்பதிவை ரத்து செய்ய முடியுமா?',
    'faq_2_a': 'ஆம், சேவை தொடங்கும் முன் எப்போது வேண்டுமானாலும் முன்பதிவை ரத்து செய்யலாம். "எனது முன்பதிவுகள்" சென்று "முன்பதிவை ரத்து செய்" என்பதைத் தட்டவும்.',
    'faq_3_q': 'சேவைகளுக்கு எவ்வாறு பணம் செலுத்துவது?',
    'faq_3_a': 'யுபிஐ, கார்டுகள், நெட்பேங்கிங் மற்றும் வாலெட்டுகளை ஆதரிக்கும் ரேஸர்பே மூலம் ஆன்லைனில் பாதுகாப்பாகப் பணம் செலுத்தலாம்.',
    'faq_4_q': 'கோல்ட் மெம்பர்ஷிப் என்றால் என்ன?',
    'faq_4_a': 'கோல்ட் மெம்பர்ஷிப் உங்களுக்கு பிரீமியம் வல்லுநர்களுக்கான அணுகல், பூஜ்ஜிய பிளாட்பார்ம் கட்டணம் மற்றும் பிரத்யேக தள்ளுபடிகளை வழங்குகிறது.',
  };
}

extension TranslationExtension on BuildContext {
  String translate(String key) {
    try {
      return Provider.of<LanguageProvider>(this).translate(key);
    } catch (_) {
      return key;
    }
  }
}
