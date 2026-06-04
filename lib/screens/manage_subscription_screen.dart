import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/premium_features.dart';

/// Screen for managing subscription details, upgrades, and account settings.
///
/// Features:
/// - Current plan details with expiry
/// - Usage breakdown
/// - Change plan options
/// - Cancel subscription with retention offer
/// - Restore purchases
/// - Billing history
/// - Contact support
class ManageSubscriptionScreen extends StatefulWidget {
  static const String routeName = '/manage-subscription';

  const ManageSubscriptionScreen({super.key});

  @override
  State<ManageSubscriptionScreen> createState() => _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  bool _isLoading = true;
  bool _isPremium = false;
  String _currentPlan = 'Free';
  DateTime? _expiryDate;
  int _messagesUsed = 0;
  int _messagesLimit = 50;
  int _callsUsed = 0;
  int _callsLimit = 3;
  int _featuresUsed = 0;
  int _totalFeatures = PremiumFeatures.allFeatures.length;
  bool _showRetentionOffer = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    // TODO: Replace with actual data loading from your subscription service
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Example data - replace with actual subscription state
        _isPremium = false;
        _currentPlan = 'Free';
        _expiryDate = null;
        _messagesUsed = 23;
        _messagesLimit = 50;
        _callsUsed = 1;
        _callsLimit = 3;
        _featuresUsed = 3;
        _totalFeatures = PremiumFeatures.allFeatures.length;
      });
    }
  }

  Future<void> _restorePurchases() async {
    // TODO: Implement actual purchase restoration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restoring purchases...'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No previous purchases found'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _cancelSubscription() async {
    setState(() => _showRetentionOffer = true);
  }

  Future<void> _confirmCancel() async {
    setState(() => _isCancelling = true);

    // TODO: Implement actual cancellation
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isCancelling = false;
        _showRetentionOffer = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription cancelled. You can resubscribe anytime.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _acceptRetentionOffer() async {
    // TODO: Apply 20% discount
    setState(() => _showRetentionOffer = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('20% discount applied! Shukran! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openBillingHistory() async {
    // TODO: Open Play Store billing history
    final url = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactSupport() async {
    final url = Uri(
      scheme: 'mailto',
      path: 'support@dostok.app',
      queryParameters: {
        'subject': 'Dostok Subscription Support',
        'body': 'Describe your issue here...',
      },
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email: support@dostok.app'),
          ),
        );
      }
    }
  }

  void _navigateToPaywall() {
    Navigator.pushNamed(context, '/paywall');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Manage Subscription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentPlanCard(),
                      const SizedBox(height: 16),
                      if (!_isPremium) ...[
                        _buildUpgradePrompt(),
                        const SizedBox(height: 16),
                      ],
                      _buildUsageBreakdown(),
                      const SizedBox(height: 16),
                      _buildPlanOptions(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                if (_showRetentionOffer) _buildRetentionOverlay(),
              ],
            ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isPremium
              ? [const Color(0xFF6B21A8), const Color(0xFF9333EA)]
              : [Colors.grey.shade700, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isPremium ? const Color(0xFF9333EA) : Colors.grey).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPremium ? Icons.star : Icons.person,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentPlan,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _isPremium ? 'Dostok Premium' : 'Dostok Free',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_expiryDate != null) ...[
            Text(
              'Renews: ${_formatDate(_expiryDate!)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ] else ...[
            Text(
              _isPremium
                  ? 'Premium access active'
                  : 'Upgrade for unlimited access',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return GestureDetector(
      onTap: _navigateToPaywall,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF9333EA).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.rocket_launch,
                color: Color(0xFF9333EA),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock unlimited messages, calls, and more!',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage This Month',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildUsageItem(
            icon: Icons.chat_bubble_outline,
            label: 'Messages',
            used: _messagesUsed,
            limit: _messagesLimit,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 14),
          _buildUsageItem(
            icon: Icons.call_outlined,
            label: 'Voice Calls',
            used: _callsUsed,
            limit: _callsLimit,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 14),
          _buildUsageItem(
            icon: Icons.auto_awesome,
            label: 'Premium Features',
            used: _featuresUsed,
            limit: _totalFeatures,
            color: const Color(0xFFF59E0B),
            isFeatureCount: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem({
    required IconData icon,
    required String label,
    required int used,
    required int limit,
    required Color color,
    bool isFeatureCount = false,
  }) {
    final progress = used / limit;
    final isNearLimit = progress > 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              isFeatureCount
                  ? '$used of $limit unlocked'
                  : '$used / ${_isPremium ? "∞" : limit}',
              style: TextStyle(
                color: isNearLimit && !_isPremium ? Colors.red : Colors.grey.shade600,
                fontWeight: isNearLimit && !_isPremium ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (!isFeatureCount) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _isPremium ? 0.3 : progress.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isNearLimit && !_isPremium ? Colors.red : color,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPlanOption(
            title: 'Monthly',
            price: '\$4.99/month',
            description: 'Cancel anytime',
            isSelected: _currentPlan == 'Monthly Premium',
            onTap: _navigateToPaywall,
          ),
          const Divider(height: 24),
          _buildPlanOption(
            title: 'Yearly',
            price: '\$39.99/year',
            description: 'Save 33% - Best value!',
            badge: 'SAVE 33%',
            isSelected: _currentPlan == 'Yearly Premium',
            onTap: _navigateToPaywall,
          ),
          const Divider(height: 24),
          _buildPlanOption(
            title: 'Lifetime',
            price: '\$99.99',
            description: 'One-time payment, forever access',
            badge: 'BEST DEAL',
            isSelected: _currentPlan == 'Lifetime Premium',
            onTap: _navigateToPaywall,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required String description,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF9333EA) : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF9333EA) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF9333EA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Restore purchases
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _restorePurchases,
            icon: const Icon(Icons.restore),
            label: const Text('Restore Purchases'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Billing history
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openBillingHistory,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Billing History'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Contact support
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _contactSupport,
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact Support'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel subscription (only if premium)
        if (_isPremium) ...[
          const Divider(height: 32),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _cancelSubscription,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Cancel Subscription',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRetentionOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Wait! Don\'t go...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Stay and get 20% off your next month!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _acceptRetentionOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Accept 20% Off',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isCancelling ? null : _confirmCancel,
                child: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Continue to Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
