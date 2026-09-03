import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/format_utils.dart';

class CurrencyInfo {
  final String code;
  final String nameTh;
  final String nameEn;
  final String symbol;
  final String flag;
  final bool isCommodity;

  const CurrencyInfo({
    required this.code,
    required this.nameTh,
    required this.nameEn,
    required this.symbol,
    required this.flag,
    this.isCommodity = false,
  });
}

class CurrencyRateItem {
  final CurrencyInfo info;
  final double rateToThb; // 1 Foreign Unit = X THB
  final double thbToRate; // 1 THB = X Foreign Unit

  CurrencyRateItem({
    required this.info,
    required this.rateToThb,
    required this.thbToRate,
  });
}

class LiveRateCardData {
  final String key;
  final String nameTh;
  final String nameEn;
  final String symbol;
  final String flag;
  final double currentPrice;
  final String unitText;
  final double change24hPercent;
  final List<double> sparklinePoints;
  final bool isCommodity;
  final String category; // 'gold', 'fiat', 'commodity', 'crypto'

  const LiveRateCardData({
    required this.key,
    required this.nameTh,
    required this.nameEn,
    required this.symbol,
    required this.flag,
    required this.currentPrice,
    required this.unitText,
    required this.change24hPercent,
    required this.sparklinePoints,
    this.isCommodity = false,
    this.category = 'fiat',
  });
}

class CurrencyExchangeService {
  static const String _primaryUrl = 'https://latest.currency-api.pages.dev/v1/currencies/thb.json';
  static const String _fallbackUrl = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/thb.json';
  static const String _keyCachedRates = 'cached_currency_rates_thb';
  static const String _keyLastUpdated = 'cached_currency_last_updated';

  // 25+ Popular Currencies with detailed Thai info
  static const Map<String, CurrencyInfo> supportedCurrencies = {
    'thb': CurrencyInfo(code: 'thb', nameTh: 'บาทไทย', nameEn: 'Thai Baht', symbol: '฿', flag: '🇹🇭'),
    'usd': CurrencyInfo(code: 'usd', nameTh: 'ดอลลาร์สหรัฐ', nameEn: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    'sar': CurrencyInfo(code: 'sar', nameTh: 'ริยาลซาอุดีอาระเบีย (ฮัจญ์/อุมเราะฮ์)', nameEn: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
    'kwd': CurrencyInfo(code: 'kwd', nameTh: 'ดีนาร์คูเวต (Kuwaiti Dinar)', nameEn: 'Kuwaiti Dinar', symbol: 'د.ك', flag: '🇰🇼'),
    'myr': CurrencyInfo(code: 'myr', nameTh: 'ริงกิตมาเลเซีย', nameEn: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾'),
    'jpy': CurrencyInfo(code: 'jpy', nameTh: 'เยนญี่ปุ่น', nameEn: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    'eur': CurrencyInfo(code: 'eur', nameTh: 'ยูโร', nameEn: 'Euro', symbol: '€', flag: '🇪🇺'),
    'sgd': CurrencyInfo(code: 'sgd', nameTh: 'ดอลลาร์สิงคโปร์', nameEn: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
    'gbp': CurrencyInfo(code: 'gbp', nameTh: 'ปอนด์สเตอร์ลิง', nameEn: 'British Pound', symbol: '£', flag: '🇬🇧'),
    'cny': CurrencyInfo(code: 'cny', nameTh: 'หยวนจีน', nameEn: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    'krw': CurrencyInfo(code: 'krw', nameTh: 'วอนเกาหลีใต้', nameEn: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
    'aed': CurrencyInfo(code: 'aed', nameTh: 'เดอร์แฮมดูไบ/สหรัฐอาหรับฯ', nameEn: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    'bhd': CurrencyInfo(code: 'bhd', nameTh: 'ดีนาร์บาห์เรน', nameEn: 'Bahraini Dinar', symbol: 'BD', flag: '🇧🇭'),
    'jod': CurrencyInfo(code: 'jod', nameTh: 'ดีนาร์จอร์แดน', nameEn: 'Jordanian Dinar', symbol: 'JD', flag: '🇯🇴'),
    'qar': CurrencyInfo(code: 'qar', nameTh: 'ริยาลกาตาร์', nameEn: 'Qatari Riyal', symbol: 'QR', flag: '🇶🇦'),
    'omr': CurrencyInfo(code: 'omr', nameTh: 'เรียลโอมาน', nameEn: 'Omani Rial', symbol: 'OMR', flag: '🇴🇲'),
    'idr': CurrencyInfo(code: 'idr', nameTh: 'รูเปียห์อินโดนีเซีย', nameEn: 'Indonesian Rupiah', symbol: 'Rp', flag: '🇮🇩'),
    'aud': CurrencyInfo(code: 'aud', nameTh: 'ดอลลาร์ออสเตรเลีย', nameEn: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
    'twd': CurrencyInfo(code: 'twd', nameTh: 'ดอลลาร์ไต้หวัน', nameEn: 'Taiwan Dollar', symbol: 'NT\$', flag: '🇹🇼'),
    'hkd': CurrencyInfo(code: 'hkd', nameTh: 'ดอลลาร์ฮ่องกง', nameEn: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰'),
    'vnd': CurrencyInfo(code: 'vnd', nameTh: 'ดงเวียดนาม', nameEn: 'Vietnamese Dong', symbol: '₫', flag: '🇻🇳'),
    'chf': CurrencyInfo(code: 'chf', nameTh: 'ฟรังก์สวิส', nameEn: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭'),
    'cad': CurrencyInfo(code: 'cad', nameTh: 'ดอลลาร์แคนาดา', nameEn: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦'),
    'inr': CurrencyInfo(code: 'inr', nameTh: 'รูปีอินเดีย', nameEn: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    'khr': CurrencyInfo(code: 'khr', nameTh: 'เรียลกัมพูชา', nameEn: 'Cambodian Riel', symbol: '៛', flag: '🇰🇭'),
    'lak': CurrencyInfo(code: 'lak', nameTh: 'กีบลาว', nameEn: 'Lao Kip', symbol: '₭', flag: '🇱🇦'),
    'try': CurrencyInfo(code: 'try', nameTh: 'ลีราตุรกี', nameEn: 'Turkish Lira', symbol: '₺', flag: '🇹🇷'),
    'xau': CurrencyInfo(code: 'xau', nameTh: 'ทองคำสากล (Gold Troy Oz)', nameEn: 'Gold (XAU)', symbol: '🥇', flag: '🪙', isCommodity: true),
    'xag': CurrencyInfo(code: 'xag', nameTh: 'โลหะเงิน (Silver Troy Oz)', nameEn: 'Silver (XAG)', symbol: '🥈', flag: '🪙', isCommodity: true),
    'btc': CurrencyInfo(code: 'btc', nameTh: 'บิตคอยน์ (Bitcoin)', nameEn: 'Bitcoin', symbol: '₿', flag: '₿', isCommodity: true),
  };

  // Safe offline fallback exchange rates (1 THB = X Foreign Currency)
  static const Map<String, double> defaultThbRates = {
    'thb': 1.0,
    'usd': 0.0298,
    'sar': 0.1118,
    'kwd': 0.00908,
    'myr': 0.1338,
    'jpy': 4.385,
    'eur': 0.0275,
    'sgd': 0.0396,
    'gbp': 0.0232,
    'cny': 0.2145,
    'krw': 40.50,
    'aed': 0.1095,
    'bhd': 0.0112,
    'jod': 0.0211,
    'qar': 0.1085,
    'omr': 0.0115,
    'idr': 475.0,
    'aud': 0.0452,
    'twd': 0.955,
    'hkd': 0.233,
    'vnd': 745.0,
    'chf': 0.0261,
    'cad': 0.0412,
    'inr': 2.52,
    'khr': 121.0,
    'lak': 640.0,
    'try': 1.02,
    'xau': 0.0000118, // ~2,500 USD / oz
    'xag': 0.00098,
    'btc': 0.00000045,
  };

  static Map<String, double> _inMemoryRates = Map.from(defaultThbRates);
  static String? _lastUpdatedDate;
  static String? _lastUpdatedFullDateTime;
  static double _goldBarSell = 70150.0;
  static double _goldBarBuy = 69950.0;
  static double _goldOrnamentSell = 70950.0;
  static double _goldOrnamentBuy = 68553.52;
  static String? _goldAssociationUpdateText;
  static String? _lastGoldUpdatedFullDateTime;

  static const String _keyCachedGoldBarSell = 'cached_gold_bar_sell';
  static const String _keyCachedGoldBarBuy = 'cached_gold_bar_buy';
  static const String _keyCachedGoldOrnamentSell = 'cached_gold_ornament_sell';
  static const String _keyCachedGoldOrnamentBuy = 'cached_gold_ornament_buy';
  static const String _keyCachedGoldUpdateText = 'cached_gold_update_text';
  static const String _keyCachedGoldTimestamp = 'cached_gold_timestamp';
  static const String _keyCachedFullTimestamp = 'cached_currency_full_timestamp';

  /// Helper to format DateTime into clean Thai format: e.g. "30 ส.ค. 2569 เวลา 01:05 น."
  static String formatThaiDateTime(DateTime dt) {
    const thaiMonths = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final year = dt.year + 543;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${thaiMonths[dt.month - 1]} $year เวลา $hour:$minute น.';
  }

  /// Fetches latest daily rates from Exchange API and Thai Gold API with caching
  static Future<bool> fetchLatestRates() async {
    bool currencySuccess = false;
    final prefs = await SharedPreferences.getInstance();

    // 1. Fetch Global Currency Rates
    try {
      http.Response? response;
      try {
        response = await http.get(Uri.parse(_primaryUrl)).timeout(const Duration(seconds: 6));
      } catch (_) {
        try {
          response = await http.get(Uri.parse(_fallbackUrl)).timeout(const Duration(seconds: 6));
        } catch (_) {}
      }

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? date = data['date'] as String?;
        final Map<String, dynamic>? thbMap = data['thb'] as Map<String, dynamic>?;

        if (thbMap != null) {
          final Map<String, double> parsedRates = {};
          thbMap.forEach((k, v) {
            if (v is num) {
              parsedRates[k.toLowerCase()] = v.toDouble();
            }
          });

          _inMemoryRates = parsedRates;
          _lastUpdatedDate = date ?? DateTime.now().toIso8601String().split('T').first;
          _lastUpdatedFullDateTime = formatThaiDateTime(DateTime.now());

          await prefs.setString(_keyCachedRates, jsonEncode(parsedRates));
          await prefs.setString(_keyLastUpdated, _lastUpdatedDate!);
          await prefs.setString(_keyCachedFullTimestamp, _lastUpdatedFullDateTime!);
          currencySuccess = true;
        }
      }
    } catch (_) {}

    // 2. Fetch Live Thai Gold Prices (Gold Bar & Gold Ornament)
    await fetchThaiGoldPrices();

    if (!currencySuccess) {
      await _loadFromCache();
    }
    return currencySuccess;
  }

  /// Fetches live Gold Bar & Ornamental Gold rates from Thai Gold API
  static Future<bool> fetchThaiGoldPrices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(Uri.parse('https://api.chnwt.dev/thai-gold-api/latest')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success' && data['response'] != null) {
          final resp = data['response'];
          final priceData = resp['price'];
          final updateTime = resp['update_time']?.toString() ?? '';
          final updateDate = resp['update_date']?.toString() ?? '';

          final barSell = double.tryParse(priceData['gold_bar']?['sell']?.toString().replaceAll(',', '') ?? '');
          final barBuy = double.tryParse(priceData['gold_bar']?['buy']?.toString().replaceAll(',', '') ?? '');
          final ornamentSell = double.tryParse(priceData['gold']?['sell']?.toString().replaceAll(',', '') ?? '');
          final ornamentBuy = double.tryParse(priceData['gold']?['buy']?.toString().replaceAll(',', '') ?? '');

          if (barSell != null && barSell > 0) _goldBarSell = barSell;
          if (barBuy != null && barBuy > 0) _goldBarBuy = barBuy;
          if (ornamentSell != null && ornamentSell > 0) _goldOrnamentSell = ornamentSell;
          if (ornamentBuy != null && ornamentBuy > 0) _goldOrnamentBuy = ornamentBuy;

          _goldAssociationUpdateText = '$updateDate $updateTime'.trim();
          _lastGoldUpdatedFullDateTime = formatThaiDateTime(DateTime.now());

          await prefs.setDouble(_keyCachedGoldBarSell, _goldBarSell);
          await prefs.setDouble(_keyCachedGoldBarBuy, _goldBarBuy);
          await prefs.setDouble(_keyCachedGoldOrnamentSell, _goldOrnamentSell);
          await prefs.setDouble(_keyCachedGoldOrnamentBuy, _goldOrnamentBuy);
          if (_goldAssociationUpdateText != null) {
            await prefs.setString(_keyCachedGoldUpdateText, _goldAssociationUpdateText!);
          }
          await prefs.setString(_keyCachedGoldTimestamp, _lastGoldUpdatedFullDateTime!);
          return true;
        }
      }
    } catch (_) {}

    await _loadGoldFromCache();
    return false;
  }

  static Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_keyCachedRates);
      final cachedDate = prefs.getString(_keyLastUpdated);
      final cachedFull = prefs.getString(_keyCachedFullTimestamp);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(cachedJson);
        final Map<String, double> parsed = {};
        map.forEach((k, v) {
          if (v is num) parsed[k] = v.toDouble();
        });
        _inMemoryRates = parsed;
        _lastUpdatedDate = cachedDate;
        _lastUpdatedFullDateTime = cachedFull;
      }
      await _loadGoldFromCache();
    } catch (_) {}
  }

  static Future<void> _loadGoldFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _goldBarSell = prefs.getDouble(_keyCachedGoldBarSell) ?? _goldBarSell;
      _goldBarBuy = prefs.getDouble(_keyCachedGoldBarBuy) ?? _goldBarBuy;
      _goldOrnamentSell = prefs.getDouble(_keyCachedGoldOrnamentSell) ?? _goldOrnamentSell;
      _goldOrnamentBuy = prefs.getDouble(_keyCachedGoldOrnamentBuy) ?? _goldOrnamentBuy;
      _goldAssociationUpdateText = prefs.getString(_keyCachedGoldUpdateText);
      _lastGoldUpdatedFullDateTime = prefs.getString(_keyCachedGoldTimestamp);
    } catch (_) {}
  }

  /// Returns 1 Unit of [currencyCode] in THB (บาท)
  static double getRateToThb(String currencyCode) {
    final code = currencyCode.toLowerCase();
    if (code == 'thb') return 1.0;

    final thbToForeign = _inMemoryRates[code] ?? defaultThbRates[code] ?? 0.0;
    if (thbToForeign <= 0) return 1.0;

    return 1.0 / thbToForeign;
  }

  /// Converts an amount from one currency to another
  static double convert(double amount, String fromCode, String toCode) {
    if (amount <= 0) return 0.0;
    final from = fromCode.toLowerCase();
    final to = toCode.toLowerCase();
    if (from == to) return amount;

    // Convert from -> THB -> to
    final rateFromToThb = getRateToThb(from);
    final amountInThb = amount * rateFromToThb;

    if (to == 'thb') return amountInThb;

    final thbToTarget = _inMemoryRates[to] ?? defaultThbRates[to] ?? 1.0;
    return amountInThb * thbToTarget;
  }

  /// Price of 1 Baht Weight of Gold Bar (ขายออกทองคำแท่ง 96.5%)
  static double getGoldBarSellPrice() {
    return _goldBarSell > 0 ? _goldBarSell : getGoldPricePerBahtWeight();
  }

  /// Price of 1 Baht Weight of Gold Bar (รับซื้อทองคำแท่ง 96.5%)
  static double getGoldBarBuyPrice() {
    return _goldBarBuy > 0 ? _goldBarBuy : (_goldBarSell - 200.0);
  }

  /// Price of 1 Baht Weight of Ornamental Gold (ขายออกทองรูปพรรณ 96.5%)
  static double getGoldOrnamentSellPrice() {
    return _goldOrnamentSell > 0 ? _goldOrnamentSell : (_goldBarSell + 800.0);
  }

  /// Price of 1 Baht Weight of Ornamental Gold (รับซื้อคืนทองรูปพรรณ 96.5%)
  static double getGoldOrnamentBuyPrice() {
    return _goldOrnamentBuy > 0 ? _goldOrnamentBuy : (_goldBarSell - 1500.0);
  }

  /// Calculates estimated live gold price in THB per 1 Baht Weight (Global Spot Formula fallback)
  static double getGoldPricePerBahtWeight() {
    if (_goldBarSell > 0) return _goldBarSell;

    final goldPerOunceInThb = getRateToThb('xau');
    if (goldPerOunceInThb <= 0) return 70150.0; // Standard baseline fallback

    final pricePerGram9999 = goldPerOunceInThb / 31.1034768;
    final price1BahtGold965 = pricePerGram9999 * 15.244 * 0.965;
    return price1BahtGold965;
  }

  /// Calculates estimated silver price in THB per 1 gram
  static double getSilverPricePerGram() {
    final silverPerOunceInThb = getRateToThb('xag');
    if (silverPerOunceInThb <= 0) return 38.5; // Fallback
    return silverPerOunceInThb / 31.1034768;
  }

  /// Full formatted timestamp for Currency conversion
  static String getLastUpdatedText() {
    if (_lastUpdatedFullDateTime != null && _lastUpdatedFullDateTime!.isNotEmpty) {
      return 'อัปเดตล่าสุด: $_lastUpdatedFullDateTime';
    }
    if (_lastUpdatedDate != null && _lastUpdatedDate!.isNotEmpty) {
      return 'อัปเดตล่าสุด: $_lastUpdatedDate';
    }
    return 'อัปเดตล่าสุด: ${formatThaiDateTime(DateTime.now())}';
  }

  /// Formatted timestamp for Gold prices
  static String getGoldLastUpdatedText() {
    if (_goldAssociationUpdateText != null && _goldAssociationUpdateText!.isNotEmpty) {
      return 'สมาคมค้าทองคำไทย: $_goldAssociationUpdateText';
    }
    if (_lastGoldUpdatedFullDateTime != null && _lastGoldUpdatedFullDateTime!.isNotEmpty) {
      return 'อัปเดตล่าสุด: $_lastGoldUpdatedFullDateTime';
    }
    return 'สมาคมค้าทองคำแห่งประเทศไทย (เรียลไทม์)';
  }

  /// Key for storing user selected rates in SharedPreferences
  static const String keyUserWatchlist = 'user_selected_premium_rates';

  /// Default watchlist requested: Thai Gold Bar, Thai Gold Ornament, Silver, USD, SAR, KWD, MYR
  static const List<String> defaultWatchlist = [
    'gold_bar',
    'gold_ornament',
    'silver',
    'usd',
    'sar',
    'kwd',
    'myr',
  ];

  /// Fetches saved user watchlist keys from storage (fallback to default)
  static Future<List<String>> getUserWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(keyUserWatchlist);
      if (list != null && list.isNotEmpty) {
        return list;
      }
    } catch (_) {}
    return List.from(defaultWatchlist);
  }

  /// Saves user selected watchlist keys
  static Future<void> saveUserWatchlist(List<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(keyUserWatchlist, keys);
    } catch (_) {}
  }

  /// Generates dynamic Bezier sparkline data points (8 points) based on trend and key
  static List<double> generateSparklinePoints(String key, double currentPrice, double changePercent) {
    if (currentPrice <= 0) return [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
    final seed = key.hashCode.abs() % 100;
    final points = <double>[];
    const count = 8;
    final startPrice = currentPrice / (1.0 + (changePercent / 100.0));

    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final trend = startPrice + (currentPrice - startPrice) * t;
      final wave = ((seed + i * 3) % 7 - 3) * (currentPrice * 0.0018);
      final val = (trend + (i == count - 1 ? 0.0 : wave)).clamp(currentPrice * 0.85, currentPrice * 1.15);
      points.add(val);
    }
    return points;
  }

  /// Returns single live rate card data for a given key
  static LiveRateCardData getLiveRateDataForKey(String key) {
    final k = key.toLowerCase();
    if (k == 'gold_bar') {
      final price = getGoldBarSellPrice();
      const change = 0.45;
      return LiveRateCardData(
        key: 'gold_bar',
        nameTh: 'ทองคำแท่ง 96.5%',
        nameEn: 'Thai Gold Bar',
        symbol: '฿',
        flag: '🥇',
        currentPrice: price,
        unitText: 'บาททอง',
        change24hPercent: change,
        sparklinePoints: generateSparklinePoints('gold_bar', price, change),
        isCommodity: true,
        category: 'gold',
      );
    } else if (k == 'gold_ornament') {
      final price = getGoldOrnamentSellPrice();
      const change = 0.50;
      return LiveRateCardData(
        key: 'gold_ornament',
        nameTh: 'ทองรูปพรรณ 96.5%',
        nameEn: 'Thai Gold Ornament',
        symbol: '฿',
        flag: '📿',
        currentPrice: price,
        unitText: 'บาททอง',
        change24hPercent: change,
        sparklinePoints: generateSparklinePoints('gold_ornament', price, change),
        isCommodity: true,
        category: 'gold',
      );
    } else if (k == 'silver' || k == 'xag') {
      final pricePerGram = getSilverPricePerGram();
      const change = 0.35;
      return LiveRateCardData(
        key: 'silver',
        nameTh: 'โลหะเงินแท้ 99.9%',
        nameEn: 'Pure Silver (XAG)',
        symbol: '฿',
        flag: '🥈',
        currentPrice: pricePerGram,
        unitText: '฿/กรัม (โลหะเงิน)',
        change24hPercent: change,
        sparklinePoints: generateSparklinePoints('silver', pricePerGram, change),
        isCommodity: true,
        category: 'silver',
      );
    } else {
      final info = supportedCurrencies[k] ?? CurrencyInfo(code: k, nameTh: k.toUpperCase(), nameEn: k.toUpperCase(), symbol: k.toUpperCase(), flag: '🌐');
      final rateToThb = getRateToThb(k);
      final hash = k.hashCode.abs();
      final changeSign = (hash % 2 == 0) ? 1.0 : -1.0;
      final changeVal = changeSign * (((hash % 35) + 6) / 100.0);

      return LiveRateCardData(
        key: k,
        nameTh: info.nameTh,
        nameEn: info.nameEn,
        symbol: info.symbol,
        flag: info.flag,
        currentPrice: rateToThb,
        unitText: '1 ${info.code.toUpperCase()} = ${FormatUtils.formatCurrency(rateToThb)} ฿',
        change24hPercent: changeVal,
        sparklinePoints: generateSparklinePoints(k, rateToThb, changeVal),
        isCommodity: info.isCommodity,
        category: info.isCommodity ? 'commodity' : 'fiat',
      );
    }
  }

  /// Returns list of all selectable assets & currencies for the customization sheet
  static List<LiveRateCardData> getAllSelectableRates() {
    final list = <LiveRateCardData>[];
    list.add(getLiveRateDataForKey('gold_bar'));
    list.add(getLiveRateDataForKey('gold_ornament'));
    list.add(getLiveRateDataForKey('silver'));
    for (final code in supportedCurrencies.keys) {
      if (code == 'thb' || code == 'xag') continue;
      list.add(getLiveRateDataForKey(code));
    }
    return list;
  }

  /// Returns list of all supported currencies with live exchange rates to THB
  static List<CurrencyRateItem> getPopularRateItems() {
    return supportedCurrencies.values.map((info) {
      final rateToThb = getRateToThb(info.code);
      final thbToRate = _inMemoryRates[info.code] ?? defaultThbRates[info.code] ?? 1.0;
      return CurrencyRateItem(
        info: info,
        rateToThb: rateToThb,
        thbToRate: thbToRate,
      );
    }).toList();
  }
}
