import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/referral_service.dart';

/// A beautiful card widget for the referral program.
///
/// Displays:
/// - Gradient background with Moroccan-inspired design
/// - Referral code with copy button
/// - Share button with platform-specific share sheet
/// - Progress tracking for referral milestones
class ReferralCard extends StatefulWidget {
  final VoidCallback? onShare;
  final VoidCallback? onCodeCopied;

  const ReferralCard({
    super.key,
    this.onShare,
    this.onCodeCopied,
  });

  @override
  State<ReferralCard> createState() => _ReferralCardState();
}

class _ReferralCardState extends State<ReferralCard>
    with SingleTickerProviderStateMixin {
  final ReferralService _referralService = ReferralService();
  String? _referralCode;
  int _referralCount = 0;
  bool _isLoading = true;
  bool _isSharing = false;
  bool _codeCopied = false;
  late AnimationController _copyAnimController;
  late Animation<double> _copyScaleAnimation;

  static const int _nextMilestone = 4;
  static const String _milestoneReward = 'free week';

  @override
  void initState() {
    super.initState();
    _copyAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _copyScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _copyAnimController, curve: Curves.easeInOut),
    );
    _loadReferralData();
  }

  @override
  void dispose() {
    _copyAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadReferralData() async {
    try {
      final code = await _referralService.generateReferralCode();
      final count = await _referralService.getReferralCount();

      if (mounted) {
        setState(() {
          _referralCode = code;
          _referralCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareReferral() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    _copyAnimController.forward();

    try {
      await _referralService.shareReferral();
      widget.onShare?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mshkil f share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
        _copyAnimController.reverse();
      }
    }
  }

  Future<void> _copyCode() async {
    if (_referralCode == null) return;

    try {
      await Clipboard.setData(ClipboardData(text: _referralCode!));

      if (mounted) {
        setState(() => _codeCopied = true);
        widget.onCodeCopied?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kod ntensakh! L9ah f clipboard'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _codeCopied = false);
        });
      }
    } catch (e) {
      debugPrint('Error copying code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B21A8), // Purple
            Color(0xFF9333EA), // Lighter purple
            Color(0xFF7C3AED), // Violet
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative patterns
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Moroccan star pattern
          Positioned(
            top: 15,
            left: 15,
            child: Icon(
              Icons.star,
              size: 24,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildReferralCodeSection(),
                const SizedBox(height: 16),
                _buildProgressSection(),
                const SizedBox(height: 20),
                _buildShareButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.card_giftcard_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invite friends, get Premium free!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share Dostok with friends and earn rewards',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCodeSection() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white.withOpacity(0.7),
          strokeWidth: 2,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your referral code',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _referralCode ?? '...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _copyCode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _codeCopied
                    ? Colors.green.withOpacity(0.8)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _codeCopied ? Icons.check : Icons.copy,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _codeCopied ? 'Copied!' : 'Copy',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = _referralCount / _nextMilestone;
    final remaining = _nextMilestone - _referralCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _referralCount == 0
                  ? 'Share to start earning!'
                  : 'You invited $_referralCount friend${_referralCount == 1 ? '' : 's'}!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (remaining > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$remaining more for $_milestoneReward!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        // Milestone indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_nextMilestone + 1, (index) {
            final isAchieved = index <= _referralCount;
            return Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAchieved
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: isAchieved
                      ? const Icon(Icons.check, size: 14, color: Color(0xFF6B21A8))
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  index == 0 ? 'Start' : '$index',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildShareButton() {
    return ScaleTransition(
      scale: _copyScaleAnimation,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSharing ? null : _shareReferral,
          icon: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6B21A8),
                  ),
                )
              : const Icon(Icons.share_rounded, size: 20),
          label: Text(
            _isSharing ? 'Sharing...' : 'Share with friends',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF6B21A8),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
