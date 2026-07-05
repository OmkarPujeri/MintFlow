/// Platform economics — single source of truth for the reward maths.
///
/// These drive the budget calculator (create_campaign_page), the campaign
/// detail spend breakdown, and any coin/INR conversion. Keep them here so the
/// UI, the "1 Coin = Rs X" helper text, and the calculator never drift apart.
/// If the business changes the fee or coin rate, this is the only edit.
class MintEconomics {
  MintEconomics._();

  /// Platform's cut of an advertiser's deposit.
  static const double platformFeeRate = 0.20;

  /// Share of the deposit that becomes the viewer payout pool.
  static const double viewerPoolRate = 0.80;

  /// Redemption value of one Mint Coin, in INR (1 coin = Rs 0.75).
  static const double coinValueInr = 0.75;
}
