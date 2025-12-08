import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/payment_model.dart';
import 'package:luna_iot/api/services/payment_api_service.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/controllers/wallet_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final PaymentFormData formData;

  const PaymentWebviewScreen({
    super.key,
    required this.formData,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isProcessingCallback = false;
  final PaymentApiService _paymentApiService = PaymentApiService(
    Get.find<ApiClient>(),
  );

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Create HTML page with pre-filled form
    final htmlContent = _generatePaymentFormHtml();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkForCallback(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkForCallback(url);
            // Auto-submit form after page loads (fallback)
            _autoSubmitForm();
          },
          onNavigationRequest: (NavigationRequest request) {
            _checkForCallback(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent, baseUrl: widget.formData.gatewayUrl);
  }

  String _generatePaymentFormHtml() {
    final formData = widget.formData;
    // Escape special characters in values to prevent XSS and form issues
    String escapeHtml(String value) {
      return value
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&#x27;');
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta charset="UTF-8">
  <title>Redirecting to Payment Gateway...</title>
  <style>
    body {
      margin: 0;
      padding: 20px;
      font-family: Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background-color: #f5f5f5;
    }
    .loading {
      text-align: center;
      color: #666;
    }
    .spinner {
      border: 4px solid #f3f3f3;
      border-top: 4px solid #3498db;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 1s linear infinite;
      margin: 20px auto;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="loading">
    <div class="spinner"></div>
    <p>Redirecting to payment gateway...</p>
  </div>
  <form id="paymentForm" method="POST" action="${escapeHtml(formData.gatewayUrl)}" enctype="application/x-www-form-urlencoded" style="display: none;">
    <input type="hidden" name="MERCHANTID" value="${escapeHtml(formData.merchantId)}">
    <input type="hidden" name="APPID" value="${escapeHtml(formData.appId)}">
    <input type="hidden" name="APPNAME" value="${escapeHtml(formData.appName)}">
    <input type="hidden" name="TXNID" value="${escapeHtml(formData.txnId)}">
    <input type="hidden" name="TXNDATE" value="${escapeHtml(formData.txnDate)}">
    <input type="hidden" name="TXNCRNCY" value="${escapeHtml(formData.txnCrncy)}">
    <input type="hidden" name="TXNAMT" value="${escapeHtml(formData.txnAmt)}">
    <input type="hidden" name="REFERENCEID" value="${escapeHtml(formData.referenceId)}">
    <input type="hidden" name="REMARKS" value="${escapeHtml(formData.remarks)}">
    <input type="hidden" name="PARTICULARS" value="${escapeHtml(formData.particulars)}">
    <input type="hidden" name="TOKEN" value="${escapeHtml(formData.token)}">
  </form>
  <script>
    // Auto-submit form when page loads
    (function() {
      function submitForm() {
        var form = document.getElementById('paymentForm');
        if (form) {
          form.submit();
        }
      }
      
      // Try multiple ways to ensure form submission
      if (document.readyState === 'complete' || document.readyState === 'interactive') {
        setTimeout(submitForm, 100);
      } else {
        window.addEventListener('load', function() {
          setTimeout(submitForm, 100);
        });
      }
      
      // Fallback: try after a short delay
      setTimeout(submitForm, 500);
    })();
  </script>
</body>
</html>
    ''';
  }

  void _autoSubmitForm() {
    // Fallback: Simple script to submit the form if it exists
    _controller.runJavaScript('''
      (function() {
        var form = document.getElementById('paymentForm');
        if (form) {
          form.submit();
        } else {
          // If form doesn't exist, try to find any form and submit it
          var forms = document.getElementsByTagName('form');
          if (forms.length > 0) {
            forms[0].submit();
          }
        }
      })();
    ''');
  }

  void _checkForCallback(String url) {
    // Check if URL contains callback parameters
    if (url.contains('txn_id=') || url.contains('TXNID=') || url.contains('status=')) {
      _handlePaymentCallback(url);
    }
  }

  Future<void> _handlePaymentCallback(String url) async {
    if (_isProcessingCallback) return;

    try {
      setState(() {
        _isProcessingCallback = true;
      });

      // Parse callback parameters from URL
      final callbackParams = PaymentCallbackParams.fromUrl(url);

      if (callbackParams.txnId == null || callbackParams.txnId!.isEmpty) {
        // Try to extract from URL manually
        final uri = Uri.parse(url);
        final txnId = uri.queryParameters['txn_id'] ??
            uri.queryParameters['TXNID'] ??
            _extractTxnIdFromUrl(url);
        
        if (txnId == null || txnId.isEmpty) {
          return; // Wait for proper callback
        }

        // Call backend callback API
        final paymentTxn = await _paymentApiService.handleCallback(
          txnId: txnId,
          status: uri.queryParameters['status']?.toLowerCase(),
        );

        _handlePaymentResult(paymentTxn);
      } else {
        // Call backend callback API
        final paymentTxn = await _paymentApiService.handleCallback(
          txnId: callbackParams.txnId,
          status: callbackParams.status,
        );

        _handlePaymentResult(paymentTxn);
      }
    } catch (e) {
      print('Payment callback error: $e');
      // Show error and allow retry
      if (mounted) {
        Get.snackbar(
          'Payment Error',
          'Failed to process payment callback. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      setState(() {
        _isProcessingCallback = false;
      });
    }
  }

  String? _extractTxnIdFromUrl(String url) {
    // Try to extract TXNID from various URL formats
    final patterns = [
      RegExp(r'txn_id=([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'TXNID=([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'txn_id=([^&?\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  void _handlePaymentResult(PaymentTransaction paymentTxn) {
    // Refresh wallet balance
    final walletController = Get.find<WalletController>();
    walletController.loadWallet();

    if (paymentTxn.isSuccess) {
      // Payment successful
      Get.back(); // Close webview
      Get.snackbar(
        'Payment Successful',
        'Your wallet has been topped up successfully. Amount: NPR ${paymentTxn.amount.toStringAsFixed(2)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } else if (paymentTxn.isFailed || paymentTxn.isError) {
      // Payment failed
      Get.back(); // Close webview
      Get.snackbar(
        'Payment Failed',
        paymentTxn.errorMessage ?? 'Payment transaction failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } else {
      // Payment pending - wait a bit and validate
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          final validatedTxn = await _paymentApiService.validatePayment(
            paymentTxn.txnId,
          );
          _handlePaymentResult(validatedTxn);
        } catch (e) {
          print('Payment validation error: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Payment Gateway',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.titleColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.titleColor),
          onPressed: () {
            Get.dialog(
              AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                  'Are you sure you want to cancel this payment?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back(); // Close dialog
                      Get.back(); // Close webview
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isProcessingCallback)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isProcessingCallback
                          ? 'Processing payment...'
                          : 'Loading payment gateway...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.subTitleColor,
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
}

