// Connectivity providers (stream + boolean) for online/offline state.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. The Stream Provider (Fixed for version 5.0.2)
// This listens to the stream which returns a single 'ConnectivityResult'
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// 2. The Boolean Provider
// This simplifies the logic for app UI: True = Online, False = Offline
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityStatus = ref.watch(connectivityProvider);
  
  return connectivityStatus.when(
    // If we get data, check if it's NOT 'none'
    data: (status) => status != ConnectivityResult.none,
    
    // If there is an error, assume we are offline
    error: (_, __) => false,
    
    // While loading, optimistically assume we are online
    loading: () => true,
  );
});