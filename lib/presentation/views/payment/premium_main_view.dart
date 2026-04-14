import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/presentation/views/payment/plans_view.dart';
import 'package:cv_tech/presentation/views/payment/payment_processing_view.dart';
import 'package:cv_tech/presentation/views/payment/payment_success_view.dart';
import 'package:cv_tech/presentation/views_models/payment/payment_view_model.dart';

class PremiumMainView extends StatelessWidget {
  const PremiumMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentViewModel()..loadCurrentPlan(),
      child: const _PremiumBody(),
    );
  }
}

class _PremiumBody extends StatelessWidget {
  const _PremiumBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Consumer<PaymentViewModel>(
          builder: (context, vm, _) {
            if (vm.state == PaymentState.processing) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (vm.state == PaymentState.success ||
                    vm.state == PaymentState.failed) {
                  vm.resetState();
                } else if (vm.selectedPlan != null &&
                    vm.state == PaymentState.idle) {
                  vm.cancelSelection();
                } else {
                  Navigator.pop(context);
                }
              },
            );
          },
        ),
      ),
      body: Consumer<PaymentViewModel>(
        builder: (context, vm, _) {
          switch (vm.state) {
            case PaymentState.processing:
              return const PaymentProcessingView();
            case PaymentState.success:
              return const PaymentSuccessView();
            case PaymentState.failed:
              return const PaymentProcessingView();
            case PaymentState.loading:
              return const Center(child: CircularProgressIndicator());
            case PaymentState.error:
            case PaymentState.idle:
              return const PlansView();
          }
        },
      ),
    );
  }
}
