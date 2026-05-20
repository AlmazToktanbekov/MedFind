import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/first_aid_data.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: CustomScrollView(
        slivers: [
          _buildHeader(l),
          _buildEmergencyContacts(context, l),
          _buildSectionTitle(l),
          _buildFirstAidGrid(context, l),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.healthTitle,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.healthSubtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts(BuildContext context, AppLocalizations l) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(PhosphorIconsRegular.phone,
                      color: AppColors.error, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  l.healthEmergencyContacts,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _EmergencyCard(
                        emoji: '🚑',
                        label: l.healthEmergencyAmbulance,
                        number: '103')),
                const SizedBox(width: 10),
                Expanded(
                    child: _EmergencyCard(
                        emoji: '👮',
                        label: l.healthEmergencyPolice,
                        number: '102')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _EmergencyCard(
                        emoji: '🚒',
                        label: l.healthEmergencyFire,
                        number: '101')),
                const SizedBox(width: 10),
                Expanded(
                    child: _EmergencyCard(
                        emoji: '⛑️',
                        label: l.healthEmergencyRescue,
                        number: '161')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(AppLocalizations l) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(PhosphorIconsRegular.firstAid,
                  color: AppColors.error, size: 17),
            ),
            const SizedBox(width: 10),
            Text(
              l.healthFirstAid,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstAidGrid(BuildContext context, AppLocalizations l) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _FirstAidCard(
            category: firstAidCategories[index],
            l: l,
            onTap: () => context.push(
              '/main/health/first-aid/${firstAidCategories[index].id}',
            ),
          ),
          childCount: firstAidCategories.length,
        ),
      ),
    );
  }
}

// ─── Emergency contact card ────────────────────────────────────────────────

class _EmergencyCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String number;

  const _EmergencyCard({
    required this.emoji,
    required this.label,
    required this.number,
  });

  Future<void> _call() async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _call,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    number,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.phone_rounded,
                size: 18, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}

// ─── First aid category card ───────────────────────────────────────────────

class _FirstAidCard extends StatelessWidget {
  final FirstAidCategory category;
  final AppLocalizations l;
  final VoidCallback onTap;

  const _FirstAidCard({
    required this.category,
    required this.l,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: category.bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: category.accentColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const Spacer(),
            Text(
              category.title(l),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: category.accentColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              l.healthStepsCount(category.steps(l).length),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: category.accentColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
