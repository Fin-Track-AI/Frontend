class MockDataService {
  static final Map<String, dynamic> userProfile = {
    'name': 'Samarth Devadiga',
    'phone': '+91 98765 43210',
    'employer': 'TechCorp India',
    'kycStatus': 'VERIFIED_LITE',
    'consentStatus': 'ACTIVE',
    'rbiAaConnected': true,
  };

  static final Map<String, dynamic> dashboardMetrics = {
    'currentMonthSpend': 42850.0,
    'lastMonthSpend': 38200.0,
    'momChangePercent': 12.17,
    'totalBudget': 60000.0,
    'savingsRate': 28.5,
    'categories': [
      {'name': 'Food & Dining', 'amount': 14200.0, 'percent': 33, 'color': 0xFF10B981, 'icon': 'restaurant'},
      {'name': 'Shopping & Tech', 'amount': 11500.0, 'percent': 27, 'color': 0xFF6366F1, 'icon': 'shopping_bag'},
      {'name': 'Travel & Commute', 'amount': 8350.0, 'percent': 19, 'color': 0xFF38BDF8, 'icon': 'directions_car'},
      {'name': 'Bills & Utilities', 'amount': 5400.0, 'percent': 13, 'color': 0xFFF59E0B, 'icon': 'bolt'},
      {'name': 'Entertainment', 'amount': 3400.0, 'percent': 8, 'color': 0xFFEC4899, 'icon': 'movie'},
    ],
    'recentTransactions': [
      {'title': 'Swiggy', 'category': 'Food & Dining', 'amount': 640.0, 'date': 'Today, 1:15 PM', 'type': 'UPI_READONLY', 'upiRef': 'UPI/428190012/swiggy'},
      {'title': 'Uber Premier', 'category': 'Travel & Commute', 'amount': 420.0, 'date': 'Yesterday, 8:45 PM', 'type': 'UPI_READONLY', 'upiRef': 'UPI/399182312/uber'},
      {'title': 'Amazon India', 'category': 'Shopping & Tech', 'amount': 2499.0, 'date': '08 Sep, 4:20 PM', 'type': 'UPI_READONLY', 'upiRef': 'UPI/319981242/amazon'},
      {'title': 'Blue Tokai Coffee', 'category': 'Food & Dining', 'amount': 280.0, 'date': '07 Sep, 11:30 AM', 'type': 'MANUAL', 'upiRef': null},
    ]
  };

  static final List<Map<String, dynamic>> reimbursementClaims = [
    {
      'id': 'CLM-2024-001',
      'title': 'Team Client Lunch at The Table',
      'amount': 3850.0,
      'date': '05 Sep 2024',
      'category': 'Client Entertainment',
      'status': 'APPROVED',
      'receiptAttached': true,
    },
    {
      'id': 'CLM-2024-002',
      'title': 'Airport Cab - Tech Conference',
      'amount': 1250.0,
      'date': '02 Sep 2024',
      'category': 'Travel',
      'status': 'IN_REVIEW',
      'receiptAttached': true,
    },
    {
      'id': 'CLM-2024-003',
      'title': 'Internet Allowance (Aug)',
      'amount': 1500.0,
      'date': '28 Aug 2024',
      'category': 'Work from Home',
      'status': 'REIMBURSED',
      'receiptAttached': true,
    }
  ];

  static final List<Map<String, dynamic>> splitGroups = [
    {
      'id': 'GRP-01',
      'title': 'Goa Weekend Trip 🌴',
      'totalExpense': 24500.0,
      'yourShare': 6125.0,
      'youOwe': 0.0,
      'youAreOwed': 2400.0,
      'members': ['Samarth (You)', 'Ameya', 'Atharva', 'Ritesh'],
    },
    {
      'id': 'GRP-02',
      'title': 'Flat 402 Rent & Utilities 🏠',
      'totalExpense': 45000.0,
      'yourShare': 15000.0,
      'youOwe': 1200.0,
      'youAreOwed': 0.0,
      'members': ['Samarth (You)', 'Ritesh', 'Aman'],
    }
  ];

  static final List<Map<String, dynamic>> aiSuggestions = [
    {'query': 'Analyze my dining spends this month', 'icon': 'trending_up'},
    {'query': 'How much can I claim for reimbursement?', 'icon': 'receipt_long'},
    {'query': 'Forecast my end-of-month savings', 'icon': 'savings'},
    {'query': 'Am I overspending in Shopping category?', 'icon': 'warning_amber'},
  ];
}
