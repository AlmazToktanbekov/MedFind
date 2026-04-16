import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/ai_repository.dart';
import '../../data/ai_history_service.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/ai_history_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Скроллим вниз при новых сообщениях
    ref.listen(aiChatProvider, (_, next) {
      if (next.messages.isNotEmpty) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildWelcome()
                : _buildMessageList(chatState),
          ),
          if (chatState.error != null) _buildError(chatState.error!),
          _buildInput(chatState.isLoading),
        ],
      ),
    );
  }

  // ─── История ────────────────────────────────────────────────────────────

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(
        onSelect: (conversation) {
          Navigator.of(context).pop();
          ref.read(aiChatProvider.notifier).loadConversation(conversation);
          _scrollToBottom();
        },
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                PhosphorIconsRegular.arrowLeft,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              PhosphorIconsFill.robot,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ИИ-Симптом Чекер',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Llama 3.3 · MedFind',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Кнопка истории
          GestureDetector(
            onTap: () => _showHistory(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                PhosphorIconsRegular.clockCounterClockwise,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Кнопка нового чата
          GestureDetector(
            onTap: () => ref.read(aiChatProvider.notifier).reset(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Welcome screen ──────────────────────────────────────────────────────

  Widget _buildWelcome() {
    final suggestions = [
      'Болит голова и тошнит',
      'Боль в груди при дыхании',
      'Высокая температура 3 дня',
      'Боль в животе справа',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.btnGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(
              PhosphorIconsFill.robot,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Здравствуйте! Я ИИ-помощник\nMedFind.',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Опишите ваши симптомы, и я помогу\nразобраться и найти нужного врача.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.warning,
                    color: AppColors.warning, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Не является медицинским диагнозом',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Быстрые примеры',
              style: AppTextStyles.labelBold,
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (s) => GestureDetector(
              onTap: () {
                _controller.text = s;
                _send();
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    const Icon(
                      PhosphorIconsRegular.chatTeardrop,
                      color: AppColors.primaryBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s, style: AppTextStyles.bodyLarge),
                    ),
                    const Icon(
                      PhosphorIconsRegular.arrowRight,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Message list ────────────────────────────────────────────────────────

  Widget _buildMessageList(AiChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == state.messages.length) return const _TypingIndicator();
        final msg = state.messages[i];
        return _MessageBubble(message: msg);
      },
    );
  }

  // ─── Error banner ────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.warning,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.error),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(aiChatProvider.notifier).clearError(),
            child: Icon(PhosphorIconsRegular.x,
                color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  // ─── Input bar ───────────────────────────────────────────────────────────

  Widget _buildInput(bool isLoading) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundApp,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _controller,
                enabled: !isLoading,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Введите симптомы...',
                  hintStyle: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLoading ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isLoading ? null : AppColors.btnGradient,
                color: isLoading ? AppColors.backgroundApp : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : const Icon(
                      PhosphorIconsFill.paperPlaneRight,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: _isUser ? AppColors.btnGradient : null,
          color: _isUser ? null : AppColors.backgroundCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(_isUser ? 18 : 4),
            bottomRight: Radius.circular(_isUser ? 4 : 18),
          ),
          boxShadow: _isUser ? null : AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsFill.robot,
                      color: AppColors.primaryBlue,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ИИ-ассистент',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: _isUser ? Colors.white : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Typing indicator ────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context2, snapshot) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final value = ((_controller.value - delay) % 1.0);
                final opacity = value < 0.5
                    ? value * 2
                    : (1.0 - value) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue
                        .withValues(alpha: 0.3 + opacity * 0.7),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ─── History Bottom Sheet ────────────────────────────────────────────────────

class _HistorySheet extends ConsumerWidget {
  final void Function(AiConversation) onSelect;
  const _HistorySheet({required this.onSelect});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин назад';
    if (diff.inDays < 1) return '${diff.inHours} ч назад';
    if (diff.inDays == 1) return 'Вчера';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(aiHistoryProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.clockCounterClockwise,
                    color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 10),
                Text('История чатов', style: AppTextStyles.headingMedium),
                const Spacer(),
                historyAsync.maybeWhen(
                  data: (list) => list.isNotEmpty
                      ? GestureDetector(
                          onTap: () =>
                              ref.read(aiHistoryProvider.notifier).clearAll(),
                          child: Text(
                            'Очистить',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox(),
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
            error: (e, st) => Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Ошибка загрузки',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
            ),
            data: (history) => history.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(PhosphorIconsRegular.chatTeardrop,
                            size: 48,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('История пуста',
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: history.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final conv = history[i];
                        return Dismissible(
                          key: Key(conv.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(PhosphorIconsRegular.trash,
                                color: AppColors.error, size: 20),
                          ),
                          onDismissed: (_) =>
                              ref.read(aiHistoryProvider.notifier).delete(conv.id),
                          child: GestureDetector(
                            onTap: () => onSelect(conv),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundApp,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      PhosphorIconsRegular.chatTeardrop,
                                      color: AppColors.primaryBlue,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          conv.title,
                                          style: AppTextStyles.labelBold,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${conv.messages.length} сообщ. · ${_formatDate(conv.date)}',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  color:
                                                      AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(PhosphorIconsRegular.arrowRight,
                                      color: AppColors.textSecondary, size: 16),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
