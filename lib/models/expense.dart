class Expense {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final String category;
  final String date;
  final String? notes;

  Expense({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
  });

  // Convert Expense object to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date,
      'notes': notes,
    };
  }

  // Create an Expense object from a database map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: map['date'] as String,
      notes: map['notes'] as String?,
    );
  }

  // Create a copy with changed values
  Expense copyWith({
    int? id,
    int? userId,
    String? title,
    double? amount,
    String? category,
    String? date,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}