String formatCurrency(num value) => 'Rs. ${value.toStringAsFixed(0)}';

String formatPercent(double value) => '${(value * 100).round()}%';

String formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
