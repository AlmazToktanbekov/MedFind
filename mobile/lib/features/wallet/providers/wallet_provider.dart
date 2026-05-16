import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/wallet_model.dart';
import '../data/wallet_repository.dart';

class WalletState {
  final WalletModel? wallet;
  final List<WalletTransactionModel> transactions;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.wallet,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    WalletModel? wallet,
    List<WalletTransactionModel>? transactions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      WalletState(
        wallet: wallet ?? this.wallet,
        transactions: transactions ?? this.transactions,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repo;
  WalletNotifier(this._repo) : super(const WalletState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final wallet = await _repo.getMyWallet();
      final txs = await _repo.getTransactions();
      state = WalletState(wallet: wallet, transactions: txs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final walletRepositoryProvider =
    Provider<WalletRepository>((_) => WalletRepository());

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.watch(walletRepositoryProvider));
});

final paymentInfoProvider = FutureProvider<PaymentInfo>((ref) async {
  return ref.watch(walletRepositoryProvider).getPaymentInfo();
});
