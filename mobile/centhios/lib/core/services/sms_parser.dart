import 'package:intl/intl.dart';

class SmsParser {
  final List<Pattern> patterns;

  SmsParser() : patterns = defaultPatterns;

  static final List<Pattern> defaultPatterns = [
    // --- HDFC UPI Card Debit Pattern ---
    Pattern(
      type: 'expense',
      regex: RegExp(
        r'Txn Rs\.([\d.]+)\s+On HDFC Bank Card (\d+)\s+At ([^\s]+)\s+by UPI (\d+)\s+On (\d{2}-\d{2})',
        caseSensitive: false,
      ),
      merchantRegex: RegExp(r'At ([^\s]+)'),
    ),
    // --- HDFC-Specific Debit Pattern ---
    Pattern(
      type: 'expense',
      regex: RegExp(
          r'Rs (\d+\.?\d*) debited from a/c \*\*(\w+) on (\d{2}-\d{2}-\d{2}) to (.*?)\. Avl Bal Rs',
          caseSensitive: false),
      merchantRegex: RegExp(r'to (.*?)\.'),
    ),
    // --- HDFC-Specific Credit Pattern ---
    Pattern(
      type: 'income',
      regex: RegExp(
          r'Rs (\d+\.?\d*) credited to a/c \*\*(\w+) on (\d{2}-\d{2}-\d{2}) by (.*?)\. Avl Bal Rs',
          caseSensitive: false),
      merchantRegex: RegExp(r'by (.*?)\.'),
    ),
    // --- Debit Patterns ---
    Pattern(
      type: 'expense',
      regex: RegExp(
          r'(?:(?:RS|INR)\.?\s?)?([\d,]+\.?\d+)\s+debited\s+from.*(?:a/c|acct|account)\s+(?:no.)?(\w*\d+\w*)',
          caseSensitive: false),
      merchantRegex: RegExp(r'(?:at|to)\s+([a-z0-9\s.&-]+?)(?:\s+on|,|ref|$)',
          caseSensitive: false),
    ),
    Pattern(
      type: 'expense',
      regex: RegExp(
          r'spent\s+(?:Rs|INR)\.?\s*([\d,]+\.?\d+)\s+on\s+your\s+card\s+(\w*\d+\w*)',
          caseSensitive: false),
      merchantRegex: RegExp(r'(?:at|on)\s+([a-z0-9\s.&-]+?)(?:\s+on|,|ref|$)',
          caseSensitive: false),
    ),
    Pattern(
      type: 'expense',
      regex: RegExp(
          r'transaction\s+of\s+(?:Rs|INR)\.?\s*([\d,]+\.?\d+)\s+has\s+been\s+made\s+on\s+your\s+card\s+(\w*\d+\w*)',
          caseSensitive: false),
      merchantRegex: RegExp(r'(?:at|on)\s+([a-z0-9\s.&-]+?)(?:\s+on|,|ref|$)',
          caseSensitive: false),
    ),
    // UPI Debits
    Pattern(
        type: 'expense',
        regex: RegExp(r'([\d,]+\.?\d+)\s+debited\s+from\s+your\s+a/c.*?UPI',
            caseSensitive: false),
        merchantRegex:
            RegExp(r'to\s+([a-z0-9\s.&@_-]+)', caseSensitive: false)),

    // --- Credit Patterns ---
    Pattern(
      type: 'income',
      regex: RegExp(
          r'(?:(?:RS|INR)\.?\s?)?([\d,]+\.?\d+)\s+credited\s+to.*(?:a/c|acct|account)\s+(?:no.)?(\w*\d+\w*)',
          caseSensitive: false),
      merchantRegex: RegExp(r'(?:from|by)\s+([a-z0-9\s.&-]+?)(?:\s+on|,|ref|$)',
          caseSensitive: false),
    ),
    Pattern(
        type: 'income',
        regex: RegExp(r'received\s+(?:Rs|INR)\.?\s*([\d,]+\.?\d+)\s+',
            caseSensitive: false),
        merchantRegex:
            RegExp(r'(?:from)\s+([a-z0-9\s.&@_-]+)', caseSensitive: false)),
    // UPI Credits
    Pattern(
        type: 'income',
        regex: RegExp(r'([\d,]+\.?\d+)\s+credited\s+to\s+your\s+a/c.*?UPI',
            caseSensitive: false),
        merchantRegex:
            RegExp(r'from\s+([a-z0-9\s.&@_-]+)', caseSensitive: false)),
  ];

  Map<String, dynamic>? parseSms(String messageBody) {
    final message = messageBody.replaceAll('\n', ' ').trim();

    for (final pattern in patterns) {
      final match = pattern.regex.firstMatch(message);
      if (match != null) {
        try {
          final amountStr = match.group(1)!.replaceAll(',', '');
          final amount = double.parse(amountStr);

          // Use pattern-specific merchant regex
          String merchant = 'Unknown';
          if (pattern.merchantRegex != null) {
            final merchantMatch =
                pattern.merchantRegex!.firstMatch(message.toLowerCase());
            if (merchantMatch != null && merchantMatch.group(1) != null) {
              merchant = merchantMatch.group(1)!.trim();
            }
          }

          // Fallback for UPI merchants if needed
          if (merchant == 'Unknown' && message.contains('UPI')) {
            final upiMerchantMatch = RegExp(
                    r'(?:to|from)\s+([a-z0-9\s.&@_-]+?)(?:\s+on|ref|$)',
                    caseSensitive: false)
                .firstMatch(message.toLowerCase());
            if (upiMerchantMatch != null) {
              merchant = upiMerchantMatch.group(1)!.trim();
            }
          }

          final date = _extractDate(message) ?? DateTime.now();

          return {
            'amount': amount,
            'merchant': toTitleCase(merchant
                .split('on')[0]
                .trim()), // Clean up common trailing words
            'date': DateFormat('yyyy-MM-dd').format(date),
            'type': pattern.type,
            'source': 'sms-local-v2'
          };
        } catch (e) {
          // Could not parse, maybe log this error
          continue;
        }
      }
    }
    return null; // No pattern matched
  }

  DateTime? _extractDate(String message) {
    final dateRegex = RegExp(
      r'(\d{1,2}-(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)-\d{2,4}|\d{1,2}-\d{1,2}-\d{2,4}|\d{2}-\d{2})',
      caseSensitive: false,
    );
    final match = dateRegex.firstMatch(message.toLowerCase());
    if (match == null) return null;

    final dateStr = match.group(1)!;

    try {
      return DateFormat('dd-MMM-yy').parse(dateStr);
    } catch (e) {
      try {
        return DateFormat('dd-MM-yy').parse(dateStr);
      } catch (e2) {
        try {
          return DateFormat('dd-MMM-yyyy').parse(dateStr);
        } catch (e3) {
          try {
            return DateFormat('dd-MM-yyyy').parse(dateStr);
          } catch (e4) {
            // For 'DD-MM' format, assume current year
            final currentYear = DateTime.now().year.toString();
            return DateFormat('dd-MM-yyyy').parse('$dateStr-$currentYear');
          }
        }
      }
    }
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      // Don't capitalize words like VPA, UPI, etc.
      if (word.toUpperCase() == word) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class Pattern {
  final String type;
  final RegExp regex;
  final RegExp? merchantRegex;

  Pattern({
    required this.type,
    required this.regex,
    this.merchantRegex,
  });
}
