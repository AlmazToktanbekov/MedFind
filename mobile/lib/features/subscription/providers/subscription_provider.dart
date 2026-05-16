import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/subscription_model.dart';
import '../data/subscription_repository.dart';

class SubscriptionState {
  final SubscriptionModel? subscription;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.subscription,
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    SubscriptionModel? subscription,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSubscription = false,
  }) {
    return SubscriptionState(
      subscription: clearSubscription ? null : (subscription ?? this.subscription),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionRepository _repo;

  SubscriptionNotifier(this._repo) : super(const SubscriptionState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sub = await _repo.getMySubscription();
      state = SubscriptionState(subscription: sub, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(),
);

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionNotifier(repo);
});

final plansProvider = FutureProvider<PlansResponse>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getPlans();
});
