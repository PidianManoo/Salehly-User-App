import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class MyFatoorahPaymentScreen extends StatefulWidget {
  final String checkOutUrl;
  final Function(String) onComplete;
  final Function(bool)? onCancel;

  const MyFatoorahPaymentScreen({super.key, required this.checkOutUrl, required this.onComplete, this.onCancel});

  @override
  State<MyFatoorahPaymentScreen> createState() => _MyFatoorahPaymentScreenState();
}

class _MyFatoorahPaymentScreenState extends State<MyFatoorahPaymentScreen> {
  String pagbankChangeUrl = "";
  bool isLoading = true;
  List<bool> isSelected = [];
  int selectedPaymentMethodIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        language.lblPaymentVerification,
        color: context.primaryColor,
        textColor: Colors.white,
        textSize: APP_BAR_TEXT_SIZE,
        showBack: true,
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _popScopDialog(context);
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(widget.checkOutUrl))),

                // initialOptions: InAppWebViewGroupOptions(
                //   crossPlatform: InAppWebViewOptions(
                //     useShouldOverrideUrlLoading: true,
                //     javaScriptEnabled: true,
                //     userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
                //   ),
                // ),
                onWebViewCreated: (controller) {
                  appStore.setLoading(true);
                },
                onLoadStart: (controller, url) {
                  log('--------------------------------> Start: ${url.toString()}');
                },
                onLoadStop: (controller, url) async {
                  if (mounted) {
                    appStore.setLoading(false);
                  }
                  log('-------------------------------->End: ${url.toString()}');
                },
                onProgressChanged: (controller, progress) {},
                onUpdateVisitedHistory: (controller, url, androidIsReload) {
                  if (url != null) {
                    pagbankChangeUrl = url.toString();
// url.data.parameters;
                    if (mounted && pagbankChangeUrl.contains('success')) {
                      log('url.queryParameters: ${url.queryParameters['Id'] ?? ""}');
                      widget.onComplete.call(url.queryParameters['Id'] ?? "");
                      finish(context);
                    } else if (mounted && (pagbankChangeUrl.contains('fail') || pagbankChangeUrl.contains('error')) ) {
                      widget.onCancel?.call(true);
                      finish(context, pagbankChangeUrl.splitAfter('message='));
                    }
                  }
                },
                onReceivedError: (controller, request, error) {
                  log('WebView Error: ${error.description}');
                  if (mounted) {
                    appStore.setLoading(false);
                  }
                },
              ),
              Observer(
                builder: (context) => LoaderWidget().visible(appStore.isLoading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _popScopDialog(BuildContext context) {
    if (!mounted) return;

    showConfirmDialogCustom(
      context,
      dialogType: DialogType.CONFIRMATION,
      title: language.lblCancelPayment,
      primaryColor: primaryColor,
      positiveText: language.lblYes,
      negativeText: language.lblCancel,
      onAccept: (p0) {
        if (mounted) {
          widget.onCancel?.call(true);
          finish(context, true);
        }
      },
    ).then(
      (value) {
        if (mounted) {
          appStore.setLoading(false);
        }
      },
    );
  }
}
