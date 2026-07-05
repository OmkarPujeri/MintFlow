/// The signed-in viewer's profile + gamification state, from `GET /auth/me`.
class Viewer {
  const Viewer({
    required this.id,
    required this.email,
    required this.role,
    required this.mintCoins,
    required this.coinsEarnedToday,
    required this.raffleTickets,
    required this.dailyStreak,
    required this.walletBalanceInr,
  });

  final String id;
  final String email;
  final String role;
  final int mintCoins;
  final int coinsEarnedToday;
  final int raffleTickets;
  final int dailyStreak;
  final double walletBalanceInr;

  factory Viewer.fromJson(Map<String, dynamic> json) => Viewer(
        id: json['id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        mintCoins: (json['mintCoins'] as num?)?.toInt() ?? 0,
        coinsEarnedToday: (json['coinsEarnedToday'] as num?)?.toInt() ?? 0,
        raffleTickets: (json['raffleTickets'] as num?)?.toInt() ?? 0,
        dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
        walletBalanceInr: (json['walletBalanceInr'] as num?)?.toDouble() ?? 0.0,
      );
}
