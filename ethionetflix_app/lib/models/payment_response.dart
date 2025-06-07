class PaymentResponse {
  final String? txRef;
  final String? paymentUrl;
  final String status;
  final String? message;

  PaymentResponse({
    this.txRef,
    this.paymentUrl,
    required this.status,
    this.message,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      txRef: json['tx_ref'] as String?,
      paymentUrl: json['payment_url'] as String?,
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tx_ref': txRef,
      'payment_url': paymentUrl,
      'status': status,
      'message': message,
    };
  }
} 