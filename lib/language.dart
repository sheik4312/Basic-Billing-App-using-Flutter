import 'package:flutter/material.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Inventory Management',
      'item_name': 'Item Name',
      'selling_price': 'Selling Price',
      'buying_price': 'Buying Price',
      'quantity': 'Quantity',
      'unit': 'Unit',
      'mrp': 'MRP',
      'gst_percentage': 'GST Percentage',
      'add_item': 'Add Item',
      'item_added': 'Item added to inventory',
      'edit_item': 'Edit Item',
      'update_item': 'Update Item',
      'price': 'Price',
      'product_code': 'Product Code',
      'selling_price2': 'Selling Price 2',
      'selling_price3': 'Selling Price 3',
      'category': 'Category',
      'add_new_category': 'Add New Category',
      'gst': 'GST',
      'clear_data': 'Clear Data',
      'import_excel': 'Import from Excel',
      'sync_categories': 'Sync Categories',
    },
    'ta': {
      'item_name': 'பொருளின் பெயர்',
      'price': 'விலை',
      'quantity': 'அளவு',
      'buying_price': 'கொள்முதல் விலை',
      'product_code': 'பொருளின் குறியீடு',
      'selling_price2': 'விற்பனை விலை 2',
      'selling_price3': 'விற்பனை விலை 3',
      'category': 'வகை',
      'add_new_category': 'புதிய வகை சேர்க்கவும்',
      'gst': 'வரிச்சோ',
      'unit': 'அலகு',
      'clear_data': 'தகவலை அழிக்கவும்',
      'import_excel': 'எக்செல் இருந்து இறக்கு',
      'sync_categories': 'வகைகளை ஒத்திசைக்கவும்',
      'item_added': 'பொருள் வெற்றிகரமாக சேர்க்கப்பட்டது',
      'app_title': 'சரக்கு மேலாண்மை',
      'selling_price': 'விற்பனை விலை',
      'mrp': 'எம்.ஆர்.பி',
      'gst_percentage': 'ஜி.எஸ்.டி சதவிதம்',
      'add_item': 'பொருள் சேர்க்க',
      'edit_item': 'பொருளை திருத்து',
      'update_item': 'பொருளை புதுப்பிக்கவும்',
    },
  };

  static String locale = 'en'; // Default locale

  static String translate(BuildContext context, String key) {
    return _localizedValues[locale]![key] ?? key;
  }

  static void setLocale(String newLocale) {
    locale = newLocale;
  }
}
